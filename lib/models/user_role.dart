/// Enum representing user roles in the application
enum UserRole {
  student,
  teacher,
  admin;

  /// Returns a display name for the role
  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.admin:
        return 'Admin';
    }
  }

  /// Returns the Firestore collection name for the role
  String get collectionName {
    switch (this) {
      case UserRole.student:
        return 'students';
      case UserRole.teacher:
        return 'teachers';
      case UserRole.admin:
        return 'admin';
    }
  }

  /// Returns the unassigned collection name for the role
  String get unassignedCollectionName {
    switch (this) {
      case UserRole.student:
        return 'unassigned_students';
      case UserRole.teacher:
        return 'unassigned_teachers';
      case UserRole.admin:
        throw UnsupportedError('Admin users cannot be unassigned');
    }
  }
}
