import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:segui/services/databases/client.dart';
import 'package:segui/services/databases/types.dart';

/// A response for a request, with a status and a body of text or bytes.
typedef FakeReply = ({int status, Object body});

FakeReply ok(Object body) => (status: 200, body: body);

/// Answers requests from recorded responses, without a network.
class FakeDatabaseClient implements DatabaseClient {
  FakeDatabaseClient(this.reply);

  final FakeReply Function(Uri url, Map<String, String> form) reply;
  final List<({Uri url, Map<String, String> form})> requests = [];

  /// Called once bytes are saved, such as to cancel halfway.
  void Function()? onSaved;

  @override
  Future<HttpTextResponse> read(
    Uri url, {
    Map<String, String>? form,
    CancelToken? cancel,
  }) async {
    cancel?.throwIfCancelled();
    requests.add((url: url, form: form ?? const {}));
    final FakeReply response = reply(url, form ?? const {});
    return HttpTextResponse(response.status, response.body as String);
  }

  @override
  Future<String> save(
    Uri url,
    File destination, {
    Map<String, String>? form,
    CancelToken? cancel,
    void Function(int bytes)? onReceived,
  }) async {
    cancel?.throwIfCancelled();
    requests.add((url: url, form: form ?? const {}));
    final FakeReply response = reply(url, form ?? const {});
    if (response.status != 200) {
      throw const DatabaseException('Not found in the database.');
    }
    final List<int> bytes = switch (response.body) {
      final String text => utf8.encode(text),
      final List<int> data => data,
      _ => throw ArgumentError('Unsupported fake body'),
    };
    // Widget tests run in fake time, where asynchronous file IO never ends.
    destination.writeAsBytesSync(bytes);
    onReceived?.call(bytes.length);
    onSaved?.call();
    cancel?.throwIfCancelled();
    return md5.convert(bytes).toString();
  }
}
