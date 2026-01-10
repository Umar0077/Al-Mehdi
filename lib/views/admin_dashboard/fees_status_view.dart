import 'package:al_mehdi_online_school/views/admin_dashboard/admin_home_view.dart';
import 'package:al_mehdi_online_school/views/admin_dashboard/notifications_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/colors.dart';
import '../../providers/unassigned_user_screens/fees_status_provider.dart';
import '../../providers/unassigned_user_screens/notifications_provider.dart';

class FeesStatusView extends StatelessWidget {
  const FeesStatusView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationsProvider>(
      create: (_) => NotificationsProvider(),
      child: ChangeNotifierProvider<FeesStatusProvider>(
        create: (_) => FeesStatusProvider()..initialize(),
        child: const _FeesStatusView(),
      ),
    );
  }
}

class _FeesStatusView extends StatelessWidget {
  const _FeesStatusView();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FeesStatusProvider>(context);
    Color dropdownColor =
        Theme.of(context).brightness == Brightness.dark
            ? darkBackground
            : appLightGreen;
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 600;

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
                      appBar: null,
                      body: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 18,
                            ),
                            child: Row(
                              children: [
                                Builder(
                                  builder: (context) {
                                    final isSmallScreen =
                                        MediaQuery.of(context).size.width < 400;
                                    return Text(
                                      'Fee Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 20 : 24,
                                      ),
                                    );
                                  },
                                ),
                                const Spacer(),
                                AdminNotificationIcon(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const NotificationView(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          Expanded(
                            child: _feesStatusBody(
                              context,
                              provider,
                              dropdownColor,
                              screenWidth,
                              isWeb,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return _mobileLayout(
            context,
            provider,
            dropdownColor,
            screenWidth,
            isWeb,
          );
        },
      );
    }
    return _mobileLayout(context, provider, dropdownColor, screenWidth, isWeb);
  }

  Widget _feesStatusBody(
    BuildContext context,
    FeesStatusProvider provider,
    Color dropdownColor,
    double screenWidth,
    bool isWeb,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? screenWidth * 0.03 : 16,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) {
              final isMobile = MediaQuery.of(context).size.width < 600;
              final isSmallScreen = MediaQuery.of(context).size.width < 400;

              return Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        focusColor: Colors.transparent,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: appGreen,
                        ),
                        dropdownColor: dropdownColor,
                        value: provider.selectedRole,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : (isMobile ? 14 : 15),
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                        ),
                        items:
                            ['All', 'Teacher', 'Student']
                                .map(
                                  (role) => DropdownMenuItem(
                                    value: role,
                                    child: Text(
                                      role,
                                      style: TextStyle(
                                        fontSize:
                                            isSmallScreen
                                                ? 13
                                                : (isMobile ? 14 : 15),
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            provider.setRole(val);
                          }
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 20),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        focusColor: Colors.transparent,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: appGreen,
                        ),
                        dropdownColor: dropdownColor,
                        value: provider.selectedStatus,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : (isMobile ? 14 : 15),
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                        ),
                        items:
                            ['All', 'Paid', 'Unpaid']
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize:
                                            isSmallScreen
                                                ? 13
                                                : (isMobile ? 14 : 15),
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            provider.setStatus(val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextField(
                      cursorColor: appGreen,
                      controller: provider.searchController,
                      onChanged: (val) => provider.setSearchTerm(val),
                      decoration: InputDecoration(
                        hintText: 'Search by name or email',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.grey.shade400,
                            width: 0.5,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1.0,
                          ),
                        ),
                        suffixIcon:
                            provider.searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: appGreen,
                                  ),
                                  onPressed: () {
                                    provider.clearSearch();
                                  },
                                )
                                : null,
                      ),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : (isMobile ? 14 : 15),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Builder(
              builder: (context) {
                final isMobile = MediaQuery.of(context).size.width < 600;
                final isSmallScreen = MediaQuery.of(context).size.width < 400;

                return Row(
                  children: [
                    Expanded(
                      flex: isMobile ? 3 : 4,
                      child: Text(
                        'User Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : (isMobile ? 14 : 16),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: isMobile ? 3 : 3,
                      child: Text(
                        'Role',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : (isMobile ? 14 : 16),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: isMobile ? 3 : 3,
                      child: Text(
                        'Fee Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 12 : (isMobile ? 14 : 16),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: isMobile ? 3 : 3,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Month Picker
                          InkWell(
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: provider.selectedMonth,
                                firstDate: DateTime(now.year - 5, 1),
                                lastDate: DateTime(now.year + 1, 12),
                                initialDatePickerMode: DatePickerMode.year,
                                helpText: 'Select Month',
                                fieldLabelText: 'Month/Year',
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: appGreen,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                provider.setMonth(
                                  DateTime(picked.year, picked.month),
                                );
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isMobile) ...[
                                  const Icon(
                                    Icons.calendar_today,
                                    color: appGreen,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Flexible(
                                  child: Text(
                                    isSmallScreen
                                        ? DateFormat(
                                          'MMM yy',
                                        ).format(provider.selectedMonth)
                                        : (isMobile
                                            ? DateFormat(
                                              'MMM yy',
                                            ).format(provider.selectedMonth)
                                            : DateFormat(
                                              'MMMM yyyy',
                                            ).format(provider.selectedMonth)),
                                    style: TextStyle(
                                      fontSize:
                                          isSmallScreen
                                              ? 11
                                              : (isMobile ? 13 : 15),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isSmallScreen) const SizedBox(width: 20),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child:
                provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Card(
                      color: Theme.of(context).cardColor,
                      shadowColor: Theme.of(context).shadowColor,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.separated(
                        itemCount: provider.filteredUsers.length,
                        separatorBuilder:
                            (_, __) =>
                                Divider(height: 1, color: Colors.grey[300]),
                        itemBuilder: (context, index) {
                          final user = provider.filteredUsers[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            child: Builder(
                              builder: (context) {
                                final isMobile =
                                    MediaQuery.of(context).size.width < 600;
                                final isSmallScreen =
                                    MediaQuery.of(context).size.width < 400;

                                return Row(
                                  children: [
                                    Expanded(
                                      flex: isMobile ? 3 : 4,
                                      child: Text(
                                        user['name'] ?? '',
                                        style: TextStyle(
                                          fontSize:
                                              isSmallScreen
                                                  ? 12
                                                  : (isMobile ? 14 : 16),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: isMobile ? 3 : 3,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          user['role'] ?? '',
                                          style: TextStyle(
                                            color: provider.getRoleColor(
                                              user['role'] ?? '',
                                            ),
                                            fontWeight: FontWeight.bold,
                                            fontSize:
                                                isSmallScreen
                                                    ? 11
                                                    : (isMobile ? 13 : 15),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: isMobile ? 3 : 3,
                                      child:
                                          (provider.selectedMonth.month ==
                                                      DateTime.now().month &&
                                                  provider.selectedMonth.year ==
                                                      DateTime.now().year)
                                              ? GestureDetector(
                                                onTap: () async {
                                                  final newStatus = await showDialog<
                                                    String
                                                  >(
                                                    context: context,
                                                    builder: (context) {
                                                      bool isPaid =
                                                          user['feeStatus'] ==
                                                          'Paid';
                                                      return AlertDialog(
                                                        backgroundColor:
                                                            Theme.of(
                                                              context,
                                                            ).scaffoldBackgroundColor,
                                                        title: const Center(
                                                          child: Text(
                                                            'Change Fee Status',
                                                          ),
                                                        ),
                                                        content: StatefulBuilder(
                                                          builder: (
                                                            context,
                                                            setStateDialog,
                                                          ) {
                                                            return Row(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .center,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                const Text(
                                                                  'Unpaid',
                                                                ),
                                                                Switch(
                                                                  value: isPaid,
                                                                  onChanged: (
                                                                    value,
                                                                  ) {
                                                                    setStateDialog(
                                                                      () {
                                                                        isPaid =
                                                                            value;
                                                                      },
                                                                    );
                                                                  },
                                                                  activeThumbColor:
                                                                      Colors
                                                                          .green,
                                                                  inactiveThumbColor:
                                                                      Colors
                                                                          .red,
                                                                  inactiveTrackColor:
                                                                      Theme.of(
                                                                        context,
                                                                      ).scaffoldBackgroundColor,
                                                                  trackOutlineColor: WidgetStateProperty.resolveWith<
                                                                    Color?
                                                                  >((
                                                                    Set<
                                                                      WidgetState
                                                                    >
                                                                    states,
                                                                  ) {
                                                                    if (states.contains(
                                                                      WidgetState
                                                                          .selected,
                                                                    )) {
                                                                      return Colors
                                                                          .transparent;
                                                                    }
                                                                    return Colors
                                                                        .red;
                                                                  }),
                                                                ),
                                                                const Text(
                                                                  'Paid',
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        ),
                                                        actionsAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                    ),
                                                            child: Text(
                                                              'Cancel',
                                                              style: TextStyle(
                                                                color: appGreen,
                                                              ),
                                                            ),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                context,
                                                                isPaid
                                                                    ? 'Paid'
                                                                    : 'Unpaid',
                                                              );
                                                            },
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  appGreen,
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                            child: const Text(
                                                              'Save',
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                  if (newStatus != null &&
                                                      newStatus !=
                                                          user['feeStatus']) {
                                                    provider.updateFeeStatus(
                                                      user,
                                                      newStatus,
                                                    );
                                                  }
                                                },
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        Theme.of(
                                                          context,
                                                        ).scaffoldBackgroundColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    user['feeStatus'] == 'Paid'
                                                        ? 'Paid'
                                                        : 'Unpaid',
                                                    style: TextStyle(
                                                      color: provider
                                                          .getFeeStatusColor(
                                                            user['feeStatus'] ??
                                                                '',
                                                          ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          isSmallScreen
                                                              ? 11
                                                              : (isMobile
                                                                  ? 13
                                                                  : 15),
                                                    ),
                                                  ),
                                                ),
                                              )
                                              : Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).scaffoldBackgroundColor,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  user['feeStatus'] == 'Paid'
                                                      ? 'Paid'
                                                      : 'Unpaid',
                                                  style: TextStyle(
                                                    color: provider
                                                        .getFeeStatusColor(
                                                          user['feeStatus'] ??
                                                              '',
                                                        ),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize:
                                                        isSmallScreen
                                                            ? 11
                                                            : (isMobile
                                                                ? 13
                                                                : 15),
                                                  ),
                                                ),
                                              ),
                                    ),
                                    Expanded(
                                      flex: isMobile ? 3 : 3,
                                      child: Builder(
                                        builder: (context) {
                                          final ts = user['lastUpdated'];
                                          if (ts != null && ts is DateTime) {
                                            return Text(
                                              isSmallScreen
                                                  ? DateFormat(
                                                    'dd/MM/yy',
                                                  ).format(ts)
                                                  : (isMobile
                                                      ? DateFormat(
                                                        'dd/MM/yy',
                                                      ).format(ts)
                                                      : DateFormat(
                                                        'dd MMM yyyy, hh:mm a',
                                                      ).format(ts)),
                                              style: TextStyle(
                                                fontSize:
                                                    isSmallScreen
                                                        ? 11
                                                        : (isMobile ? 13 : 15),
                                              ),
                                            );
                                          }
                                          return Text(
                                            'N/A',
                                            style: TextStyle(
                                              fontSize:
                                                  isSmallScreen
                                                      ? 11
                                                      : (isMobile ? 13 : 15),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout(
    BuildContext context,
    FeesStatusProvider provider,
    Color dropdownColor,
    double screenWidth,
    bool isWeb,
  ) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminHomeView()),
        );
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
          title: Builder(
            builder: (context) {
              final isSmallScreen = MediaQuery.of(context).size.width < 400;
              return Text(
                'Fee Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 20 : 24,
                ),
              );
            },
          ),
        ),
        body: _feesStatusBody(
          context,
          provider,
          dropdownColor,
          screenWidth,
          isWeb,
        ),
      ),
    );
  }
}
