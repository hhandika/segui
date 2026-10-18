package com.hhandika.segui

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
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
 * Folder picking and shared files for SEGUI on Android.
 *
 * A folder from the system picker is a content URI, not a path, so the files that match the
 * requested extensions are copied into a folder Dart chooses, with progress events. Files shared
 * to SEGUI wait until Dart takes them, and are copied then.
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
    private var folderRequest: FolderRequest? = null

    init {
        channel.setMethodCallHandler(this)
        progressChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFolder" -> pickFolder(call, result)
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

    /** Handles the folder picker result. Returns false for other requests. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PICK_FOLDER_REQUEST) {
            return false
        }
        val request = folderRequest ?: return true
        folderRequest = null
        val treeUri = data?.data
        if (resultCode != Activity.RESULT_OK || treeUri == null) {
            request.result.success(null)
            return true
        }
        cancelled.set(false)
        executor.execute { copyFolder(treeUri, request) }
        return true
    }

    fun dispose() {
        cancelled.set(true)
        channel.setMethodCallHandler(null)
        progressChannel.setStreamHandler(null)
        executor.shutdown()
    }

    private fun pickFolder(call: MethodCall, result: MethodChannel.Result) {
        if (folderRequest != null) {
            result.error("busy", "A folder picker is already open", null)
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
        folderRequest = FolderRequest(File(destination), extensions, result)
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
        @Suppress("DEPRECATION")
        activity.startActivityForResult(intent, PICK_FOLDER_REQUEST)
    }

    private fun copyFolder(treeUri: Uri, request: FolderRequest) {
        try {
            val rootId = DocumentsContract.getTreeDocumentId(treeUri)
            val rootName = displayName(
                DocumentsContract.buildDocumentUriUsingTree(treeUri, rootId),
            ) ?: "folder"
            val files = mutableListOf<TreeFile>()
            collectFiles(treeUri, rootId, emptyList(), request.extensions, files)
            sendProgress(0, files.size)
            val output = File(request.destination, safeName(rootName))
            for ((index, file) in files.withIndex()) {
                if (cancelled.get()) {
                    break
                }
                val target = file.relativePath.fold(output) { dir, part -> File(dir, part) }
                copyUri(file.uri, target)
                sendProgress(index + 1, files.size)
            }
            mainHandler.post { request.result.success(output.absolutePath) }
        } catch (e: OutOfMemoryError) {
            mainHandler.post { request.result.error("out_of_memory", e.message, null) }
        } catch (e: Exception) {
            mainHandler.post { request.result.error("folder_copy_failed", e.message, null) }
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
                    files.add(TreeFile(uri, path))
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
        executor.execute {
            try {
                val usedNames = mutableSetOf<String>()
                val paths = uris.map { uri ->
                    val name = uniqueName(safeName(displayName(uri) ?: "shared"), usedNames)
                    val target = File(destination, name)
                    copyUri(uri, target)
                    target.absolutePath
                }
                mainHandler.post { result.success(paths) }
            } catch (e: Exception) {
                mainHandler.post { result.error("shared_copy_failed", e.message, null) }
            }
        }
    }

    private fun copyUri(uri: Uri, target: File) {
        target.parentFile?.mkdirs()
        val input = activity.contentResolver.openInputStream(uri)
            ?: throw IllegalStateException("Cannot open $uri")
        input.use { source ->
            target.outputStream().buffered().use { sink -> source.copyTo(sink, BUFFER_SIZE) }
        }
    }

    private fun displayName(uri: Uri): String? {
        val columns = arrayOf(OpenableColumns.DISPLAY_NAME)
        return activity.contentResolver.query(uri, columns, null, null, null)
            ?.use { cursor: Cursor -> if (cursor.moveToFirst()) cursor.getString(0) else null }
            ?: uri.lastPathSegment?.substringAfterLast('/')
    }

    private fun sendProgress(copied: Int, total: Int) {
        // Send about 200 updates at most, plus the first and the last.
        val step = maxOf(1, total / 200)
        if (copied != 0 && copied != total && copied % step != 0) {
            return
        }
        mainHandler.post { progressSink?.success(mapOf("copied" to copied, "total" to total)) }
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

    private data class FolderRequest(
        val destination: File,
        val extensions: List<String>,
        val result: MethodChannel.Result,
    )

    private data class TreeFile(val uri: Uri, val relativePath: List<String>)

    private companion object {
        const val PICK_FOLDER_REQUEST = 7341
        const val BUFFER_SIZE = 64 * 1024

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
