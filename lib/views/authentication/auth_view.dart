import 'package:al_mehdi_online_school/views/admin_dashboard/sidebar_and%20bottom_tabs_views/admin_main_view.dart';
import 'package:al_mehdi_online_school/views/admin_dashboard/unassigned_users_view/wait_for_assignment_view.dart';
import 'package:al_mehdi_online_school/views/authentication/login_view.dart';
import 'package:al_mehdi_online_school/views/students/student_home_screen/student_home_screen.dart';
import 'package:al_mehdi_online_school/views/teachers/teacher_home_screen/teacher_home_screen.dart';
import 'package:al_mehdi_online_school/constants/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthView extends StatelessWidget {
  const AuthView({super.key});

  Future<Widget> _determineRoleAndNavigate(User user) async {
    final uid = user.uid;

    try {
      // Check if user is a student
      final studentDoc =
          await FirebaseFirestore.instance.collection('students').doc(uid).get();
      if (studentDoc.exists) {
        // Check if student is assigned to a teacher
        final assignedTeacherId = studentDoc.data()?['assignedTeacherId'];
        if (assignedTeacherId == null) {
          // Student not assigned yet - show waiting screen
          return const WaitForAssignmentView(role: 'Student');
        }
        // Student is assigned - go to home screen
        return const StudentHomeScreen();
      }

      // Check if user is a teacher
      final teacherDoc =
          await FirebaseFirestore.instance.collection('teachers').doc(uid).get();
      if (teacherDoc.exists) {
        // Check if teacher is assigned to a student
        final assignedStudentId = teacherDoc.data()?['assignedStudentId'];
        if (assignedStudentId == null) {
          // Teacher not assigned yet - show waiting screen
          return const WaitForAssignmentView(role: 'Teacher');
        }
        // Teacher is assigned - go to home screen
        return const TeacherHomeScreen();
      }

      // Check if user is an admin
      final adminDoc =
          await FirebaseFirestore.instance.collection('admin').doc(uid).get();
      if (adminDoc.exists) {
        return const AdminMainView();
      }
    } catch (e) {
      // Handle Firestore errors gracefully
      return _buildErrorScreen('Unable to verify your account. Please check your internet connection and try again.');
    }

    // User not found in any collection - show error with option to go back
    return _buildErrorScreen('Your account is not registered in our system. Please complete your registration or contact support.');
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                "Unknown role or user not found",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'Sign Out & Return to Login',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: appGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data != null) {
            return FutureBuilder<Widget>(
              future: _determineRoleAndNavigate(snapshot.data!),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (roleSnapshot.hasData) {
                  return roleSnapshot.data!;
                } else {
                  return const Center(child: Text("Error loading user role"));
                }
              },
            );
          } else {
            return LoginView();
          }
        },
      ),
    );
  }
}
