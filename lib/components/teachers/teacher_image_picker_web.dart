import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

Future<Uint8List?> pickImagePlatform() async {
  final completer = Completer<Uint8List?>();
  
  try {
    // Check if we're on a mobile device
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    final isMobile = userAgent.contains('mobile') || 
                    userAgent.contains('android') || 
                    userAgent.contains('iphone') || 
                    userAgent.contains('ipad');
    
    if (isMobile) {
      // For mobile browsers, create a more robust file input
      final uploadInput = html.FileUploadInputElement()
        ..accept = 'image/*'
        ..style.position = 'absolute'
        ..style.left = '-9999px'
        ..style.top = '-9999px';
      
      // Add the input to the DOM temporarily
      html.document.body!.append(uploadInput);
      
      uploadInput.click();
      
      // Set up a timeout to handle cases where the file picker doesn't work
      Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });
      
      uploadInput.onChange.listen((event) {
        if (uploadInput.files != null && uploadInput.files!.isNotEmpty) {
          final file = uploadInput.files!.first;
          
          // Check file size (limit to 10MB)
          if (file.size > 10 * 1024 * 1024) {
            completer.completeError('File size too large. Please select an image smaller than 10MB.');
            return;
          }
          
          final reader = html.FileReader();
          
          reader.readAsDataUrl(file);
          reader.onLoadEnd.listen((event) {
            try {
              final base64 = (reader.result as String).split(',').last;
              final bytes = base64Decode(base64);
              completer.complete(bytes);
            } catch (e) {
              completer.completeError('Failed to process image: $e');
            }
          });
          
          reader.onError.listen((event) {
            completer.completeError('Failed to read file');
          });
        } else {
          completer.complete(null);
        }
        
        // Clean up the input element
        uploadInput.remove();
      });
      
      // Handle cases where the file picker is cancelled
      // Note: onCancel is not available in dart:html, so we rely on timeout
      // The timeout will handle cases where the user doesn't select a file
      
    } else {
      // For desktop browsers, use the standard approach
      final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
      uploadInput.click();
      
      uploadInput.onChange.listen((event) {
        if (uploadInput.files != null && uploadInput.files!.isNotEmpty) {
          final file = uploadInput.files!.first;
          
          // Check file size (limit to 10MB)
          if (file.size > 10 * 1024 * 1024) {
            completer.completeError('File size too large. Please select an image smaller than 10MB.');
            return;
          }
          
          final reader = html.FileReader();
          
          reader.readAsDataUrl(file);
          reader.onLoadEnd.listen((event) {
            try {
              final base64 = (reader.result as String).split(',').last;
              final bytes = base64Decode(base64);
              completer.complete(bytes);
            } catch (e) {
              completer.completeError('Failed to process image: $e');
            }
          });
          
          reader.onError.listen((event) {
            completer.completeError('Failed to read file');
          });
        } else {
          completer.complete(null);
        }
      });
    }
  } catch (e) {
    completer.completeError('Failed to initialize image picker: $e');
  }
  
  return completer.future;
}
