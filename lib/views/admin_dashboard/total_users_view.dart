import 'package:al_mehdi_online_school/views/admin_dashboard/admin_home_view.dart';
import 'package:al_mehdi_online_school/views/admin_dashboard/notifications_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/colors.dart';
import '../../providers/unassigned_user_screens/notifications_provider.dart';
import '../../providers/unassigned_user_screens/total_users_provider.dart';

// NOTE: NotificationsProvider should be provided at the app or dashboard root, not here!
class TotalUsersView extends StatelessWidget {
  const TotalUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationsProvider>(
      create: (_) => NotificationsProvider(),
      child: ChangeNotifierProvider<TotalUsersProvider>(
        create: (_) => TotalUsersProvider()..initialize(),
        child: const _TotalUsersView(),
      ),
    );
  }
}

class _TotalUsersView extends StatefulWidget {
  const _TotalUsersView();

  @override
  State<_TotalUsersView> createState() => _TotalUsersViewState();
}

class _TotalUsersViewState extends State<_TotalUsersView> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      Provider.of<TotalUsersProvider>(context, listen: false).initialize();
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TotalUsersProvider>(context);
    Color dropdownColor =
        Theme.of(context).brightness == Brightness.dark
            ? darkBackground
            : appLightGreen;

    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;
    final double padding = isWeb ? 32 : 16;
    final double fontSize = isWeb ? 16 : 15;
    final double avatarRadius = isWeb ? 28 : 22;
    final double cardSpacing = isWeb ? 16 : 10;
    final double dropdownWidth = isWeb ? 180 : 140;

    if (isWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: Row(
                children: [
                  Expanded(
                    child: Scaffold(
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      body:
                          provider.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : SafeArea(
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
                                            'Total Users',
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
                                                  builder:
                                                      (context) =>
                                                          NotificationView(),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Divider(),
                                    const SizedBox(height: 16),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: padding,
                                      ),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth:
                                                constraints.maxWidth -
                                                padding * 2,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                width: dropdownWidth,
                                                child: _buildDropdown(
                                                  context,
                                                  'Role',
                                                  ['All', 'Student', 'Teacher'],
                                                  provider.selectedRole,
                                                  provider.setRole,
                                                  dropdownWidth,
                                                  fontSize,
                                                  dropdownColor,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              SizedBox(
                                                width: dropdownWidth,
                                                child: _buildDropdown(
                                                  context,
                                                  'Status',
                                                  [
                                                    'All',
                                                    'Enabled',
                                                    'Disabled',
                                                  ],
                                                  provider.selectedStatus,
                                                  provider.setStatus,
                                                  dropdownWidth,
                                                  fontSize,
                                                  dropdownColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Ensure the list gets all remaining space
                                    Expanded(
                                      child: ListView.separated(
                                        itemCount:
                                            provider.filteredUsers.length,
                                        separatorBuilder:
                                            (_, __) =>
                                                SizedBox(height: cardSpacing),
                                        itemBuilder: (context, index) {
                                          final user =
                                              provider.filteredUsers[index];
                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: padding,
                                            ),
                                            child: InkWell(
                                              onTap:
                                                  () => _showUserDetailsPopup(
                                                    context,
                                                    user,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Card(
                                                color:
                                                    Theme.of(context).cardColor,
                                                shadowColor:
                                                    Theme.of(
                                                      context,
                                                    ).shadowColor,
                                                elevation: 1,
                                                margin: EdgeInsets.only(
                                                  bottom: cardSpacing,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 10,
                                                      ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      CircleAvatar(
                                                        radius: avatarRadius,
                                                        backgroundImage:
                                                            NetworkImage(
                                                              user['avatarUrl'],
                                                            ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            RichText(
                                                              text: TextSpan(
                                                                style: TextStyle(
                                                                  color:
                                                                      Theme.of(
                                                                            context,
                                                                          )
                                                                          .textTheme
                                                                          .bodyLarge
                                                                          ?.color,
                                                                  fontSize:
                                                                      fontSize,
                                                                ),
                                                                children: [
                                                                  const TextSpan(
                                                                    text:
                                                                        'Name: ',
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                  TextSpan(
                                                                    text:
                                                                        user['name'],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            RichText(
                                                              text: TextSpan(
                                                                style: TextStyle(
                                                                  color:
                                                                      Theme.of(
                                                                            context,
                                                                          )
                                                                          .textTheme
                                                                          .bodyLarge
                                                                          ?.color,
                                                                  fontSize:
                                                                      fontSize,
                                                                ),
                                                                children: [
                                                                  const TextSpan(
                                                                    text:
                                                                        'Role: ',
                                                                    style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                                  ),
                                                                  TextSpan(
                                                                    text:
                                                                        user['role'],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          provider.toggleUserEnabled(
                                                            index,
                                                            !(user['enabled'] ??
                                                                false),
                                                          );
                                                        },
                                                        style: TextButton.styleFrom(
                                                          backgroundColor:
                                                              (user['enabled'] ??
                                                                      false)
                                                                  ? Colors.green
                                                                  : Colors.red,
                                                          foregroundColor:
                                                              Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20,
                                                                ),
                                                          ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 20,
                                                                vertical: 10,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          (user['enabled'] ??
                                                                  false)
                                                              ? 'Enabled'
                                                              : 'Disabled',
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            );
          }
          // Optionally, return the mobile layout for smaller widths:
          return _mobileLayout(context, provider);
        },
      );
    }
    return _mobileLayout(context, provider);
  }

  Widget _buildDropdown(
    BuildContext context,
    String label,
    List<String> options,
    String selectedValue,
    Function(String) onChanged,
    double width,
    double fontSize,
    Color bgColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(20),
      ),
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(left: 5),
        child: DropdownButton<String>(
          padding: EdgeInsets.symmetric(horizontal: 8),
          focusColor: Colors.transparent,
          icon: const Icon(Icons.arrow_drop_down, color: appGreen),
          underline: const SizedBox.shrink(),
          dropdownColor: bgColor,
          value: selectedValue,
          isExpanded: true,
          onChanged: (value) => onChanged(value ?? options[0]),
          items:
              options
                  .map(
                    (val) => DropdownMenuItem(
                      value: val,
                      child: Text(
                        val,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  )
                  .toList(),
          style: TextStyle(fontSize: fontSize),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _mobileLayout(BuildContext context, TotalUsersProvider provider) {
    Color dropdownColor =
        Theme.of(context).brightness == Brightness.dark
            ? darkBackground
            : appLightGreen;
    final double padding = 16;
    final double fontSize = 15;
    final double avatarRadius = 22;
    final double cardSpacing = 10;
    final double dropdownWidth = 140;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminHomeView()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AdminHomeView()),
              );
            },
          ),
          title: const Text(
            'Total Users',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
        ),
        body:
            provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              context,
                              'Role',
                              ['All', 'Student', 'Teacher'],
                              provider.selectedRole,
                              provider.setRole,
                              dropdownWidth,
                              fontSize,
                              dropdownColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              context,
                              'Status',
                              ['All', 'Enabled', 'Disabled'],
                              provider.selectedStatus,
                              provider.setStatus,
                              dropdownWidth,
                              fontSize,
                              dropdownColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.separated(
                          itemCount: provider.filteredUsers.length,
                          separatorBuilder:
                              (_, __) => SizedBox(height: cardSpacing),
                          itemBuilder: (context, index) {
                            final user = provider.filteredUsers[index];
                            return InkWell(
                              onTap: () => _showUserDetailsPopup(context, user),
                              borderRadius: BorderRadius.circular(12),
                              child: Card(
                                color: Theme.of(context).cardColor,
                                shadowColor: Theme.of(context).shadowColor,
                                elevation: 1,
                                margin: EdgeInsets.only(bottom: cardSpacing),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: avatarRadius,
                                        backgroundImage: NetworkImage(
                                          user['avatarUrl'],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                style: TextStyle(
                                                  color:
                                                      Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color,
                                                  fontSize: fontSize,
                                                ),
                                                children: [
                                                  const TextSpan(
                                                    text: 'Name: ',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  TextSpan(text: user['name']),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            RichText(
                                              text: TextSpan(
                                                style: TextStyle(
                                                  color:
                                                      Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color,
                                                  fontSize: fontSize,
                                                ),
                                                children: [
                                                  const TextSpan(
                                                    text: 'Role: ',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  TextSpan(text: user['role']),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          provider.toggleUserEnabled(
                                            index,
                                            !(user['enabled'] ?? false),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor:
                                              (user['enabled'] ?? false)
                                                  ? Colors.green
                                                  : Colors.red,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 10,
                                          ),
                                        ),
                                        child: Text(
                                          (user['enabled'] ?? false)
                                              ? 'Enabled'
                                              : 'Disabled',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  void _showUserDetailsPopup(
    BuildContext context,
    Map<String, dynamic> user,
  ) async {
    final provider = Provider.of<TotalUsersProvider>(context, listen: false);
    final userIndex = provider.filteredUsers.indexWhere(
      (u) => u['id'] == user['id'],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            child: FutureBuilder<Map<String, dynamic>?>(
              future: provider.fetchUserDetails(user['id'], user['role']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    height: 300,
                    padding: const EdgeInsets.all(24),
                    child: const Center(
                      child: CircularProgressIndicator(color: appGreen),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return Container(
                    height: 300,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: appRed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load user details',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Close',
                            style: TextStyle(color: appGreen),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final userDetails = snapshot.data!;
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Header with close button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'User Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                              color: appGrey,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Profile Picture
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: appGreen, width: 3),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundImage: NetworkImage(
                              userDetails['profilePictureUrl'],
                            ),
                            onBackgroundImageError: (_, __) {},
                            child:
                                userDetails['profilePictureUrl'].isEmpty
                                    ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: appGrey,
                                    )
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // User Information Cards
                        _buildInfoCard(
                          context,
                          'Full Name',
                          userDetails['fullName'],
                          Icons.person,
                        ),
                        const SizedBox(height: 12),

                        _buildInfoCard(
                          context,
                          'Email',
                          userDetails['email'],
                          Icons.email,
                        ),
                        const SizedBox(height: 12),

                        _buildInfoCard(
                          context,
                          'Phone Number',
                          userDetails['phoneNumber'],
                          Icons.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          context,
                          'Country',
                          userDetails['country'] ?? 'N/A',
                          Icons.public,
                        ),
                        const SizedBox(height: 12),

                        _buildInfoCard(
                          context,
                          'Role',
                          userDetails['role'],
                          Icons.work,
                        ),
                        const SizedBox(height: 12),

                        // Status Toggle Button
                        StatefulBuilder(
                          builder: (context, setState) {
                            final currentUser =
                                userIndex >= 0
                                    ? provider.filteredUsers[userIndex]
                                    : user;
                            final isEnabled = currentUser['enabled'] ?? false;

                            return TextButton(
                              onPressed:
                                  userIndex >= 0
                                      ? () async {
                                        await provider.toggleUserEnabled(
                                          userIndex,
                                          !isEnabled,
                                        );
                                        setState(
                                          () {},
                                        ); // Refresh the dialog state
                                      }
                                      : null,
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    isEnabled ? Colors.green : Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isEnabled
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEnabled ? 'Enabled' : 'Disabled',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Close Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade700
                  : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: appLightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: appGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: appGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w600,
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
