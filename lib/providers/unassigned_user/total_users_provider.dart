import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TotalUsersProvider extends ChangeNotifier {
  String selectedRole = 'All';
  String selectedStatus = 'All';
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  bool isLoadingUserDetails = false;

  void initialize() async {
    await fetchUsers();
    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchUsers() async {
    final firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> fetchedUsers = [];
    try {
      final studentSnap = await firestore.collection('students').get();
      for (var doc in studentSnap.docs) {
        final data = doc.data();
        fetchedUsers.add({
          'id': doc.id,
          'name': data['fullName'] ?? 'Unnamed',
          'role': 'Student',
          'enabled': data['enabled'] ?? true, // <-- FIXED HERE
          'avatarUrl': data['profilePictureUrl'] ?? data['avatarUrl'] ?? 'https://i.pravatar.cc/100?img=11',
        });
      }
      final teacherSnap = await firestore.collection('teachers').get();
      for (var doc in teacherSnap.docs) {
        final data = doc.data();
        fetchedUsers.add({
          'id': doc.id,
          'name': data['fullName'] ?? 'Unnamed',
          'role': 'Teacher',
          'enabled': data['enabled'] ?? true, // <-- FIXED HERE
          'avatarUrl': data['profilePictureUrl'] ?? data['avatarUrl'] ?? 'https://i.pravatar.cc/100?img=12',
        });
      }
      users = fetchedUsers;
    } catch (e) {
      // handle error
    }
    notifyListeners();
  }

  void setRole(String role) {
    selectedRole = role;
    notifyListeners();
  }

  void setStatus(String status) {
    selectedStatus = status;
    notifyListeners();
  }

  Future<void> toggleUserEnabled(int index, bool value) async {
    final user = filteredUsers[index];
    final userId = user['id'];
    final role = user['role'].toLowerCase() == 'teacher' ? 'teachers' : 'students';

    await FirebaseFirestore.instance
        .collection(role)
        .doc(userId)
        .update({'enabled': value});

    // Update local list for instant feedback
    filteredUsers[index]['enabled'] = value;
    notifyListeners();

    // Optionally, re-fetch from Firestore to ensure sync
    // await initialize();
  }

  List<Map<String, dynamic>> get filteredUsers {
    return users.where((user) {
      final roleMatch = selectedRole == 'All' || user['role'] == selectedRole;
      final statusMatch = selectedStatus == 'All' ||
        (selectedStatus == 'Enabled' && user['enabled'] == true) ||
        (selectedStatus == 'Disabled' && user['enabled'] == false);
      return roleMatch && statusMatch;
    }).toList();
  }

  Future<Map<String, dynamic>?> fetchUserDetails(String userId, String role) async {
    isLoadingUserDetails = true;
    notifyListeners();
    
    try {
      final collection = role.toLowerCase() == 'teacher' ? 'teachers' : 'students';
      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        isLoadingUserDetails = false;
        notifyListeners();
        return {
          'fullName': data['fullName'] ?? 'N/A',
          'email': data['email'] ?? 'N/A',
          'phoneNumber': data['phoneNumber'] ?? 'N/A',
          'country': data['country'] ?? 'N/A',
          'profilePictureUrl': data['profilePictureUrl'] ?? data['avatarUrl'] ?? 'https://i.pravatar.cc/150',
          'role': role,
          'enabled': data['enabled'] ?? true,
          'uid': data['uid'] ?? userId,
        };
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
    
    isLoadingUserDetails = false;
    notifyListeners();
    return null;
  }
}
