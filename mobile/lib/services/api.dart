import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user.dart';
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

Future<User> getMe() async {
  final headers = await _authHeaders();
  final res = await http.get(Uri.parse('$_base/auth/me'), headers: headers);
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
    Uri.parse('$_base/auth/signup'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  if (res.statusCode != 201) {
    final body = jsonDecode(res.body);
    throw Exception(body['error'] ?? 'Signup failed');
  }
}

Future<List<dynamic>> getActs() async {
  final headers = await _authHeaders();
  final res = await http.get(Uri.parse('$_base/acts'), headers: headers);
  if (res.statusCode != 200) throw Exception('Failed to fetch acts');
  return jsonDecode(res.body);
}

Future<Map<String, dynamic>> getPresignedUrl(String filename) async {
  final headers = await _authHeaders();
  final res = await http.post(
    Uri.parse('$_base/uploads/presign'),
    headers: headers,
    body: jsonEncode({'filename': filename, 'contentType': 'image/jpeg'}),
  );
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
  final headers = await _authHeaders();
  final res = await http.post(
    Uri.parse('$_base/acts'),
    headers: headers,
    body: jsonEncode({
      'category': category,
      'photoUrl': photoUrl,
      'lat': lat,
      'long': long,
      if (gpsAccuracy != null) 'gpsAccuracy': gpsAccuracy,
    }),
  );
  if (res.statusCode != 201) {
    final body = jsonDecode(res.body);
    throw Exception(body['error'] ?? 'Failed to save act');
  }
}
