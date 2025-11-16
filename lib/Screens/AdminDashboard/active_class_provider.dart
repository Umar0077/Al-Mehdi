import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActiveClassProvider extends ChangeNotifier {
  List<Map<String, dynamic>> activeClasses = [];
  bool loading = true;

  ActiveClassProvider() {
    fetchActiveClasses();
  }

  Future<void> fetchActiveClasses() async {
    loading = true;
    notifyListeners();
    final snapshot = await FirebaseFirestore.instance
        .collection('classes')
        .where('status', isEqualTo: 'active')
        .get();
    activeClasses = snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
    loading = false;
    notifyListeners();
  }
}
