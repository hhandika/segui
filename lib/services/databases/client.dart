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
    this.timeout = const Duration(seconds: 45),
    this.connectTimeout = const Duration(seconds: 20),
    this.readTimeout = const Duration(seconds: 30),
    this.ncbiInterval = defaultNcbiInterval,
  });

  /// NCBI allows 3 req/s without an API key, or 10 req/s with one.
  static const Duration defaultNcbiInterval = Duration(milliseconds: 350);
  static const Duration keyedNcbiInterval = Duration(milliseconds: 110);
  static const Duration _defaultInterval = Duration(milliseconds: 50);

  final bool Function(Uri url) isAllowed;
  final Duration retryDelay;

  /// Longest wait for response headers.
  final Duration timeout;
  final Duration connectTimeout;
  final Duration readTimeout;
  final Duration ncbiInterval;

  static const int _maxAttempts = 3;
  static const int _maxRedirects = 4;

  final Map<String, DateTime> _nextRequest = {};
  HttpClient? _http;

  HttpClient get _client => _http ??= HttpClient()
    ..connectionTimeout = connectTimeout
    ..idleTimeout = const Duration(seconds: 15)
    ..maxConnectionsPerHost = 6;

  void close({bool force = false}) {
    _http?.close(force: force);
    _http = null;
  }

  @override
  Future<HttpTextResponse> read(
    Uri url, {
    Map<String, String>? form,
    CancelToken? cancel,
  }) {
    return _withRetry(url.host, cancel, (isLast) {
      return _send(url, form, cancel, (response, activeUrl) async {
        if (!isLast && _isBusy(response.statusCode)) {
          final Duration? retryAfter = _retryAfter(response);
          await response.drain<void>();
          throw _RetryableStatus(response.statusCode, retryAfter: retryAfter);
        }
        final String body = await _readBody(response, cancel);
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
    return _withRetry(url.host, cancel, (isLast) {
      return _send(url, form, cancel, (response, activeUrl) async {
        if (response.statusCode != HttpStatus.ok) {
          final Duration? retryAfter = _retryAfter(response);
          await response.drain<void>();
          if (!isLast && _isBusy(response.statusCode)) {
            throw _RetryableStatus(response.statusCode, retryAfter: retryAfter);
          }
          throw DatabaseException(_statusMessage(response.statusCode));
        }
        return _saveBody(response, destination, cancel, onReceived);
      });
    });
  }

  Future<String> _readBody(
    HttpClientResponse response,
    CancelToken? cancel,
  ) async {
    final Completer<String> completer = Completer<String>();
    final StringBuffer buffer = StringBuffer();
    late final StreamSubscription<String> sub;
    final remove = cancel?.onCancel(() {
      sub.cancel();
      if (!completer.isCompleted) {
        completer.completeError(const DatabaseCancelled());
      }
    });
    sub = response
        .timeout(readTimeout)
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen(
      buffer.write,
      onError: (Object error, StackTrace stack) {
        if (!completer.isCompleted) completer.completeError(error, stack);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete(buffer.toString());
      },
      cancelOnError: true,
    );
    try {
      return await completer.future;
    } finally {
      remove?.call();
    }
  }

  Future<String> _saveBody(
    HttpClientResponse response,
    File destination,
    CancelToken? cancel,
    void Function(int bytes)? onReceived,
  ) async {
    final digest = _DigestSink();
    final ByteConversionSink hash = md5.startChunkedConversion(digest);
    final IOSink file = destination.openWrite();
    int received = 0;
    final Completer<void> completer = Completer<void>();
    late final StreamSubscription<List<int>> sub;
    final remove = cancel?.onCancel(() {
      sub.cancel();
      if (!completer.isCompleted) {
        completer.completeError(const DatabaseCancelled());
      }
    });

    sub = response.timeout(readTimeout).listen(
      (chunk) {
        hash.add(chunk);
        file.add(chunk);
        received += chunk.length;
        onReceived?.call(received);
      },
      onError: (Object error, StackTrace stack) {
        if (!completer.isCompleted) completer.completeError(error, stack);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );

    try {
      await completer.future;
      await file.flush();
    } finally {
      remove?.call();
      await file.close();
    }
    hash.close();
    return digest.value.toString();
  }

  Future<T> _withRetry<T>(
    String host,
    CancelToken? cancel,
    Future<T> Function(bool isLast) attempt,
  ) async {
    for (int count = 1;; count++) {
      cancel?.throwIfCancelled();
      final bool isLast = count >= _maxAttempts;
      Duration? retryAfter;
      try {
        return await attempt(isLast);
      } on DatabaseException {
        rethrow;
      } on FileSystemException catch (e) {
        cancel?.throwIfCancelled();
        throw DatabaseException('Could not save the download (${e.message}).');
      } on _RetryableStatus catch (e) {
        cancel?.throwIfCancelled();
        if (isLast) throw DatabaseException(_statusMessage(e.status));
        retryAfter = e.retryAfter;
      } on Exception catch (e) {
        cancel?.throwIfCancelled();
        if (isLast) throw DatabaseException(_failureMessage(e));
      }
      final Duration delay = retryAfter ?? retryDelay * count;
      _pushBack(host, delay);
      await _wait(delay, cancel);
    }
  }

  Future<T> _send<T>(
    Uri start,
    Map<String, String>? form,
    CancelToken? cancel,
    Future<T> Function(HttpClientResponse response, Uri activeUrl) consume,
  ) async {
    final HttpClient http = _client;
    Uri url = start;
    Map<String, String>? currentForm = form;
    for (int hop = 0; hop <= _maxRedirects; hop++) {
      if (!isAllowed(url)) {
        throw const DatabaseException('The database gave an unsafe address.');
      }
      await _throttle(url.host, cancel);
      cancel?.throwIfCancelled();
      final HttpClientRequest request =
          await (currentForm == null ? http.getUrl(url) : http.postUrl(url))
              .timeout(connectTimeout);
      final removeReqCancel = cancel?.onCancel(request.abort);
      final HttpClientResponse response;
      try {
        request.followRedirects = false;
        if (currentForm != null) {
          final List<int> body =
              utf8.encode(Uri(queryParameters: currentForm).query);
          request.headers.contentType = ContentType(
            'application',
            'x-www-form-urlencoded',
            charset: 'utf-8',
          );
          request.contentLength = body.length;
          request.add(body);
        }
        response = await request.close().timeout(timeout);
      } finally {
        removeReqCancel?.call();
      }
      final String? location =
          response.headers.value(HttpHeaders.locationHeader);
      if (_isRedirect(response.statusCode) && location != null) {
        await response.drain<void>();
        if (response.statusCode == HttpStatus.seeOther) {
          currentForm = null;
        }
        url = url.resolve(location);
        continue;
      }
      final T result = await consume(response, url);
      cancel?.throwIfCancelled();
      return result;
    }
    throw const DatabaseException('The database redirected too many times.');
  }

  Future<void> _throttle(String host, CancelToken? cancel) async {
    final Duration interval =
        host.startsWith('eutils.ncbi') ? ncbiInterval : _defaultInterval;
    final DateTime now = DateTime.now();
    final DateTime? next = _nextRequest[host];
    final DateTime slot = next != null && next.isAfter(now) ? next : now;
    _nextRequest[host] = slot.add(interval);
    if (slot.isAfter(now)) {
      await _wait(slot.difference(now), cancel);
    }
  }

  void _pushBack(String host, Duration delay) {
    final DateTime target = DateTime.now().add(delay);
    final DateTime? current = _nextRequest[host];
    if (current == null || current.isBefore(target)) {
      _nextRequest[host] = target;
    }
  }

  Duration? _retryAfter(HttpClientResponse response) {
    final String? raw = response.headers.value(HttpHeaders.retryAfterHeader);
    if (raw == null) return null;
    final int? seconds = int.tryParse(raw.trim());
    if (seconds == null || seconds < 0) return null;
    return Duration(seconds: seconds > 60 ? 60 : seconds);
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
  const _RetryableStatus(this.status, {this.retryAfter});

  final int status;
  final Duration? retryAfter;
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
