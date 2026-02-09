import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

Future<Uint8List?> pickImagePlatform() async {
  final completer = Completer<Uint8List?>();

  try {
    // Check if we're on a mobile device
    final userAgent = web.window.navigator.userAgent.toLowerCase();
    final isMobile =
        userAgent.contains('mobile') ||
        userAgent.contains('android') ||
        userAgent.contains('iphone') ||
        userAgent.contains('ipad');

    if (isMobile) {
      // For mobile browsers, create a more robust file input
      final uploadInput =
          web.HTMLInputElement()
            ..type = 'file'
            ..accept = 'image/*';
      uploadInput.style.position = 'absolute';
      uploadInput.style.left = '-9999px';
      uploadInput.style.top = '-9999px';

      // Add the input to the DOM temporarily
      web.document.body!.appendChild(uploadInput);

      uploadInput.click();

      // Set up a timeout to handle cases where the file picker doesn't work
      Timer(const Duration(seconds: 30), () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      uploadInput.addEventListener(
        'change',
        (event) {
          if (uploadInput.files != null && uploadInput.files!.length > 0) {
            final file = uploadInput.files!.item(0)!;

            // Check file size (limit to 10MB)
            if (file.size > 10 * 1024 * 1024) {
              completer.completeError(
                'File size too large. Please select an image smaller than 10MB.',
              );
              return;
            }

            final reader = web.FileReader();

            reader.addEventListener(
              'loadend',
              (event) {
                try {
                  final base64 = (reader.result as String).split(',').last;
                  final bytes = base64Decode(base64);
                  completer.complete(bytes);
                } catch (e) {
                  completer.completeError('Failed to process image: $e');
                }
              }.toJS,
            );

            reader.addEventListener(
              'error',
              (event) {
                completer.completeError('Failed to read file');
              }.toJS,
            );

            reader.readAsDataURL(file);
          } else {
            completer.complete(null);
          }

          // Clean up the input element
          uploadInput.remove();
        }.toJS,
      );

      // Handle cases where the file picker is cancelled
      // Note: onCancel is not available, so we rely on timeout
      // The timeout will handle cases where the user doesn't select a file
    } else {
      // For desktop browsers, use the standard approach
      final uploadInput =
          web.HTMLInputElement()
            ..type = 'file'
            ..accept = 'image/*';
      uploadInput.click();

      uploadInput.addEventListener(
        'change',
        (event) {
          if (uploadInput.files != null && uploadInput.files!.length > 0) {
            final file = uploadInput.files!.item(0)!;

            // Check file size (limit to 10MB)
            if (file.size > 10 * 1024 * 1024) {
              completer.completeError(
                'File size too large. Please select an image smaller than 10MB.',
              );
              return;
            }

            final reader = web.FileReader();

            reader.addEventListener(
              'loadend',
              (event) {
                try {
                  final base64 = (reader.result as String).split(',').last;
                  final bytes = base64Decode(base64);
                  completer.complete(bytes);
                } catch (e) {
                  completer.completeError('Failed to process image: $e');
                }
              }.toJS,
            );

            reader.addEventListener(
              'error',
              (event) {
                completer.completeError('Failed to read file');
              }.toJS,
            );

            reader.readAsDataURL(file);
          } else {
            completer.complete(null);
          }
        }.toJS,
      );
    }
  } catch (e) {
    completer.completeError('Failed to initialize image picker: $e');
  }

  return completer.future;
}
