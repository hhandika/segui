package com.hhandika.segui

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Folder and file picking and shared files for SEGUI on Android.
 *
 * Picked folders and files are content URIs, not paths, so the files that match the requested
 * extensions are copied into a folder Dart chooses, with progress events. Files shared to SEGUI
 * wait until Dart takes them, and are copied then, also with progress events.
 */
class MobileIoPlugin(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val channel = MethodChannel(messenger, "segui/mobile_io")
    private val progressChannel = EventChannel(messenger, "segui/mobile_io/progress")
    private val mainHandler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    private val cancelled = AtomicBoolean(false)
    private val pendingShared = mutableListOf<Uri>()
    private var progressSink: EventChannel.EventSink? = null
    private var pickRequest: PickRequest? = null

    init {
        channel.setMethodCallHandler(this)
        progressChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFolder" -> startPick(call, result, multiple = false, folder = true)
            "pickFiles" -> startPick(
                call,
                result,
                multiple = call.argument<Boolean>("multiple") ?: true,
                folder = false,
            )
            "cancelCopy" -> {
                cancelled.set(true)
                result.success(null)
            }
            "releaseFolders" -> result.success(null)
            "pendingSharedCount" -> result.success(pendingShared.size)
            "takeSharedFiles" -> takeSharedFiles(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        progressSink = events
    }

    override fun onCancel(arguments: Any?) {
        progressSink = null
    }

    /** Queues the files of a share or open intent and tells Dart about them. */
    fun handleIntent(intent: Intent?) {
        val uris = sharedUris(intent ?: return)
        if (uris.isEmpty()) {
            return
        }
        pendingShared.addAll(uris.filter { it !in pendingShared })
        // Mark the intent as handled so a configuration change does not queue it again.
        intent.action = null
        channel.invokeMethod("sharedFilesAvailable", pendingShared.size)
    }

    /** Handles the folder and file picker results. Returns false for other requests. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PICK_FOLDER_REQUEST && requestCode != PICK_FILES_REQUEST) {
            return false
        }
        val request = pickRequest ?: return true
        pickRequest = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            request.result.success(null)
            return true
        }
        cancelled.set(false)
        if (requestCode == PICK_FOLDER_REQUEST) {
            val treeUri = data.data
            if (treeUri == null) {
                request.result.success(null)
                return true
            }
            executor.execute { copyFolder(treeUri, request) }
        } else {
            val uris = pickedUris(data)
            executor.execute { copyPickedFiles(uris, request) }
        }
        return true
    }

    fun dispose() {
        cancelled.set(true)
        channel.setMethodCallHandler(null)
        progressChannel.setStreamHandler(null)
        executor.shutdown()
    }

    private fun startPick(
        call: MethodCall,
        result: MethodChannel.Result,
        multiple: Boolean,
        folder: Boolean,
    ) {
        if (pickRequest != null) {
            result.error("busy", "A picker is already open", null)
            return
        }
        val destination = call.argument<String>("destination")
        if (destination == null) {
            result.error("bad_args", "Missing destination folder", null)
            return
        }
        val extensions = call.argument<List<String>>("extensions")
            ?.map { it.lowercase() }
            .orEmpty()
        pickRequest = PickRequest(File(destination), extensions, result)
        val intent = if (folder) {
            Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        } else {
            Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "*/*"
                putExtra(Intent.EXTRA_ALLOW_MULTIPLE, multiple)
            }
        }
        @Suppress("DEPRECATION")
        activity.startActivityForResult(
            intent,
            if (folder) PICK_FOLDER_REQUEST else PICK_FILES_REQUEST,
        )
    }

    private fun copyFolder(treeUri: Uri, request: PickRequest) {
        try {
            val rootId = DocumentsContract.getTreeDocumentId(treeUri)
            val rootName = displayName(
                DocumentsContract.buildDocumentUriUsingTree(treeUri, rootId),
            ) ?: "folder"
            sendCounting()
            val files = mutableListOf<TreeFile>()
            collectFiles(treeUri, rootId, emptyList(), request.extensions, files)
            val progress = CopyProgress(files.size, totalSize(files.map { it.size }))
            val output = File(request.destination, safeName(rootName))
            for (file in files) {
                val target = file.relativePath.fold(output) { dir, part -> File(dir, part) }
                if (!copyUri(file.uri, target, progress)) {
                    break
                }
                progress.fileDone()
            }
            mainHandler.post { request.result.success(output.absolutePath) }
        } catch (e: OutOfMemoryError) {
            mainHandler.post { request.result.error("out_of_memory", e.message, null) }
        } catch (e: Exception) {
            mainHandler.post { request.result.error("folder_copy_failed", e.message, null) }
        }
    }

    /** Copies the picked files that match the requested extensions into the destination. */
    private fun copyPickedFiles(uris: List<Uri>, request: PickRequest) {
        try {
            sendCounting()
            val usedNames = mutableSetOf<String>()
            val documents = uris.map { uri -> openableInfo(uri) }
            val matches = documents.filter { matchesExtension(it.name, request.extensions) }
            val progress = CopyProgress(matches.size, totalSize(matches.map { it.size }))
            val paths = mutableListOf<String>()
            for (document in matches) {
                val target = File(request.destination, uniqueName(safeName(document.name), usedNames))
                if (!copyUri(document.uri, target, progress)) {
                    break
                }
                progress.fileDone()
                paths.add(target.absolutePath)
            }
            val skipped = documents.size - matches.size
            mainHandler.post {
                request.result.success(mapOf("paths" to paths, "skipped" to skipped))
            }
        } catch (e: OutOfMemoryError) {
            mainHandler.post { request.result.error("out_of_memory", e.message, null) }
        } catch (e: Exception) {
            mainHandler.post { request.result.error("file_copy_failed", e.message, null) }
        }
    }

    /** Walks the folder tree and keeps the files whose names end with an extension. */
    private fun collectFiles(
        treeUri: Uri,
        parentId: String,
        parentPath: List<String>,
        extensions: List<String>,
        files: MutableList<TreeFile>,
    ) {
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, parentId)
        val columns = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
        )
        activity.contentResolver.query(childrenUri, columns, null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) {
                if (cancelled.get()) {
                    return
                }
                val id = cursor.getString(0) ?: continue
                val name = cursor.getString(1) ?: continue
                if (name.startsWith(".")) {
                    continue
                }
                val path = parentPath + safeName(name)
                if (cursor.getString(2) == DocumentsContract.Document.MIME_TYPE_DIR) {
                    collectFiles(treeUri, id, path, extensions, files)
                } else if (matchesExtension(name, extensions)) {
                    val uri = DocumentsContract.buildDocumentUriUsingTree(treeUri, id)
                    val size = if (cursor.isNull(3)) UNKNOWN_SIZE else cursor.getLong(3)
                    files.add(TreeFile(uri, path, size))
                }
            }
        }
    }

    private fun takeSharedFiles(call: MethodCall, result: MethodChannel.Result) {
        val destination = call.argument<String>("destination")
        if (destination == null) {
            result.error("bad_args", "Missing destination folder", null)
            return
        }
        val uris = pendingShared.toList()
        pendingShared.clear()
        cancelled.set(false)
        executor.execute {
            try {
                sendCounting()
                val usedNames = mutableSetOf<String>()
                val documents = uris.map { uri -> openableInfo(uri, fallbackName = "shared") }
                val progress = CopyProgress(documents.size, totalSize(documents.map { it.size }))
                val paths = mutableListOf<String>()
                for (document in documents) {
                    val target =
                        File(destination, uniqueName(safeName(document.name), usedNames))
                    if (!copyUri(document.uri, target, progress)) {
                        break
                    }
                    progress.fileDone()
                    paths.add(target.absolutePath)
                }
                mainHandler.post { result.success(paths) }
            } catch (e: Exception) {
                mainHandler.post { result.error("shared_copy_failed", e.message, null) }
            }
        }
    }

    /**
     * Copies [uri] into [target] and counts the bytes in [progress]. Returns false when the copy
     * was cancelled, after deleting the partial file.
     */
    private fun copyUri(uri: Uri, target: File, progress: CopyProgress): Boolean {
        if (cancelled.get()) {
            return false
        }
        target.parentFile?.mkdirs()
        val input = activity.contentResolver.openInputStream(uri)
            ?: throw IllegalStateException("Cannot open $uri")
        var completed = true
        input.use { source ->
            target.outputStream().use { sink ->
                val buffer = ByteArray(BUFFER_SIZE)
                while (true) {
                    if (cancelled.get()) {
                        completed = false
                        break
                    }
                    val read = source.read(buffer)
                    if (read < 0) {
                        break
                    }
                    sink.write(buffer, 0, read)
                    progress.addBytes(read)
                }
            }
        }
        if (!completed) {
            target.delete()
        }
        return completed
    }

    /** The URIs of one or many picked documents. */
    private fun pickedUris(data: Intent): List<Uri> {
        val clip = data.clipData
        if (clip != null) {
            return (0 until clip.itemCount).mapNotNull { clip.getItemAt(it).uri }
        }
        return listOfNotNull(data.data)
    }

    /** The display name and size of a document, with a size of [UNKNOWN_SIZE] when unknown. */
    private fun openableInfo(uri: Uri, fallbackName: String = "file"): Openable {
        val columns = arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE)
        val queried = activity.contentResolver.query(uri, columns, null, null, null)
            ?.use { cursor: Cursor ->
                if (!cursor.moveToFirst()) {
                    return@use null
                }
                val name = if (cursor.isNull(0)) null else cursor.getString(0)
                val size = if (cursor.isNull(1)) UNKNOWN_SIZE else cursor.getLong(1)
                Pair(name, size)
            }
        val name = queried?.first
            ?: uri.lastPathSegment?.substringAfterLast('/')
            ?: fallbackName
        return Openable(uri, name, queried?.second ?: UNKNOWN_SIZE)
    }

    private fun displayName(uri: Uri): String? {
        val columns = arrayOf(OpenableColumns.DISPLAY_NAME)
        return activity.contentResolver.query(uri, columns, null, null, null)
            ?.use { cursor: Cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
            ?: uri.lastPathSegment?.substringAfterLast('/')
    }

    /** Tells Dart a copy started while the files are still being counted. */
    private fun sendCounting() {
        sendEvent(mapOf("copied" to 0, "total" to 0))
    }

    private fun sendEvent(event: Map<String, Any>) {
        mainHandler.post { progressSink?.success(event) }
    }

    /**
     * Counts copied files and bytes and sends progress events, at most one per
     * [PROGRESS_INTERVAL_MS] except the first and the last. A total size of zero means some sizes
     * are unknown, so Dart follows the file count.
     */
    private inner class CopyProgress(private val totalFiles: Int, private val totalBytes: Long) {
        private var files = 0
        private var bytes = 0L
        private var lastSent = 0L

        init {
            send(force = true)
        }

        fun addBytes(count: Int) {
            bytes += count
            send(force = false)
        }

        fun fileDone() {
            files++
            send(force = files == totalFiles)
        }

        private fun send(force: Boolean) {
            val now = SystemClock.uptimeMillis()
            if (!force && now - lastSent < PROGRESS_INTERVAL_MS) {
                return
            }
            lastSent = now
            sendEvent(
                mapOf(
                    "copied" to files,
                    "total" to totalFiles,
                    "bytesCopied" to bytes,
                    "bytesTotal" to totalBytes,
                ),
            )
        }
    }

    private fun sharedUris(intent: Intent): List<Uri> {
        return when (intent.action) {
            Intent.ACTION_SEND -> listOfNotNull(streamExtra(intent))
            Intent.ACTION_SEND_MULTIPLE -> streamListExtra(intent)
            Intent.ACTION_VIEW -> listOfNotNull(intent.data)
            else -> emptyList()
        }
    }

    private fun streamExtra(intent: Intent): Uri? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
    }

    private fun streamListExtra(intent: Intent): List<Uri> {
        val uris = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM)
        }
        return uris.orEmpty()
    }

    private data class PickRequest(
        val destination: File,
        val extensions: List<String>,
        val result: MethodChannel.Result,
    )

    private data class TreeFile(val uri: Uri, val relativePath: List<String>, val size: Long)

    private data class Openable(val uri: Uri, val name: String, val size: Long)

    private companion object {
        const val PICK_FOLDER_REQUEST = 7341
        const val PICK_FILES_REQUEST = 7342
        const val BUFFER_SIZE = 64 * 1024
        const val PROGRESS_INTERVAL_MS = 100L
        const val UNKNOWN_SIZE = -1L

        /** The sum of [sizes], or zero when any size is unknown. */
        fun totalSize(sizes: List<Long>): Long {
            return if (sizes.any { it < 0 }) 0L else sizes.sum()
        }

        fun matchesExtension(name: String, extensions: List<String>): Boolean {
            if (extensions.isEmpty()) {
                return true
            }
            val lower = name.lowercase()
            return extensions.any { lower.endsWith(".$it") }
        }

        /** Keeps a document name from leaving its folder. */
        fun safeName(name: String): String {
            val cleaned = name.replace('/', '_').replace('\\', '_')
            return if (cleaned == "." || cleaned == ".." || cleaned.isBlank()) "_" else cleaned
        }

        fun uniqueName(name: String, used: MutableSet<String>): String {
            var candidate = name
            var index = 1
            while (!used.add(candidate)) {
                candidate = "${index}_$name"
                index++
            }
            return candidate
        }
    }
}
