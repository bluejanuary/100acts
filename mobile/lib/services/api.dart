import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user.dart';
import '../models/system_config.dart';
import 'token.dart';

String get _base => dotenv.env['API_URL']!;

Future<Map<String, String>> _authHeaders() async {
  final token = await TokenStorage.getToken();
  if (token == null) throw Exception('Not authenticated');
  return {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
}

/// Attempt to refresh the access token using the stored refresh token.
/// Returns true if successful, false otherwise.
Future<bool> _tryRefresh() async {
  final refreshToken = await TokenStorage.getRefreshToken();
  if (refreshToken == null) return false;
  try {
    final res = await http.post(
      Uri.parse('$_base/auth/refresh'),
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

/// Make an authenticated GET request, refreshing token once on 401.
Future<http.Response> _authGet(String path) async {
  var headers = await _authHeaders();
  var res = await http.get(Uri.parse('$_base$path'), headers: headers);
  if (res.statusCode == 401) {
    final refreshed = await _tryRefresh();
    if (refreshed) {
      headers = await _authHeaders();
      res = await http.get(Uri.parse('$_base$path'), headers: headers);
    }
  }
  return res;
}

/// Make an authenticated POST request, refreshing token once on 401.
Future<http.Response> _authPost(String path, Object body) async {
  var headers = await _authHeaders();
  var res = await http.post(Uri.parse('$_base$path'), headers: headers, body: jsonEncode(body));
  if (res.statusCode == 401) {
    final refreshed = await _tryRefresh();
    if (refreshed) {
      headers = await _authHeaders();
      res = await http.post(Uri.parse('$_base$path'), headers: headers, body: jsonEncode(body));
    }
  }
  return res;
}

Future<User> getMe() async {
  final res = await _authGet('/auth/me');
  if (res.statusCode != 200) throw Exception('Failed to fetch user');
  return User.fromJson(jsonDecode(res.body));
}

Future<Map<String, dynamic>> login(String email, String password) async {
  final res = await http.post(
    Uri.parse('$_base/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  final body = jsonDecode(res.body);
  if (res.statusCode != 200) throw Exception(body['error'] ?? 'Login failed');
  return body;
}

Future<void> signup(String email, String password) async {
  final res = await http.post(
    Uri.parse('$_base/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  if (res.statusCode != 201) {
    final body = jsonDecode(res.body);
    throw Exception(body['error'] ?? 'Signup failed');
  }
}

Future<SystemConfig> getSystemConfig() async {
  debugPrint('[api] GET $_base/api/config');
  final res = await http.get(Uri.parse('$_base/api/config'));
  debugPrint('[api] GET $_base/api/config → ${res.statusCode} ${res.body}');
  if (res.statusCode != 200) throw Exception('Failed to fetch system config (${res.statusCode})');
  return SystemConfig.fromJson(jsonDecode(res.body));
}

Future<List<dynamic>> getActs() async {
  final res = await _authGet('/acts');
  if (res.statusCode != 200) throw Exception('Failed to fetch acts');
  return jsonDecode(res.body);
}

Future<Map<String, dynamic>> getPresignedUrl(String filename) async {
  final res = await _authPost('/uploads/presign', {'filename': filename, 'contentType': 'image/jpeg'});
  if (res.statusCode != 200) throw Exception('Failed to get upload URL');
  return jsonDecode(res.body);
}

Future<void> uploadToS3(String uploadUrl, List<int> bytes) async {
  final res = await http.put(
    Uri.parse(uploadUrl),
    headers: {'Content-Type': 'image/jpeg'},
    body: bytes,
  );
  if (res.statusCode != 200) throw Exception('Failed to upload photo');
}

Future<void> createAct({
  required String category,
  required String photoUrl,
  required double lat,
  required double long,
  double? gpsAccuracy,
}) async {
  final res = await _authPost('/acts', {
    'category': category,
    'photoUrl': photoUrl,
    'lat': lat,
    'long': long,
    if (gpsAccuracy != null) 'gpsAccuracy': gpsAccuracy,
  });
  if (res.statusCode != 201) {
    final body = jsonDecode(res.body);
    throw Exception(body['error'] ?? 'Failed to save act');
  }
}
