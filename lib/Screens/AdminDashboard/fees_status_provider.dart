import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class FeesStatusProvider extends ChangeNotifier {
  String selectedRole = 'All';
  String selectedStatus = 'All';
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  FeesStatusProvider() {
    _resetFeesIfNeeded();
    fetchUsers();
  }

  Future<void> _resetFeesIfNeeded() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final lastResetMonth = prefs.getInt('lastFeeResetMonth') ?? 0;
    final lastResetYear = prefs.getInt('lastFeeResetYear') ?? 0;
    if (now.day > 1 && (now.month != lastResetMonth || now.year != lastResetYear)) {
      final feeCollection = FirebaseFirestore.instance.collection('fee');
      final feeSnap = await feeCollection.get();
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in feeSnap.docs) {
        final userId = doc.data()['userId'];
        final docId = '${userId}_${now.month}_${now.year}';
        batch.set(feeCollection.doc(docId), {
          ...doc.data(),
          'feeStatus': 'Unpaid',
          'month': now.month,
          'year': now.year,
        }, SetOptions(merge: true));
      }
      await batch.commit();
      await prefs.setInt('lastFeeResetMonth', now.month);
      await prefs.setInt('lastFeeResetYear', now.year);
    }
  }

  Future<void> fetchUsers() async {
    isLoading = true;
    notifyListeners();
    final firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> fetchedUsers = [];
    final now = DateTime.now();
    final month = selectedMonth.month;
    final year = selectedMonth.year;
    try {
      final studentSnap = await firestore.collection('students').get();
      final teacherSnap = await firestore.collection('teachers').get();
      final feeSnap = await firestore.collection('fee').where('month', isEqualTo: month).where('year', isEqualTo: year).get();
      final Map<String, Map<String, dynamic>> feeStatusMap = {
        for (var doc in feeSnap.docs) doc.data()['userId']: doc.data(),
      };
      for (var doc in studentSnap.docs) {
        final data = doc.data();
        final id = doc.id;
        final feeData = feeStatusMap[id];
        fetchedUsers.add({
          'id': id,
          'name': data['fullName'] ?? 'Unnamed',
          'role': 'Student',
          'feeStatus': feeData != null ? (feeData['feeStatus'] ?? 'Unpaid') : 'Unpaid',
          'lastUpdated': feeData != null ? feeData['lastUpdated'] : null,
          'enabled': true,
        });
      }
      for (var doc in teacherSnap.docs) {
        final data = doc.data();
        final id = doc.id;
        final feeData = feeStatusMap[id];
        fetchedUsers.add({
          'id': id,
          'name': data['fullName'] ?? 'Unnamed',
          'role': 'Teacher',
          'feeStatus': feeData != null ? (feeData['feeStatus'] ?? 'Unpaid') : 'Unpaid',
          'lastUpdated': feeData != null ? feeData['lastUpdated'] : null,
          'enabled': true,
        });
      }
      users = fetchedUsers;
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> get filteredUsers {
    return users.where((user) {
      final matchesRole = selectedRole == 'All' || user['role'] == selectedRole;
      final matchesStatus = selectedStatus == 'All' || user['feeStatus'] == selectedStatus;
      final matchesSearch = searchController.text.isEmpty || user['name']!.toLowerCase().contains(searchController.text.toLowerCase());
      return matchesRole && matchesStatus && matchesSearch;
    }).toList();
  }

  void setSelectedRole(String val) {
    selectedRole = val;
    notifyListeners();
  }

  void setSelectedStatus(String val) {
    selectedStatus = val;
    notifyListeners();
  }

  void setSearch(String val) {
    searchController.text = val;
    notifyListeners();
  }

  void setSelectedMonth(DateTime val) async {
    selectedMonth = val;
    isLoading = true;
    notifyListeners();
    await fetchUsers();
  }

  void updateFeeStatus(Map<String, dynamic> user, String newStatus) async {
    user['feeStatus'] = newStatus;
    user['lastUpdated'] = Timestamp.now();
    notifyListeners();
    final userId = user['id'];
    final role = user['role'];
    final now = DateTime.now();
    final docId = '${userId}_${now.month}_${now.year}';
    await FirebaseFirestore.instance.collection('fee').doc(docId).set({
      'userId': userId,
      'role': role,
      'feeStatus': newStatus,
      'month': now.month,
      'year': now.year,
      'lastUpdated': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // Add missing methods for Provider compatibility
  void initialize() async {
    await _resetFeesIfNeeded();
    await fetchUsers();
    isLoading = false;
    notifyListeners();
  }

  void setRole(String val) => setSelectedRole(val);
  void setStatus(String val) => setSelectedStatus(val);
  void setSearchTerm(String val) => setSearch(val);
  void clearSearch() {
    searchController.clear();
    notifyListeners();
  }
  void setMonth(DateTime val) => setSelectedMonth(val);

  Color getRoleColor(String role) {
    if (role == 'Teacher') return Colors.blue;
    if (role == 'Student') return Colors.orange;
    return Colors.grey;
  }

  Color getFeeStatusColor(String status) {
    if (status == 'Paid') return Colors.green;
    if (status == 'Unpaid') return Colors.red;
    return Colors.grey;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
