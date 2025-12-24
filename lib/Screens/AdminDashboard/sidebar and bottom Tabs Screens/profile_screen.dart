import 'package:flutter/material.dart';
import 'package:al_mehdi_online_school/constants/colors.dart';
import 'package:al_mehdi_online_school/Screens/AdminDashboard/notifications.dart';
import '../notifications_provider.dart';
import 'profile_screen_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationsProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ProfileScreenProvider()),
      ],
      child: Consumer<ProfileScreenProvider>(
        builder: (context, provider, _) {
          final isWeb = MediaQuery.of(context).size.width >= 900;
          return Scaffold(
            backgroundColor: Colors.white,
            body: isWeb
                ? Scaffold(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    body: SingleChildScrollView(
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
                                AdminNotificationIcon(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Notifications(),
                                      ),
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
                                    height: height - height * 0.2,
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
                                            Stack(
                                              children: [
                                                CircleAvatar(
                                                  radius: 70,
                                                  backgroundImage: provider.profileImageUrl != null
                                                    ? NetworkImage(provider.profileImageUrl!)
                                                    : const NetworkImage(
                                                        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSzmDFOpRqmQmU64T6__2MDOl6NLaCK4I-10MHVrCGltXOSeXcl56_sD59-0ddr4M9aNc0&usqp=CAU',
                                                      ),
                                                ),
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black.withOpacity(0.2),
                                                          blurRadius: 4,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: IconButton(
                                                      icon: provider.isLoading
                                                          ? const SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child: CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                valueColor: AlwaysStoppedAnimation<Color>(appGreen),
                                                              ),
                                                            )
                                                          : const Icon(Icons.camera_alt, color: appGreen, size: 24),
                                                      onPressed: provider.isLoading
                                                          ? null
                                                          : () async {
                                                              try {
                                                                await provider.pickAndUploadImage(context);
                                                                if (context.mounted) {
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    const SnackBar(
                                                                      content: Text('Profile picture updated successfully!'),
                                                                      backgroundColor: appGreen,
                                                                    ),
                                                                  );
                                                                }
                                                              } catch (e) {
                                                                if (context.mounted) {
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    SnackBar(
                                                                      content: Text('Failed to update profile picture: ${e.toString()}'),
                                                                      backgroundColor: Colors.red,
                                                                    ),
                                                                  );
                                                                }
                                                              }
                                                            },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              provider.fullName,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              provider.role,
                                              style: const TextStyle(fontSize: 15),
                                            ),
                                            const SizedBox(height: 30),
                                            ElevatedButton(
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    final nameController = TextEditingController(text: provider.fullName);
                                                    final emailController = TextEditingController(text: provider.email);
                                                    final phoneController = TextEditingController(text: provider.phone);
                                                    return AlertDialog(
                                                      title: const Text('Edit Profile'),
                                                      content: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          TextField(
                                                            controller: nameController,
                                                            decoration: const InputDecoration(labelText: 'Full Name'),
                                                          ),
                                                          SizedBox(height: 10,),
                                                          TextField(
                                                            controller: emailController,
                                                            decoration: const InputDecoration(labelText: 'Email'),
                                                          ),
                                                          SizedBox(height: 10,),
                                                          TextField(
                                                            controller: phoneController,
                                                            decoration: const InputDecoration(labelText: 'Phone'),
                                                          ),
                                                        ],
                                                      ),
                                                      actionsAlignment: MainAxisAlignment.center,
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context),
                                                          child: const Text('Cancel', style: TextStyle(color: Colors.red),),
                                                          style: TextButton.styleFrom(
                                                            shadowColor: Colors.transparent,
                                                            surfaceTintColor: Colors.transparent,
                                                          ),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () async {
                                                            await provider.updateAdminProfile(
                                                              fullName: nameController.text,
                                                              email: emailController.text,
                                                              phone: phoneController.text,
                                                            );
                                                            Navigator.pop(context);
                                                          },
                                                          child: const Text('Save Changes'),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: appGreen,
                                                            foregroundColor: Colors.white
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: appGreen,
                                                foregroundColor: Colors.white,
                                                minimumSize: const Size.fromHeight(48),
                                              ),
                                              child: const Text(
                                                "Edit Changes",
                                                style: TextStyle(fontSize: 16),
                                              ),
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
                                    height: height - height * 0.2,
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
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Profile Info',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 20),
                                                    const Text(
                                                      'Full Name',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: appGrey,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      width: double.infinity,
                                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).cardColor,
                                                        border: Border.all(color: appGrey),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        provider.fullName,
                                                        style: const TextStyle(fontSize: 14),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 14),
                                                    const Text(
                                                      'Email',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: appGrey,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      width: double.infinity,
                                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).cardColor,
                                                        border: Border.all(color: appGrey),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        provider.email,
                                                        style: const TextStyle(fontSize: 14),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 14),
                                                    const Text(
                                                      'Phone',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: appGrey,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      width: double.infinity,
                                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).cardColor,
                                                        border: Border.all(color: appGrey),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: Text(
                                                        provider.phone,
                                                        style: const TextStyle(fontSize: 14),
                                                      ),
                                                    ),
                                                    // Removed "Class" field
                                                    const SizedBox(height: 30),
                                                    TextButton(
                                                      onPressed: () {},
                                                      child: const Text(
                                                        "Change Password",
                                                        style: TextStyle(color: appGreen),
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
                  )
                : Scaffold(
                    appBar: AppBar(
                      title: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: const Text(
                          'Profile',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.notifications),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Notifications(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    body: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 70,
                                      backgroundImage: provider.profileImageUrl != null
                                        ? NetworkImage(provider.profileImageUrl!)
                                        : const NetworkImage(
                                            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSzmDFOpRqmQmU64T6__2MDOl6NLaCK4I-10MHVrCGltXOSeXcl56_sD59-0ddr4M9aNc0&usqp=CAU',
                                          ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: provider.isLoading
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(appGreen),
                                                  ),
                                                )
                                              : const Icon(Icons.camera_alt, color: appGreen, size: 24),
                                          onPressed: provider.isLoading
                                              ? null
                                              : () async {
                                                  try {
                                                    await provider.pickAndUploadImage(context);
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('Profile picture updated successfully!'),
                                                          backgroundColor: appGreen,
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('Failed to update profile picture: ${e.toString()}'),
                                                          backgroundColor: Colors.red,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  provider.fullName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  provider.role,
                                  style: const TextStyle(fontSize: 15),
                                ),
                                const SizedBox(height: 30),
                                // ElevatedButton(
                                //   onPressed: () {
                                //     showDialog(
                                //       context: context,
                                //       builder: (context) {
                                //         final nameController = TextEditingController(text: provider.fullName);
                                //         final emailController = TextEditingController(text: provider.email);
                                //         final phoneController = TextEditingController(text: provider.phone);
                                //         return AlertDialog(
                                //           title: const Text('Edit Profile'),
                                //           content: Column(
                                //             mainAxisSize: MainAxisSize.min,
                                //             children: [
                                //               TextField(
                                //                 controller: nameController,
                                //                 decoration: const InputDecoration(labelText: 'Full Name'),
                                //               ),
                                //               SizedBox(height: 10,),
                                //               TextField(
                                //                 controller: emailController,
                                //                 decoration: const InputDecoration(labelText: 'Email'),
                                //               ),
                                //               SizedBox(height: 10,),
                                //               TextField(
                                //                 controller: phoneController,
                                //                 decoration: const InputDecoration(labelText: 'Phone'),
                                //               ),
                                //             ],
                                //           ),
                                //           actions: [
                                //             TextButton(
                                //               onPressed: () => Navigator.pop(context),
                                //               child: const Text('Cancel', style: TextStyle(color: Colors.red),),
                                //             ),
                                //             ElevatedButton(
                                //               onPressed: () async {
                                //                 await provider.updateAdminProfile(
                                //                   fullName: nameController.text,
                                //                   email: emailController.text,
                                //                   phone: phoneController.text,
                                //                 );
                                //                 Navigator.pop(context);
                                //               },
                                //               child: const Text('Save Changes'),
                                //               style: ElevatedButton.styleFrom(
                                //                   backgroundColor: appGreen,
                                //                   foregroundColor: Colors.white
                                //               ),
                                //             ),
                                //           ],
                                //         );
                                //       },
                                //     );
                                //   },
                                //   style: ElevatedButton.styleFrom(
                                //     backgroundColor: appGreen,
                                //     foregroundColor: Colors.white,
                                //     minimumSize: const Size.fromHeight(48),
                                //   ),
                                //   child: const Text(
                                //     "Edit Changes",
                                //     style: TextStyle(fontSize: 16),
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Full Name',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: appGrey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    border: Border.all(color: appGrey),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    provider.fullName,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Email',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: appGrey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    border: Border.all(color: appGrey),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    provider.email,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Phone',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: appGrey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    border: Border.all(color: appGrey),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    provider.phone,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                // Removed "Class" field
                                const SizedBox(height: 30),
                                ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        final nameController = TextEditingController(text: provider.fullName);
                                        final emailController = TextEditingController(text: provider.email);
                                        final phoneController = TextEditingController(text: provider.phone);
                                        return AlertDialog(
                                          title: const Text('Edit Profile'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                controller: nameController,
                                                decoration: const InputDecoration(labelText: 'Full Name'),
                                              ),
                                              SizedBox(height: 10,),
                                              TextField(
                                                controller: emailController,
                                                decoration: const InputDecoration(labelText: 'Email'),
                                              ),
                                              SizedBox(height: 10,),
                                              TextField(
                                                controller: phoneController,
                                                decoration: const InputDecoration(labelText: 'Phone'),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel', style: TextStyle(color: Colors.red),),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                await provider.updateAdminProfile(
                                                  fullName: nameController.text,
                                                  email: emailController.text,
                                                  phone: phoneController.text,
                                                );
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Save Changes'),
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: appGreen,
                                                  foregroundColor: Colors.white
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: appGreen,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                  child: const Text(
                                    "Edit Changes",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
          );
        },
      ),
    );
  }
}
