import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfileEditProvider extends ChangeNotifier {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController classController = TextEditingController();
  bool isSubmitting = false;

  void initialize(String currentFullName, String currentPhone, String currentClass) {
    fullNameController.text = currentFullName;
    phoneController.text = currentPhone;
    classController.text = currentClass;
    notifyListeners();
  }

  Future<void> saveChanges(BuildContext context) async {
    if (fullNameController.text.isEmpty || phoneController.text.isEmpty || classController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All fields are required")));
      return;
    }
    isSubmitting = true;
    notifyListeners();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");
      await FirebaseFirestore.instance.collection('students').doc(user.uid).update({
        'fullName': fullNameController.text.trim(),
        'phoneNumber': phoneController.text.trim(),
        'grade': classController.text.trim(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: "+e.toString())));
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    classController.dispose();
    super.dispose();
  }
}
