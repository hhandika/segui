import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:segui/services/databases/client.dart';
import 'package:segui/services/databases/types.dart';

void main() {
  late HttpServer server;
  late Directory dir;
  late int calls;
  late Future<void> Function(HttpRequest request) handle;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('segui-client-');
    calls = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      calls++;
      try {
        await handle(request);
      } on Exception {
        // The client closes the connection when a test cancels.
      }
    });
  });

  tearDown(() async {
    await server.close(force: true);
    await dir.delete(recursive: true);
  });

  HttpDatabaseClient client() => HttpDatabaseClient(
        // The server has no address once a test closes it.
        isAllowed: (url) => url.host == InternetAddress.loopbackIPv4.address,
        retryDelay: const Duration(milliseconds: 5),
        timeout: const Duration(seconds: 5),
      );

  Uri url([String path = '/']) =>
      Uri.parse('http://${server.address.address}:${server.port}$path');

  test('Retries 429 and 5xx', () async {
    handle = (request) async {
      request.response.statusCode = calls == 1
          ? 429
          : calls == 2
              ? 503
              : 200;
      request.response.write('done');
      await request.response.close();
    };
    final response = await client().read(url());
    expect(response.body, 'done');
    expect(calls, 3);
  });

  test('Does not retry a bad request', () async {
    handle = (request) async {
      request.response.statusCode = 400;
      request.response.write('{"message":"Invalid"}');
      await request.response.close();
    };
    expect((await client().read(url())).status, 400);
    expect(calls, 1);
  });

  test('Posts forms', () async {
    late String body;
    handle = (request) async {
      body = await utf8.decodeStream(request);
      await request.response.close();
    };
    await client().read(url(), form: {'term': 'Mus musculus[Organism]'});
    expect(Uri.splitQueryString(body), {'term': 'Mus musculus[Organism]'});
  });

  test('Returns the MD5 of what it saves', () async {
    final bytes = List<int>.generate(200000, (i) => i % 251);
    handle = (request) async {
      request.response.add(bytes);
      await request.response.close();
    };
    final file = File(p.join(dir.path, 'saved'));
    expect(await client().save(url(), file), md5.convert(bytes).toString());
    expect(file.lengthSync(), bytes.length);
  });

  test('Refuses a redirect to another host', () async {
    handle = (request) async {
      await request.response.redirect(Uri.parse('http://example.invalid/x'));
    };
    await expectLater(
      client().read(url()),
      throwsA(isA<DatabaseException>()),
    );
    expect(calls, 1);
  });

  test('Cancel stops a body halfway', () async {
    handle = (request) async {
      request.response.bufferOutput = false;
      for (int i = 0; i < 200; i++) {
        request.response.add(List.filled(1024, 65));
        await request.response.flush();
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await request.response.close();
    };
    final token = CancelToken();
    final watch = Stopwatch()..start();
    await expectLater(
      client().save(
        url(),
        File(p.join(dir.path, 'cancelled')),
        cancel: token,
        onReceived: (_) => token.cancel(),
      ),
      throwsA(isA<DatabaseCancelled>()),
    );
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
  });

  test('Being offline gives a message users can act on', () async {
    final Uri closed = url();
    await server.close(force: true);
    await expectLater(
      client().read(closed),
      throwsA(isA<DatabaseException>().having(
        (e) => e.message,
        'message',
        contains('internet connection'),
      )),
    );
  });

  test('Reuses keep-alive connections and respects Retry-After', () async {
    handle = (request) async {
      if (calls == 1) {
        request.response.statusCode = 429;
        request.response.headers.set(HttpHeaders.retryAfterHeader, '0');
        request.response.write('busy');
      } else {
        request.response.statusCode = 200;
        request.response.write('ok');
      }
      await request.response.close();
    };
    final shared = client();
    addTearDown(shared.close);
    expect((await shared.read(url())).body, 'ok');
    expect((await shared.read(url())).body, 'ok');
    expect(calls, 3);
    expect(server.connectionsInfo().total, 1);
  });

  test('Cancelling one request leaves the pooled client usable', () async {
    handle = (request) async {
      request.response.bufferOutput = false;
      request.response.write('first');
      await request.response.flush();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await request.response.close();
    };
    final shared = client();
    addTearDown(shared.close);
    final token = CancelToken();
    await expectLater(
      shared.save(
        url(),
        File(p.join(dir.path, 'part')),
        cancel: token,
        onReceived: (_) => token.cancel(),
      ),
      throwsA(isA<DatabaseCancelled>()),
    );
    expect((await shared.read(url())).body, 'first');
  });
}
