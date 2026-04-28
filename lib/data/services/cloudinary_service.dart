import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudinaryService {
  static const String _cloudName = 'dhwh1vlwx';
  static const String _uploadPreset = 'bundadini'; // unsigned preset
  static const String _folder = 'bunda_dini/patients';

  static Future<String> uploadFoto(File file, String patientId) async {
    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final publicId = '${patientId}_$timestamp';

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = _folder
      ..fields['public_id'] = publicId
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body);

    if (response.statusCode != 200) {
      throw Exception('Upload gagal: ${json['error']['message']}');
    }

    return json['secure_url'] as String;
  }

  /// Hapus foto lama (opsional, dipanggil saat update foto)
  static Future<void> deleteFoto(String publicId) async {
    // Untuk delete butuh signed request (API Secret)
    // Lebih aman dilakukan via Cloud Function / backend
    // Untuk sekarang biarkan saja — Cloudinary free 25GB
  }
}
