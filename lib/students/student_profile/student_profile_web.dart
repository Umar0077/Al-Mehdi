import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../students/student_notifications/student_notifications.dart';
import '../../components/teacher_image_picker.dart'; // reuse teacher image picker
import '../../services/notification_service.dart';
import 'student_profile_web_provider.dart';

class StudentProfileWeb extends StatelessWidget {
  const StudentProfileWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StudentProfileWebProvider>(
      create: (_) => StudentProfileWebProvider(),
      child: Consumer<StudentProfileWebProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                              child: Row(
                                children: [
                                  const Text(
                                    'Profile',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                                  ),
                                  const Spacer(),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: NotificationService.getNotificationsStream(),
                                    builder: (context, snapshot) {
                                      int unreadCount = 0;
                                      if (snapshot.hasData) {
                                        unreadCount = snapshot.data!.docs.where((doc) => !(doc['read'] ?? false)).length;
                                      }
                                      return Stack(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.notifications),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => const StudentNotificationScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                          if (unreadCount > 0)
                                            Positioned(
                                              right: 8,
                                              top: 8,
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: MediaQuery.of(context).size.height - 150,
                                      child: Card(
                                        color: Theme.of(context).cardColor,
                                        shadowColor: Theme.of(context).shadowColor,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            children: [
                                              CircleAvatar(
                                                radius: 70,
                                                backgroundImage: provider.uploadedImageBytes != null
                                                    ? MemoryImage(provider.uploadedImageBytes!)
                                                    : (provider.profilePictureUrl.isNotEmpty
                                                        ? NetworkImage(provider.profilePictureUrl) as ImageProvider
                                                        : null),
                                                backgroundColor: provider.uploadedImageBytes == null && provider.profilePictureUrl.isEmpty
                                                    ? Colors.purple[100]
                                                    : null,
                                                child: provider.uploadedImageBytes == null && provider.profilePictureUrl.isEmpty
                                                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                                                    : null,
                                              ),
                                              const SizedBox(height: 10),
                                              TextButton(
                                                onPressed: provider.isUploadingProfile
                                                    ? null
                                                    : () => provider.handleImageUpload(pickImagePlatform, context),
                                                child: provider.isUploadingProfile
                                                    ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor: AlwaysStoppedAnimation<Color>(appGreen),
                                                        ),
                                                      )
                                                    : const Text(
                                                        "Upload",
                                                        style: TextStyle(color: appGreen, fontSize: 15),
                                                      ),
                                              ),
                                              const SizedBox(height: 20),
                                              Text(
                                                provider.fullName,
                                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 10),
                                              const Text("Student", style: TextStyle(fontSize: 15)),
                                              const SizedBox(height: 10),
                                              const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Iconsax.verify, color: appGreen),
                                                  SizedBox(width: 5),
                                                  Text("Enrolled", style: TextStyle(color: appGreen)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: SizedBox(
                                      height: MediaQuery.of(context).size.height - 150,
                                      child: Card(
                                        color: Theme.of(context).cardColor,
                                        shadowColor: Theme.of(context).shadowColor,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(height: 15),
                                                if (!provider.isEditMode) ...[
                                                  buildField(context, "Full Name", provider.fullName),
                                                  buildField(context, "Email", provider.email),
                                                  buildField(context, "Phone", provider.phone),
                                                  buildField(context, "Class", provider.studentClass),
                                                ] else ...[
                                                  buildEditField(context, "Full Name", provider.fullNameController),
                                                  buildField(context, "Email", provider.email),
                                                  buildEditField(context, "Phone", provider.phoneController),
                                                  buildEditField(context, "Class", provider.classController),
                                                ],
                                                const SizedBox(height: 30),
                                                LayoutBuilder(
                                                  builder: (context, constraints) {
                                                    if (constraints.maxWidth > 300) {
                                                      return Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          if (!provider.isEditMode)
                                                            TextButton(
                                                              onPressed: () {},
                                                              child: const Text("", style: TextStyle(color: appGreen)),
                                                            )
                                                          else
                                                            TextButton(
                                                              onPressed: provider.cancelEdit,
                                                              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
                                                            ),
                                                          if (!provider.isEditMode)
                                                            ElevatedButton(
                                                              onPressed: provider.isSaving ? null : provider.toggleEditMode,
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: appGreen,
                                                                foregroundColor: Colors.white,
                                                              ),
                                                              child: provider.isSaving
                                                                  ? const SizedBox(
                                                                      width: 18,
                                                                      height: 18,
                                                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                                    )
                                                                  : const Text("Edit Profile", style: TextStyle(fontSize: 16)),
                                                            )
                                                          else
                                                            ElevatedButton(
                                                              onPressed: provider.isSaving ? null : () => provider.saveChanges(context),
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: appGreen,
                                                                foregroundColor: Colors.white,
                                                              ),
                                                              child: provider.isSaving
                                                                  ? const SizedBox(
                                                                      width: 18,
                                                                      height: 18,
                                                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                                    )
                                                                  : const Text("Save Changes", style: TextStyle(fontSize: 16)),
                                                            ),
                                                        ],
                                                      );
                                                    } else {
                                                      return Column(
                                                        children: [
                                                          if (!provider.isEditMode)
                                                            Center(
                                                              child: TextButton(
                                                                onPressed: () {},
                                                                child: const Text("Change Password", style: TextStyle(color: appGreen)),
                                                              ),
                                                            )
                                                          else
                                                            Center(
                                                              child: TextButton(
                                                                onPressed: provider.cancelEdit,
                                                                child: const Text("Cancel", style: TextStyle(color: Colors.red)),
                                                              ),
                                                            ),
                                                          if (!provider.isEditMode)
                                                            const SizedBox(height: 10),
                                                          if (!provider.isEditMode)
                                                            Center(
                                                              child: ElevatedButton(
                                                                onPressed: provider.isSaving ? null : provider.toggleEditMode,
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: appGreen,
                                                                  foregroundColor: Colors.white,
                                                                ),
                                                                child: provider.isSaving
                                                                    ? const SizedBox(
                                                                        width: 18,
                                                                        height: 18,
                                                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                                      )
                                                                    : const Text("Edit Profile", style: TextStyle(fontSize: 16)),
                                                              ),
                                                            )
                                                          else
                                                            Center(
                                                              child: ElevatedButton(
                                                                onPressed: provider.isSaving ? null : () => provider.saveChanges(context),
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: appGreen,
                                                                  foregroundColor: Colors.white,
                                                                ),
                                                                child: provider.isSaving
                                                                    ? const SizedBox(
                                                                        width: 18,
                                                                        height: 18,
                                                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                                      )
                                                                    : const Text("Save Changes", style: TextStyle(fontSize: 16)),
                                                              ),
                                                            ),
                                                        ],
                                                      );
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildField(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: appGrey)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(color: appGrey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget buildEditField(BuildContext context, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: appGrey)),
          const SizedBox(height: 6),
          TextField(
            cursorColor: appGreen,
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: appGrey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: appGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: appGreen),
              ),
            ),
          ),
        ],
      ),
    );
  }

  
}
