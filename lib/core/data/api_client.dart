part of '../../main.dart';

class ApiClient {
  ApiClient({required String baseUrl, this.token})
    : baseUrl = normalisasiBaseApiMobile(baseUrl);

  final String baseUrl;
  final String? token;
  final HttpClient _httpClient = HttpClient();

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request = await _httpClient.openUrl(method, _uri(path));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }

    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    final payload = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
    if (response.statusCode >= 400) throw ApiException.fromPayload(payload);
    return payload;
  }

  Future<dynamic> multipartLeave(
    Map<String, String> fields,
    PickedDocument? document,
  ) async {
    final boundary = '----presensi-${DateTime.now().microsecondsSinceEpoch}';
    final bytes = BytesBuilder();

    for (final entry in fields.entries) {
      bytes.add(utf8.encode('--$boundary\r\n'));
      bytes.add(
        utf8.encode(
          'Content-Disposition: form-data; name="${entry.key}"\r\n\r\n',
        ),
      );
      bytes.add(utf8.encode('${entry.value}\r\n'));
    }

    if (document != null) {
      bytes.add(utf8.encode('--$boundary\r\n'));
      bytes.add(
        utf8.encode(
          'Content-Disposition: form-data; name="dokumen"; filename="${document.name}"\r\n',
        ),
      );
      bytes.add(
        utf8.encode(
          'Content-Type: ${document.mimeType ?? 'application/octet-stream'}\r\n\r\n',
        ),
      );
      bytes.add(document.bytes);
      bytes.add(utf8.encode('\r\n'));
    }

    bytes.add(utf8.encode('--$boundary--\r\n'));
    final body = bytes.takeBytes();
    final request = await _httpClient.postUrl(_uri('/pengajuan-izin'));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (token != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    request.headers.contentType = ContentType(
      'multipart',
      'form-data',
      parameters: {'boundary': boundary},
    );
    request.contentLength = body.length;
    request.add(body);

    final response = await request.close();
    final text = await utf8.decoder.bind(response).join();
    final payload = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
    if (response.statusCode >= 400) throw ApiException.fromPayload(payload);
    return payload;
  }

  Uri _uri(String path) {
    final root = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$root$path');
  }
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  factory ApiException.fromPayload(dynamic payload) {
    if (payload is Map) {
      final errors = payload['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return ApiException(first.first.toString());
        }
      }
      return ApiException(
        payload['pesan']?.toString() ??
            payload['message']?.toString() ??
            'Permintaan gagal.',
      );
    }
    return ApiException('Permintaan gagal.');
  }

  @override
  String toString() => message;
}
