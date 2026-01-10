import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../constants/colors.dart';
import '../../../providers/students/profile/student_profile_mobile_provider.dart';
import 'student_profile_edit_screen.dart';

class StudentProfileMobile extends StatelessWidget {
  const StudentProfileMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StudentProfileMobileProvider>(
      create: (_) => StudentProfileMobileProvider(),
      child: Consumer<StudentProfileMobileProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: const Text(
                  'Profile',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
              ),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading profile...'),
                  ],
                ),
              ),
            );
          }

          if (provider.error != null) {
            return Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: const Text(
                  'Profile',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading profile',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.refreshProfile(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const Text(
                'Profile',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed:
                      provider.isLoading
                          ? null
                          : () => provider.refreshProfile(),
                  tooltip: 'Refresh Profile',
                ),
              ],
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: RefreshIndicator(
              onRefresh: provider.refreshProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Enhanced Profile Picture Section
                      _buildProfilePictureSection(context, provider),
                      const SizedBox(height: 24),

                      // Student Information Card
                      _buildInfoCard(context, provider),
                      const SizedBox(height: 20),

                      // Teacher Information Card (if assigned)
                      if (provider.assignedTeacherId != null)
                        _buildTeacherInfoCard(context, provider),

                      const SizedBox(height: 24),

                      // Action Buttons
                      _buildActionButtons(context, provider),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Enhanced Profile Picture Section
  Widget _buildProfilePictureSection(
    BuildContext context,
    StudentProfileMobileProvider provider,
  ) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
                  provider.selectedImage != null
                      ? FileImage(provider.selectedImage!)
                      : (provider.profilePictureUrl.isNotEmpty
                          ? NetworkImage(provider.profilePictureUrl)
                              as ImageProvider
                          : null),
              child:
                  provider.profilePictureUrl.isEmpty &&
                          provider.selectedImage == null
                      ? Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey.shade400,
                      )
                      : null,
            ),
            if (provider.isUploading)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: appGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed:
                      provider.isUploading
                          ? null
                          : () => provider.pickImage(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          provider.fullName.isNotEmpty ? provider.fullName : 'Student',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        if (provider.email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            provider.email,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ],
    );
  }

  // Student Information Card
  Widget _buildInfoCard(
    BuildContext context,
    StudentProfileMobileProvider provider,
  ) {
    return Card(
      elevation: 2,
      color: Theme.of(context).scaffoldBackgroundColor,
      shadowColor: Theme.of(context).shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: appGreen),
                const SizedBox(width: 8),
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Full Name', provider.fullName),
            _buildInfoRow(Icons.email_outlined, 'Email', provider.email),
            _buildInfoRow(Icons.phone, 'Phone', provider.phone),
            _buildInfoRow(Icons.school, 'Class', provider.studentClass),
          ],
        ),
      ),
    );
  }

  // Teacher Information Card
  Widget _buildTeacherInfoCard(
    BuildContext context,
    StudentProfileMobileProvider provider,
  ) {
    return Card(
      elevation: 2,
      color: Theme.of(context).scaffoldBackgroundColor,
      shadowColor: Theme.of(context).shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school_outlined, color: appGreen),
                const SizedBox(width: 8),
                const Text(
                  'Assigned Teacher',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.person_outline,
              'Teacher Name',
              provider.assignedTeacherName ?? 'Loading...',
            ),
          ],
        ),
      ),
    );
  }

  // Action Buttons
  Widget _buildActionButtons(
    BuildContext context,
    StudentProfileMobileProvider provider,
  ) {
    return Column(
      children: [
        // Edit Profile Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                provider.isSaving
                    ? null
                    : () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => StudentProfileEditScreen(
                                currentFullName: provider.fullName,
                                currentPhone: provider.phone,
                                currentClass: provider.studentClass,
                              ),
                        ),
                      );
                      if (result == true) {
                        provider.refreshProfile();
                      }
                    },
            style: ElevatedButton.styleFrom(
              backgroundColor: appGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon:
                provider.isSaving
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.edit),
            label: Text(
              provider.isSaving ? 'Saving...' : 'Edit Profile',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Change Password Button
      ],
    );
  }

  // Helper method for info rows
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : 'Not specified',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: value.isNotEmpty ? null : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
