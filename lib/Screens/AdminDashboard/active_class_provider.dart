import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ActiveClassProvider extends ChangeNotifier {
  List<Map<String, dynamic>> activeClasses = [];
  bool loading = true;

  ActiveClassProvider() {
    fetchActiveClasses();
  }

  Future<void> fetchActiveClasses() async {
    loading = true;
    notifyListeners();
    final snapshot =
        await FirebaseFirestore.instance
            .collection('classes')
            .where('status', isEqualTo: 'active')
            .get();
    activeClasses = snapshot.docs.map((doc) => doc.data()).toList();
    loading = false;
    notifyListeners();
  }
}
