import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Creates a [Dio] instance whose HTTP adapter always returns [cannedJson]
/// as a 200 OK application/json response without making real network calls.
Dio fakeDio(Map<String, dynamic> cannedJson) {
  final dio = Dio();
  dio.httpClientAdapter = _FakeAdapter(cannedJson);
  return dio;
}

class _FakeAdapter implements HttpClientAdapter {
  final Map<String, dynamic> _cannedJson;

  _FakeAdapter(this._cannedJson);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(_cannedJson),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
