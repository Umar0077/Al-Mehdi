import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

Future<Uint8List?> pickImagePlatform() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      
      if (file.bytes != null) {
        // Check file size (limit to 10MB)
        if (file.size > 10 * 1024 * 1024) {
          if (kDebugMode) {
            print('File size too large: ${file.size} bytes');
          }
          return null;
        }
        
        if (kDebugMode) {
          print('Image selected: ${file.name}, size: ${file.size} bytes');
        }
        
        return file.bytes!;
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error picking image: $e');
    }
  }

  return null;
}
