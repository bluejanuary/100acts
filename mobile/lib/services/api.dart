import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/act.dart';
import '../models/user.dart';
import '../models/system_config.dart';
import 'api_endpoints.dart';
import 'token.dart';

// ─── Auth headers ────────────────────────────────────────────────────────────

Future<Map<String, String>> _authHeaders() async {
  final token = await TokenStorage.getToken();
  if (token == null) throw Exception('Not authenticated');
  return {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
}

// ─── Token refresh ───────────────────────────────────────────────────────────

Future<bool> _tryRefresh() async {
  final refreshToken = await TokenStorage.getRefreshToken();
  if (refreshToken == null) return false;
  try {
    final res = await http.post(
      Uri.parse(ApiEndpoints.refresh),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    if (res.statusCode != 200) return false;
    final body = jsonDecode(res.body);
    await TokenStorage.save(body['token'], body['refreshToken']);
    debugPrint('[api] token refreshed');
    return true;
  } catch (_) {
    return false;
  }
}

// ─── Authenticated request helpers ───────────────────────────────────────────

Future<http.Response> _authGet(String url) async {
  var headers = await _authHeaders();
  var res = await http.get(Uri.parse(url), headers: headers);
  if (res.statusCode == 401) {
    final refreshed = await _tryRefresh();
    if (refreshed) {
      headers = await _authHeaders();
      res = await http.get(Uri.parse(url), headers: headers);
    }
  }
  return res;
}

Future<http.Response> _authPost(String url, Object body) async {
  var headers = await _authHeaders();
  var res = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));
  if (res.statusCode == 401) {
    final refreshed = await _tryRefresh();
    if (refreshed) {
      headers = await _authHeaders();
      res = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));
    }
  }
  return res;
}

// ─── API calls ───────────────────────────────────────────────────────────────

Future<User> getMe() async {
  final res = await _authGet(ApiEndpoints.me);
  if (res.statusCode != 200) throw Exception('Failed to fetch user');
  return User.fromJson(jsonDecode(res.body));
}

Future<Map<String, dynamic>> login(String email, String password) async {
  debugPrint('[api] POST ${ApiEndpoints.login}');
  final res = await http.post(
    Uri.parse(ApiEndpoints.login),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  debugPrint('[api] login → ${res.statusCode} ${res.body}');
  if (res.statusCode != 200) {
    String errorMsg = 'Login failed';
    try {
      errorMsg = jsonDecode(res.body)['error'] ?? errorMsg;
    } catch (_) {
      errorMsg = 'Server error (${res.statusCode})';
    }
    throw Exception(errorMsg);
  }
  return jsonDecode(res.body);
}

Future<void> signup(String email, String password) async {
  debugPrint('[api] POST ${ApiEndpoints.register}');
  final res = await http.post(
    Uri.parse(ApiEndpoints.register),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  debugPrint('[api] register → ${res.statusCode} ${res.body}');
  if (res.statusCode != 201) {
    String errorMsg = 'Signup failed';
    try {
      errorMsg = jsonDecode(res.body)['error'] ?? errorMsg;
    } catch (_) {
      errorMsg = 'Server error (${res.statusCode})';
    }
    throw Exception(errorMsg);
  }
}

Future<SystemConfig> getSystemConfig() async {
  debugPrint('[api] GET ${ApiEndpoints.config}');
  final res = await http.get(Uri.parse(ApiEndpoints.config));
  debugPrint('[api] config → ${res.statusCode} ${res.body}');
  if (res.statusCode != 200) throw Exception('Failed to fetch system config (${res.statusCode})');
  return SystemConfig.fromJson(jsonDecode(res.body));
}

Future<List<Act>> getActs() async {
  debugPrint('[api] GET ${ApiEndpoints.acts}');
  final res = await _authGet(ApiEndpoints.acts);
  if (res.statusCode != 200) throw Exception('Failed to fetch acts');
  final list = jsonDecode(res.body) as List<dynamic>;
  return list.map((e) => Act.fromJson(e as Map<String, dynamic>)).toList();
}

Future<List<Act>> getAllActs() async {
  debugPrint('[api] GET ${ApiEndpoints.allActs}');
  final res = await _authGet(ApiEndpoints.allActs);
  if (res.statusCode != 200) throw Exception('Failed to fetch all acts');
  final list = jsonDecode(res.body) as List<dynamic>;
  return list.map((e) => Act.fromJson(e as Map<String, dynamic>)).toList();
}

Future<Map<String, dynamic>> getPresignedUrl(String filename) async {
  debugPrint('[api] POST ${ApiEndpoints.presign}');
  final res = await _authPost(ApiEndpoints.presign, {'filename': filename, 'contentType': 'image/jpeg'});
  if (res.statusCode != 200) throw Exception('Failed to get upload URL');
  return jsonDecode(res.body);
}

Future<void> uploadToS3(String uploadUrl, List<int> bytes) async {
  debugPrint('[api] PUT $uploadUrl');
  final res = await http.put(
    Uri.parse(uploadUrl),
    headers: {'Content-Type': 'image/jpeg'},
    body: bytes,
  );
  if (res.statusCode != 200) throw Exception('Failed to upload photo');
}

Future<void> createAct({
  required String category,
  required String description,
  required List<String> photoUrls,
  required double lat,
  required double long,
  double? gpsAccuracy,
}) async {
  debugPrint('[api] POST ${ApiEndpoints.acts}');
  final res = await _authPost(ApiEndpoints.acts, {
    'category': category,
    'description': description,
    'photoUrls': photoUrls,
    'lat': lat,
    'long': long,
    if (gpsAccuracy != null) 'gpsAccuracy': gpsAccuracy,
  });
  if (res.statusCode != 201) {
    String errorMsg = 'Failed to save act';
    try {
      errorMsg = jsonDecode(res.body)['error'] ?? errorMsg;
    } catch (_) {}
    throw Exception(errorMsg);
  }
}
