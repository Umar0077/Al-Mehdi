import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../components/custom_button.dart';
// Removed unused imports
import '../../../components/custom_textfield.dart';
import '../../../providers/students/profile/student_profile_edit_provider.dart';

class StudentProfileEditScreen extends StatelessWidget {
  final String currentFullName;
  final String currentPhone;
  final String currentClass;

  const StudentProfileEditScreen({
    super.key,
    required this.currentFullName,
    required this.currentPhone,
    required this.currentClass,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StudentProfileEditProvider>(
      create: (_) {
        final provider = StudentProfileEditProvider();
        provider.initialize(currentFullName, currentPhone, currentClass);
        return provider;
      },
      child: Consumer<StudentProfileEditProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),
                  CustomTextfield(
                    width: double.infinity,
                    labelText: 'Full Name',
                    controller: provider.fullNameController,
                  ),
                  const SizedBox(height: 16),
                  CustomTextfield(
                    width: double.infinity,
                    labelText: 'Phone Number',
                    controller: provider.phoneController,
                  ),
                  const SizedBox(height: 16),
                  CustomTextfield(
                    width: double.infinity,
                    labelText: 'Class',
                    controller: provider.classController,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 45,
                          child:
                              provider.isSubmitting
                                  ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                  : CustomButton(
                                    text: 'Save Changes',
                                    onPressed:
                                        () => provider.saveChanges(context),
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
