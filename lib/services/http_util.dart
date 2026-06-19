import 'dart:convert';
import 'package:dio/dio.dart';

/// 极简网络工具类
/// 仅对外暴露一个 GET 方法，统一处理异常。
/// 业务层通过 Repository 调用，无需关心底层实现。
class HttpUtil {
  static final HttpUtil _instance = HttpUtil._internal();
  factory HttpUtil() => _instance;

  late final Dio _dio;

  HttpUtil._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  /// 发起 GET 请求，返回解析后的数据列表。
  /// 请求失败或数据异常时返回空列表，不抛异常。
  Future<List<dynamic>> getList(
    String url, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.get<String>(
        url,
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.plain),
      );
      if (response.statusCode == 200 && response.data != null) {
        var body = response.data!;
        // 去掉可能的 UTF-8 BOM
        if (body.codeUnitAt(0) == 0xFEFF) {
          body = body.substring(1);
        }
        final decoded = jsonDecode(body);
        if (decoded is List) return decoded;
      }
      return [];
    } catch (e) {
      print('HttpUtil.getList error: $e');
      print('  URL: $url');
      return [];
    }
  }

  /// 发起 GET 请求，返回原始响应数据（Map类型）。
  /// 用于获取非列表结构的 JSON 数据。
  Future<Map<String, dynamic>?> getMap(
    String url, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.get<String>(
        url,
        queryParameters: queryParams,
        options: Options(responseType: ResponseType.plain),
      );
      if (response.statusCode == 200 && response.data != null) {
        var body = response.data!;
        if (body.codeUnitAt(0) == 0xFEFF) {
          body = body.substring(1);
        }
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
      return null;
    } catch (e) {
      print('HttpUtil.getMap error: $e');
      return null;
    }
  }
}
