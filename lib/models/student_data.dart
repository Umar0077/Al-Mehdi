/// Model for student registration data
class StudentData {
  final String fullName;
  final String phoneNumber;
  final String country;
  final String grade;
  final String favouriteSubject;

  const StudentData({
    required this.fullName,
    required this.phoneNumber,
    required this.country,
    required this.grade,
    required this.favouriteSubject,
  });

  /// Validate student data fields
  bool isValid() {
    return fullName.trim().isNotEmpty &&
        phoneNumber.trim().isNotEmpty &&
        country.trim().isNotEmpty &&
        grade.trim().isNotEmpty &&
        favouriteSubject.trim().isNotEmpty;
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toFirestoreMap({
    required String uid,
    required String email,
  }) {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName.trim(),
      'country': country.trim(),
      'grade': grade.trim(),
      'favouriteSubject': favouriteSubject.trim(),
      'phoneNumber': phoneNumber.trim(),
      'role': 'Student',
      'assignedTeacherId': null,
    };
  }

  /// Convert to map for unassigned students collection
  Map<String, dynamic> toUnassignedMap({
    required String uid,
    required String email,
  }) {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName.trim(),
      'country': country.trim(),
      'grade': grade.trim(),
      'favouriteSubject': favouriteSubject.trim(),
      'phoneNumber': phoneNumber.trim(),
      'role': 'Student',
      'assigned': false,
    };
  }

  /// Copy with method for updating fields
  StudentData copyWith({
    String? fullName,
    String? phoneNumber,
    String? country,
    String? grade,
    String? favouriteSubject,
  }) {
    return StudentData(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      country: country ?? this.country,
      grade: grade ?? this.grade,
      favouriteSubject: favouriteSubject ?? this.favouriteSubject,
    );
  }
}
