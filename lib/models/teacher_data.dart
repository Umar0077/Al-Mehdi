import 'package:file_picker/file_picker.dart';

/// Model for teacher registration data
class TeacherData {
  final String fullName;
  final String phoneNumber;
  final String country;
  final String degree;
  final PlatformFile degreeFile;

  const TeacherData({
    required this.fullName,
    required this.phoneNumber,
    required this.country,
    required this.degree,
    required this.degreeFile,
  });

  /// Validate teacher data fields
  bool isValid() {
    return fullName.trim().isNotEmpty &&
        phoneNumber.trim().isNotEmpty &&
        country.trim().isNotEmpty &&
        degree.trim().isNotEmpty;
  }

  /// Convert to map for Firestore (without degreeProofUrl, will be added separately)
  Map<String, dynamic> toFirestoreMap({
    required String uid,
    required String email,
    required String degreeProofUrl,
  }) {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'country': country.trim(),
      'degree': degree.trim(),
      'degreeProofUrl': degreeProofUrl,
      'assignedStudentId': null,
    };
  }

  /// Convert to map for unassigned teachers collection
  Map<String, dynamic> toUnassignedMap({
    required String uid,
    required String email,
    required String degreeProofUrl,
  }) {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'country': country.trim(),
      'degree': degree.trim(),
      'degreeProofUrl': degreeProofUrl,
      'role': 'Teacher',
      'assigned': false,
    };
  }

  /// Copy with method for updating fields
  TeacherData copyWith({
    String? fullName,
    String? phoneNumber,
    String? country,
    String? degree,
    PlatformFile? degreeFile,
  }) {
    return TeacherData(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      country: country ?? this.country,
      degree: degree ?? this.degree,
      degreeFile: degreeFile ?? this.degreeFile,
    );
  }
}
