import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class RestApi {
  final dio = Dio();
  final Uri baseUri;
  final Map<String, dynamic>? apiDefaultHeaders;

  RestApi({required String baseUrl, Map<String, dynamic>? defaultHeaders})
    : baseUri = Uri.parse(baseUrl),
      apiDefaultHeaders = {
        "Cache-Control": "no-cache",
        "Accept-Encoding": "gzip",
        ...?defaultHeaders,
      } {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.idleTimeout = Duration(milliseconds: 100);
      return client;
    };
  }

  Future<Response<T>> apiRequest<T>({
    required String method,
    required String path,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
    String contentType = Headers.jsonContentType,
    ResponseType responseType = ResponseType.json,
  }) async {
    final bool isJson = contentType == Headers.jsonContentType;
    final combinedHeaders = {
      if (isJson) "Accept": "application/json",
      ...?apiDefaultHeaders,
      ...?headers,
    };

    try {
      final response = await dio.request<T>(
        baseUri.resolve(path).toString(),
        data: data,
        queryParameters: queryParams,
        options: Options(
          method: method,
          contentType: contentType,
          responseType: responseType,
          validateStatus: _validateStatus,
          headers: combinedHeaders,
        ),
      );
      return response;
    } catch (error) {
      final sanitizedHeaders = _sanitizeHeaders(combinedHeaders);
      throw RestApiException(
        "Problem sending request: url=${baseUri.resolve(path)}, "
        "headers=$sanitizedHeaders",
        error,
      );
    }
  }

  Future<Response<T>> apiMultipart<T>({
    required String path,
    required Map<String, String> fields,
    required List<int> file,
    required String filename,
    Map<String, dynamic>? queryParams,
    Map<String, dynamic>? headers,
  }) async {
    final uri = baseUri.resolve(path);
    final combinedHeaders = {...?apiDefaultHeaders, ...?headers};

    final formData = FormData.fromMap({
      ...fields,
      "bundle": MultipartFile.fromBytes(
        file,
        filename: filename,
        contentType: DioMediaType("application", "gzip"),
      ),
    });

    try {
      final response = await dio.post<T>(
        uri.toString(),
        data: formData,
        queryParameters: queryParams,
        options: Options(validateStatus: _validateStatus, headers: combinedHeaders),
      );
      return response;
    } catch (error) {
      final sanitizedHeaders = _sanitizeHeaders(combinedHeaders);
      throw RestApiException(
        "Problem sending request: url=$uri, "
        "headers=$sanitizedHeaders",
        error,
      );
    }
  }

  bool _validateStatus(int? status) {
    return true;
    // return status != null && status >= 200 && status < 300;
  }

  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    return {
      ...headers,
      if (headers.containsKey("Authorization")) ...{"Authorization": "*****"},
    };
  }
}

extension ResponseExt on Response {
  bool get ok {
    final code = statusCode;
    return code != null && (code >= 200 && code <= 299);
  }
}

class RestApiException implements Exception {
  final String message;
  final dynamic error;

  RestApiException(this.message, [this.error]);

  @override
  String toString() => '$message <- $error';
}
