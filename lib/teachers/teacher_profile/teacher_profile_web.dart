import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../../constants/colors.dart';
import '../../components/teacher_image_picker.dart';
import '../../services/notification_service.dart';
import '../../students/student_notifications/student_notifications.dart';
import '../../views/admin_dashboard/unassigned_users_view/degree_preview_view.dart';
import 'teacher_profile_web_provider.dart';

class TeacherProfileWeb extends StatelessWidget {
  const TeacherProfileWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TeacherProfileWebProvider(),
      child: Consumer<TeacherProfileWebProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                // Sidebar(selectedIndex: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 18,
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Profile',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const Spacer(),
                            // Notification Icon with badge
                            StreamBuilder<QuerySnapshot>(
                              stream:
                                  NotificationService.getNotificationsStream(),
                              builder: (context, snapshot) {
                                int unreadCount = 0;
                                if (snapshot.hasData) {
                                  unreadCount =
                                      snapshot.data!.docs
                                          .where(
                                            (doc) => !(doc['read'] ?? false),
                                          )
                                          .length;
                                }
                                return Stack(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.notifications),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
                                                    const StudentNotificationScreen(),
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
                                height:
                                    MediaQuery.of(context).size.height - 150,
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
                                          backgroundImage:
                                              provider.uploadedImageBytes !=
                                                      null
                                                  ? MemoryImage(
                                                    provider
                                                        .uploadedImageBytes!,
                                                  )
                                                  : (provider
                                                          .profilePictureUrl
                                                          .isNotEmpty
                                                      ? NetworkImage(
                                                            provider
                                                                .profilePictureUrl,
                                                          )
                                                          as ImageProvider
                                                      : null),
                                          backgroundColor:
                                              provider.uploadedImageBytes ==
                                                          null &&
                                                      provider
                                                          .profilePictureUrl
                                                          .isEmpty
                                                  ? appGreen
                                                  : null,
                                          child:
                                              provider.uploadedImageBytes ==
                                                          null &&
                                                      provider
                                                          .profilePictureUrl
                                                          .isEmpty
                                                  ? const Icon(
                                                    Icons.person,
                                                    size: 50,
                                                    color: Colors.white,
                                                  )
                                                  : null,
                                        ),
                                        const SizedBox(height: 10),
                                        TextButton(
                                          onPressed:
                                              provider.isUploadingProfile
                                                  ? null
                                                  : () => provider
                                                      .handleImageUpload(
                                                        context,
                                                        pickImagePlatform,
                                                      ),
                                          child:
                                              provider.isUploadingProfile
                                                  ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(appGreen),
                                                    ),
                                                  )
                                                  : const Text(
                                                    "Upload",
                                                    style: TextStyle(
                                                      color: appGreen,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          provider.fullName.isNotEmpty
                                              ? provider.fullName
                                              : 'Loading...',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          "Teacher",
                                          style: TextStyle(fontSize: 15),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: const [
                                            Icon(
                                              Iconsax.verify,
                                              color: appGreen,
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              "Assigned",
                                              style: TextStyle(color: appGreen),
                                            ),
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
                                height:
                                    MediaQuery.of(context).size.height - 150,
                                child: Card(
                                  shadowColor: Theme.of(context).shadowColor,
                                  color: Theme.of(context).cardColor,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 20),
                                          if (!provider.isEditMode) ...[
                                            buildField(
                                              "Full Name",
                                              provider.fullName.isNotEmpty
                                                  ? provider.fullName
                                                  : 'Loading...',
                                            ),
                                            buildField(
                                              "Email",
                                              provider.email.isNotEmpty
                                                  ? provider.email
                                                  : 'Loading...',
                                            ),
                                            buildField(
                                              "Phone",
                                              provider.phone.isNotEmpty
                                                  ? provider.phone
                                                  : 'Loading...',
                                            ),
                                            buildField(
                                              "Degree",
                                              provider.degree.isNotEmpty
                                                  ? provider.degree
                                                  : 'Loading...',
                                            ),
                                            if (provider
                                                .degreeProofUrl
                                                .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 14.0,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Degree Proof',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: appGrey,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  _,
                                                                ) => DegreePreviewView(
                                                                  imageUrl:
                                                                      provider
                                                                          .degreeProofUrl,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                      child: Container(
                                                        width: double.infinity,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 14,
                                                              vertical: 14,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Theme.of(
                                                                context,
                                                              ).cardColor,
                                                          border: Border.all(
                                                            color: appGrey,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                        child: Row(
                                                          children: const [
                                                            Icon(
                                                              Icons
                                                                  .picture_as_pdf,
                                                              color: appGreen,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              'View Degree Proof',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: appGreen,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ] else ...[
                                            // Edit mode fields
                                            buildEditField(
                                              "Full Name",
                                              provider.fullNameController,
                                            ),
                                            buildEditField(
                                              "Phone",
                                              provider.phoneController,
                                            ),
                                            buildDegreeDropdown(
                                              context,
                                              provider,
                                            ),
                                            if (provider
                                                .degreeProofUrl
                                                .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 14.0,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Current Degree Proof',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: appGrey,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (
                                                                  _,
                                                                ) => DegreePreviewView(
                                                                  imageUrl:
                                                                      provider
                                                                          .degreeProofUrl,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                      child: Container(
                                                        width: double.infinity,
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 14,
                                                              vertical: 14,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Theme.of(
                                                                context,
                                                              ).cardColor,
                                                          border: Border.all(
                                                            color: appGrey,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                        child: Row(
                                                          children: const [
                                                            Icon(
                                                              Icons
                                                                  .picture_as_pdf,
                                                              color: appGreen,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              'View Current Degree Proof',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                color: appGreen,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            const Text(
                                              'Upload New Degree Proof (Optional)',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: appGrey,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                onPressed:
                                                    provider.pickDocument,
                                                icon: const Icon(
                                                  Icons.upload_file,
                                                  color: appGreen,
                                                ),
                                                label: Text(
                                                  provider.newDegreeFile != null
                                                      ? provider
                                                          .newDegreeFile!
                                                          .name
                                                      : 'Upload New Degree Document',
                                                  style: const TextStyle(
                                                    color: appGreen,
                                                  ),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(
                                                    color: appGreen,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 14,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 30),
                                          LayoutBuilder(
                                            builder: (context, constraints) {
                                              if (constraints.maxWidth > 300) {
                                                return Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    if (!provider.isEditMode)
                                                      TextButton(
                                                        onPressed: () {},
                                                        child: const Text(
                                                          "",
                                                          style: TextStyle(
                                                            color: appGreen,
                                                          ),
                                                        ),
                                                      )
                                                    else
                                                      TextButton(
                                                        onPressed:
                                                            provider.cancelEdit,
                                                        child: const Text(
                                                          "Cancel",
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                          ),
                                                        ),
                                                      ),
                                                    if (!provider.isEditMode)
                                                      ElevatedButton(
                                                        onPressed:
                                                            provider
                                                                .toggleEditMode,
                                                        style:
                                                            ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  appGreen,
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                        child: const Text(
                                                          "Edit Profile",
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      )
                                                    else
                                                      ElevatedButton(
                                                        onPressed:
                                                            provider.isSubmitting
                                                                ? null
                                                                : () => provider
                                                                    .updateProfile(
                                                                      context,
                                                                    ),
                                                        style:
                                                            ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  appGreen,
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                        child:
                                                            provider.isSubmitting
                                                                ? const SizedBox(
                                                                  width: 16,
                                                                  height: 16,
                                                                  child: CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                    valueColor:
                                                                        AlwaysStoppedAnimation<
                                                                          Color
                                                                        >(
                                                                          Colors
                                                                              .white,
                                                                        ),
                                                                  ),
                                                                )
                                                                : const Text(
                                                                  "Save Changes",
                                                                  style:
                                                                      TextStyle(
                                                                        fontSize:
                                                                            16,
                                                                      ),
                                                                ),
                                                      ),
                                                  ],
                                                );
                                              } else {
                                                return Column(
                                                  children: [
                                                    if (!provider.isEditMode)
                                                      TextButton(
                                                        onPressed: () {},
                                                        child: const Text(
                                                          "Change Password",
                                                          style: TextStyle(
                                                            color: appGreen,
                                                          ),
                                                        ),
                                                      ),
                                                    if (!provider.isEditMode)
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                    if (!provider.isEditMode)
                                                      Center(
                                                        child: ElevatedButton(
                                                          onPressed:
                                                              provider
                                                                  .toggleEditMode,
                                                          style:
                                                              ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    appGreen,
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                          child: const Text(
                                                            "Edit Profile",
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    else
                                                      Column(
                                                        children: [
                                                          Center(
                                                            child: TextButton(
                                                              onPressed:
                                                                  provider
                                                                      .cancelEdit,
                                                              child: const Text(
                                                                "Cancel",
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          Center(
                                                            child: ElevatedButton(
                                                              onPressed:
                                                                  provider.isSubmitting
                                                                      ? null
                                                                      : () => provider
                                                                          .updateProfile(
                                                                            context,
                                                                          ),
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    appGreen,
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                              child:
                                                                  provider.isSubmitting
                                                                      ? const SizedBox(
                                                                        width:
                                                                            16,
                                                                        height:
                                                                            16,
                                                                        child: CircularProgressIndicator(
                                                                          strokeWidth:
                                                                              2,
                                                                          valueColor: AlwaysStoppedAnimation<
                                                                            Color
                                                                          >(
                                                                            Colors.white,
                                                                          ),
                                                                        ),
                                                                      )
                                                                      : const Text(
                                                                        "Save Changes",
                                                                        style: TextStyle(
                                                                          fontSize:
                                                                              16,
                                                                        ),
                                                                      ),
                                                            ),
                                                          ),
                                                        ],
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

  Widget buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: appGrey),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: appGrey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget buildEditField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: appGrey),
          ),
          const SizedBox(height: 6),
          TextField(
            cursorColor: appGreen,
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: appGrey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: appGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: appGreen),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDegreeDropdown(
    BuildContext context,
    TeacherProfileWebProvider provider,
  ) {
    Color dropdownColor =
        Theme.of(context).brightness == Brightness.dark
            ? darkBackground
            : appLightGreen;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Degree',
            style: TextStyle(fontWeight: FontWeight.bold, color: appGrey),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: appGrey),
            ),
            child: DropdownButton<String>(
              underline: const SizedBox.shrink(),
              value:
                  provider.selectedDegree?.isNotEmpty == true
                      ? provider.selectedDegree
                      : (provider.degree.isNotEmpty ? provider.degree : null),
              hint: Text(
                provider.selectedDegree?.isNotEmpty == true
                    ? provider.selectedDegree!
                    : (provider.degree.isNotEmpty
                        ? provider.degree
                        : 'Select your degree'),
                style: TextStyle(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey[600],
                ),
              ),
              onChanged: (value) => provider.selectedDegree = value,
              items:
                  provider.degrees
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Text(
                            d,
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
                            ),
                          ),
                        ),
                      )
                      .toList(),
              isExpanded: true,
              dropdownColor: dropdownColor,
              borderRadius: BorderRadius.circular(12),
              icon: Icon(Icons.arrow_drop_down, color: appGreen),
              iconSize: 24,
              style: TextStyle(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
