//! HTTPS access to the archives.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:segui/services/databases/types.dart';

/// Stops the requests it is passed to.
class CancelToken {
  bool _isCancelled = false;
  final Set<void Function()> _listeners = {};

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) return;
    _isCancelled = true;
    for (final listener in _listeners.toList()) {
      listener();
    }
    _listeners.clear();
  }

  void throwIfCancelled() {
    if (_isCancelled) throw const DatabaseCancelled();
  }

  /// Calls [listener] on cancel. Returns a function that removes it.
  void Function() onCancel(void Function() listener) {
    if (_isCancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
    return () => _listeners.remove(listener);
  }
}

class HttpTextResponse {
  const HttpTextResponse(this.status, this.body);

  final int status;
  final String body;

  bool get isOk => status == HttpStatus.ok;
}

/// Requests the archive services need, replaced by a fake in tests.
abstract interface class DatabaseClient {
  /// Reads a response as text. [form] is sent as a POST body. An error
  /// status is returned, because the archives explain errors in the body.
  Future<HttpTextResponse> read(
    Uri url, {
    Map<String, String>? form,
    CancelToken? cancel,
  });

  /// Saves a response to [destination] and returns the MD5 of its bytes.
  /// Throws on an error status or a short response.
  Future<String> save(
    Uri url,
    File destination, {
    Map<String, String>? form,
    CancelToken? cancel,
    void Function(int bytes)? onReceived,
  });
}

/// Whether [url] is an HTTPS address of NCBI or EMBL-EBI. Addresses come
/// from responses, so anything else is refused.
bool isArchiveUrl(Uri url) {
  if (!url.isScheme('https')) return false;
  return url.host.endsWith('.ncbi.nlm.nih.gov') ||
      url.host.endsWith('.ebi.ac.uk');
}

/// [address] from an archive as HTTPS. ENA omits the scheme and NCBI lists
/// FTP, and both serve the same paths over HTTPS.
Uri archiveFileUrl(String address) {
  final String path = address.trim().replaceFirst(RegExp(r'^\w+://'), '');
  return Uri.parse('https://$path');
}

class HttpDatabaseClient implements DatabaseClient {
  HttpDatabaseClient({
    this.isAllowed = isArchiveUrl,
    this.retryDelay = const Duration(seconds: 2),
    this.timeout = const Duration(seconds: 90),
  });

  final bool Function(Uri url) isAllowed;
  final Duration retryDelay;

  /// Longest wait for a response or for the next bytes of one.
  final Duration timeout;

  static const int _maxAttempts = 3;
  static const int _maxRedirects = 4;

  /// NCBI allows three requests a second without an API key.
  static const Duration _ncbiInterval = Duration(milliseconds: 400);
  static const Duration _defaultInterval = Duration(milliseconds: 100);

  final Map<String, DateTime> _nextRequest = {};

  @override
  Future<HttpTextResponse> read(
    Uri url, {
    Map<String, String>? form,
    CancelToken? cancel,
  }) {
    return _withRetry(cancel, (isLast) {
      return _send(url, form, cancel, (response) async {
        if (!isLast && _isBusy(response.statusCode)) {
          throw _RetryableStatus(response.statusCode);
        }
        final String body = await response
            .timeout(timeout)
            .transform(const Utf8Decoder(allowMalformed: true))
            .join();
        return HttpTextResponse(response.statusCode, body);
      });
    });
  }

  @override
  Future<String> save(
    Uri url,
    File destination, {
    Map<String, String>? form,
    CancelToken? cancel,
    void Function(int bytes)? onReceived,
  }) {
    return _withRetry(cancel, (isLast) {
      return _send(url, form, cancel, (response) async {
        if (response.statusCode != HttpStatus.ok) {
          if (!isLast && _isBusy(response.statusCode)) {
            throw _RetryableStatus(response.statusCode);
          }
          throw DatabaseException(_statusMessage(response.statusCode));
        }
        final digest = _DigestSink();
        final ByteConversionSink hash = md5.startChunkedConversion(digest);
        final IOSink file = destination.openWrite();
        int received = 0;
        try {
          // addStream waits for the disk, so large runs do not fill memory.
          await file.addStream(response.timeout(timeout).map((chunk) {
            hash.add(chunk);
            received += chunk.length;
            onReceived?.call(received);
            return chunk;
          }));
          await file.flush();
        } finally {
          await file.close();
        }
        hash.close();
        return digest.value.toString();
      });
    });
  }

  Future<T> _withRetry<T>(
    CancelToken? cancel,
    Future<T> Function(bool isLast) attempt,
  ) async {
    for (int count = 1;; count++) {
      cancel?.throwIfCancelled();
      final bool isLast = count >= _maxAttempts;
      try {
        return await attempt(isLast);
      } on DatabaseException {
        rethrow;
      } on FileSystemException catch (e) {
        cancel?.throwIfCancelled();
        throw DatabaseException('Could not save the download (${e.message}).');
      } on Exception catch (e) {
        cancel?.throwIfCancelled();
        if (isLast) throw DatabaseException(_failureMessage(e));
      }
      await _wait(retryDelay * count, cancel);
    }
  }

  Future<T> _send<T>(
    Uri start,
    Map<String, String>? form,
    CancelToken? cancel,
    Future<T> Function(HttpClientResponse response) consume,
  ) async {
    // A client for each request lets cancel close the connection, even
    // halfway through a body.
    final HttpClient http = HttpClient()..connectionTimeout = timeout;
    final remove = cancel?.onCancel(() => http.close(force: true));
    try {
      Uri url = start;
      for (int hop = 0; hop <= _maxRedirects; hop++) {
        if (!isAllowed(url)) {
          throw const DatabaseException('The database gave an unsafe address.');
        }
        await _throttle(url.host, cancel);
        cancel?.throwIfCancelled();
        final HttpClientRequest request =
            form == null ? await http.getUrl(url) : await http.postUrl(url);
        // Each hop is checked before it is followed.
        request.followRedirects = false;
        if (form != null) {
          final List<int> body = utf8.encode(Uri(queryParameters: form).query);
          request.headers.contentType = ContentType(
            'application',
            'x-www-form-urlencoded',
            charset: 'utf-8',
          );
          request.contentLength = body.length;
          request.add(body);
        }
        final response = await request.close().timeout(timeout);
        final String? location =
            response.headers.value(HttpHeaders.locationHeader);
        if (_isRedirect(response.statusCode) && location != null) {
          await response.drain<void>();
          url = url.resolve(location);
          continue;
        }
        final T result = await consume(response);
        cancel?.throwIfCancelled();
        return result;
      }
      throw const DatabaseException('The database redirected too many times.');
    } finally {
      remove?.call();
      http.close(force: true);
    }
  }

  Future<void> _throttle(String host, CancelToken? cancel) async {
    final Duration interval =
        host.startsWith('eutils.ncbi') ? _ncbiInterval : _defaultInterval;
    final DateTime now = DateTime.now();
    final DateTime? next = _nextRequest[host];
    final DateTime slot = next != null && next.isAfter(now) ? next : now;
    _nextRequest[host] = slot.add(interval);
    if (slot.isAfter(now)) {
      await _wait(slot.difference(now), cancel);
    }
  }

  Future<void> _wait(Duration duration, CancelToken? cancel) async {
    final completer = Completer<void>();
    void finish() {
      if (!completer.isCompleted) completer.complete();
    }

    final timer = Timer(duration, finish);
    final remove = cancel?.onCancel(finish);
    await completer.future;
    timer.cancel();
    remove?.call();
    cancel?.throwIfCancelled();
  }

  bool _isBusy(int status) =>
      status == HttpStatus.tooManyRequests ||
      status >= HttpStatus.internalServerError;

  bool _isRedirect(int status) => const {
        HttpStatus.movedPermanently,
        HttpStatus.found,
        HttpStatus.seeOther,
        HttpStatus.temporaryRedirect,
        HttpStatus.permanentRedirect,
      }.contains(status);

  String _statusMessage(int status) {
    if (status == HttpStatus.notFound) return 'Not found in the database.';
    if (_isBusy(status)) return 'The database is busy. Try again later.';
    return 'The database refused the request ($status).';
  }

  String _failureMessage(Exception error) {
    return switch (error) {
      TimeoutException() => 'The database took too long to answer.',
      _RetryableStatus(:final status) => _statusMessage(status),
      SocketException() ||
      HandshakeException() =>
        'Could not connect. Check your internet connection.',
      _ => 'The connection was interrupted. Try again.',
    };
  }
}

class _RetryableStatus implements Exception {
  const _RetryableStatus(this.status);

  final int status;
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
