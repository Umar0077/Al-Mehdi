import 'dart:async';

import 'package:al_mehdi_online_school/components/admin_sidebar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../constants/colors.dart';
import '../admin_home_view.dart';
import 'assign_students_view.dart';

class UserDetailsView extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isUnassigned;
  final VoidCallback? onAssign;
  final bool isFinalAssignment;

  const UserDetailsView({
    super.key,
    required this.user,
    this.isUnassigned = false,
    this.onAssign,
    this.isFinalAssignment = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTeacher = user['role'] == 'Teacher';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth >= 900;
        if (isWeb) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Row(
              children: [
                AdminSidebar(selectedIndex: 0),
                Expanded(
                  child: Column(
                    children: [
                      AppBar(
                        leading: BackButton(),
                        elevation: 0,
                        title: Text(
                          isTeacher ? 'Teacher Profile' : 'Student Profile',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                      ),
                      Expanded(child: _detailsContent(context, isWeb)),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              leading: BackButton(),
              elevation: 0,
              title: Text(
                isTeacher ? 'Teacher Profile' : 'Student Profile',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            body: _detailsContent(context, false),
          );
        }
      },
    );
  }

  Widget _detailsContent(BuildContext context, bool isWeb) {
    final isTeacher = user['role'] == 'Teacher';
    final String collection =
        isUnassigned
            ? (isTeacher ? 'unassigned_teachers' : 'unassigned_students')
            : (isTeacher ? 'teachers' : 'students');
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection(collection)
              .doc(user['uid'])
              .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading data.'));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('No data found.'));
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        final avatarUrl = user['avatar'] ?? '';
        final name = data['fullName'] ?? '';
        final email = data['email'] ?? '';
        final phone = data['phoneNumber'] ?? '';
        final country = data['country'] ?? '';
        final role = data['role'] ?? '';
        final degree = data['degree'] ?? '';
        final grade = data['grade'] ?? '';
        final favSubject = data['favouriteSubject'] ?? '';
        final assignedStudentId = data['assignedStudentId'];
        final hasAssignedStudents =
            assignedStudentId is List && assignedStudentId.isNotEmpty;
        final degreeProofUrl = data['degreeProofUrl'] ?? '';

        List<Widget> infoFields = [];
        void addField(String label, String? value) {
          if (value != null && value.isNotEmpty) {
            infoFields.add(_profileField(context, label, value));
            infoFields.add(const SizedBox(height: 14));
          }
        }

        addField('Full Name', name);
        addField('Email', email);
        addField('Phone Number', phone);
        addField('Country', country);
        if (isTeacher) {
          addField('Degree', degree);
          if (degreeProofUrl.isNotEmpty) {
            infoFields.add(
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => DegreePreviewScreen(imageUrl: degreeProofUrl),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Degree Proof',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: appGrey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          border: Border.all(color: appGrey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getFileIcon(degreeProofUrl),
                              color: appGreen,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'View Degree Proof',
                              style: TextStyle(fontSize: 14, color: appGreen),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        } else {
          addField('Grade', grade);
          addField('Favourite Subject', favSubject);
        }
        addField('Role', role);

        if (isWeb) {
          return Padding(
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
                              backgroundImage: NetworkImage(avatarUrl),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(role, style: const TextStyle(fontSize: 15)),
                            const SizedBox(height: 10),
                            if (isTeacher &&
                                isFinalAssignment &&
                                onAssign != null) ...[
                              ElevatedButton(
                                onPressed: () async {
                                  onAssign!();
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder:
                                        (context) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                  );
                                  await Future.delayed(
                                    const Duration(seconds: 1),
                                  );
                                  Navigator.of(context).pop();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdminHomeView(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Assign',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ] else if (isTeacher &&
                                !isFinalAssignment &&
                                !hasAssignedStudents) ...[
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AssignStudentsView(
                                            teacherUid: user['uid'],
                                          ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Assign To',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ] else if (!isTeacher && onAssign != null) ...[
                              ElevatedButton(
                                onPressed: () {
                                  onAssign!();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: appGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  isFinalAssignment ? 'Assign' : 'Assign To',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
                            children: infoFields,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Mobile layout
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundImage: NetworkImage(avatarUrl),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Card(
                    color: Theme.of(context).cardColor,
                    shadowColor: Theme.of(context).shadowColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...infoFields,
                          const SizedBox(height: 20),
                          if (isTeacher &&
                              isFinalAssignment &&
                              onAssign != null) ...[
                            ElevatedButton(
                              onPressed: () async {
                                onAssign!();
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder:
                                      (context) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                );
                                await Future.delayed(
                                  const Duration(seconds: 1),
                                );
                                Navigator.of(context).pop();
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminHomeView(),
                                  ),
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Assign',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ] else if (isTeacher &&
                              !isFinalAssignment &&
                              !hasAssignedStudents) ...[
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AssignStudentsView(
                                          teacherUid: user['uid'],
                                        ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Assign To',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ] else if (!isTeacher && onAssign != null) ...[
                            ElevatedButton(
                              onPressed: () {
                                onAssign!();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: appGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                isFinalAssignment ? 'Assign' : 'Assign To',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _profileField(BuildContext context, String label, String value) {
    return Column(
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
            color: Theme.of(context).cardColor,
            border: Border.all(color: appGrey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  IconData _getFileIcon(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('.pdf')) {
      return Icons.picture_as_pdf;
    } else if (lowerUrl.contains('.doc') || lowerUrl.contains('.docx')) {
      return Icons.description;
    } else if (lowerUrl.contains('.jpg') ||
        lowerUrl.contains('.jpeg') ||
        lowerUrl.contains('.png') ||
        lowerUrl.contains('.gif')) {
      return Icons.image;
    }
    return Icons.insert_drive_file;
  }
}

class DegreePreviewScreen extends StatefulWidget {
  final String imageUrl;

  const DegreePreviewScreen({super.key, required this.imageUrl});

  @override
  State<DegreePreviewScreen> createState() => _DegreePreviewScreenState();
}

class _DegreePreviewScreenState extends State<DegreePreviewScreen> {
  bool isDownloading = false;

  bool _isImageFile(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.jpg') ||
        lowerUrl.contains('.jpeg') ||
        lowerUrl.contains('.png') ||
        lowerUrl.contains('.gif') ||
        lowerUrl.contains('.webp') ||
        lowerUrl.contains('.bmp') ||
        lowerUrl.contains('.svg');
  }

  bool _isDocumentFile(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.pdf') ||
        lowerUrl.contains('.doc') ||
        lowerUrl.contains('.docx') ||
        lowerUrl.contains('.xls') ||
        lowerUrl.contains('.xlsx') ||
        lowerUrl.contains('.ppt') ||
        lowerUrl.contains('.pptx') ||
        lowerUrl.contains('.txt') ||
        lowerUrl.contains('.rtf');
  }

  String _getFileType(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('.pdf')) return 'PDF';
    if (lowerUrl.contains('.doc') || lowerUrl.contains('.docx')) return 'Word Document';
    if (lowerUrl.contains('.xls') || lowerUrl.contains('.xlsx')) return 'Excel Document';
    if (lowerUrl.contains('.ppt') || lowerUrl.contains('.pptx')) return 'PowerPoint';
    if (lowerUrl.contains('.txt')) return 'Text Document';
    return 'Document';
  }

  IconData _getFileIcon(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('.pdf')) return Icons.picture_as_pdf;
    if (lowerUrl.contains('.doc') || lowerUrl.contains('.docx')) return Icons.description;
    if (lowerUrl.contains('.xls') || lowerUrl.contains('.xlsx')) return Icons.table_chart;
    if (lowerUrl.contains('.ppt') || lowerUrl.contains('.pptx')) return Icons.slideshow;
    if (lowerUrl.contains('.txt')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('.pdf')) return Colors.red;
    if (lowerUrl.contains('.doc') || lowerUrl.contains('.docx')) return Colors.blue;
    if (lowerUrl.contains('.xls') || lowerUrl.contains('.xlsx')) return Colors.green;
    if (lowerUrl.contains('.ppt') || lowerUrl.contains('.pptx')) return Colors.orange;
    return Colors.grey;
  }

  Future<void> _downloadFile(String url) async {
    try {
      setState(() {
        isDownloading = true;
      });

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      setState(() {
        isDownloading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening file in external application...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isDownloading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openFile() async {
    if (_isDocumentFile(widget.imageUrl)) {
      // Open documents (PDF, Word, Excel, etc.) in webview viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentViewerScreen(
            documentUrl: widget.imageUrl,
            title: 'Degree Proof',
          ),
        ),
      );
    } else if (!_isImageFile(widget.imageUrl)) {
      // For non-document files, try to open in external application
      try {
        final uri = Uri.parse(widget.imageUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot open this file type'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening file: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.imageUrl));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = _isImageFile(widget.imageUrl);
    final isDocument = _isDocumentFile(widget.imageUrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Degree Proof'),
        actions: [
          if (!isImage)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download File',
              onPressed: isDownloading 
                  ? null 
                  : () => _downloadFile(widget.imageUrl),
            ),
        ],
      ),
      body: Center(
        child: isImage
            ? InteractiveViewer(
                child: Image.network(
                  widget.imageUrl,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text('Failed to load image'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Download File'),
                          onPressed: () => _downloadFile(widget.imageUrl),
                        ),
                      ],
                    );
                  },
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isDownloading) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text(
                        'Opening file...',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                    ] else ...[
                      Icon(
                        _getFileIcon(widget.imageUrl),
                        size: 120,
                        color: _getFileColor(widget.imageUrl),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _getFileType(widget.imageUrl),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Click below to view or download the file',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new, size: 28),
                        label: Text(
                          isDocument ? 'Open Document' : 'Open File',
                          style: const TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          backgroundColor: appGreen,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _openFile,
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Link'),
                        onPressed: _copyLink,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

// Document Viewer Screen using WebView - Supports PDF, Word, Excel, PowerPoint
class DocumentViewerScreen extends StatefulWidget {
  final String documentUrl;
  final String title;

  const DocumentViewerScreen({
    super.key,
    required this.documentUrl,
    this.title = 'Document Viewer',
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  late final WebViewController _controller;
  bool isLoading = true;
  String errorMessage = '';
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _startLoadingTimeout();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startLoadingTimeout() {
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (isLoading && mounted) {
        setState(() {
          errorMessage = 'Loading timeout. Please check your internet connection and try again.';
          isLoading = false;
        });
      }
    });
  }

  void _initializeWebView() {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  isLoading = true;
                  errorMessage = '';
                });
              }
            },
            onPageFinished: (String url) {
              _timeoutTimer?.cancel();
              if (mounted) {
                setState(() {
                  isLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              _timeoutTimer?.cancel();
              if (mounted) {
                setState(() {
                  errorMessage = 'Failed to load document. Please check your internet connection.';
                  isLoading = false;
                });
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              // Prevent navigation to external links for security
              if (request.url.contains('docs.google.com/viewer')) {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
          ),
        )
        ..loadRequest(
          Uri.parse(
            'https://docs.google.com/viewer?url=${Uri.encodeComponent(widget.documentUrl)}&embedded=true',
          ),
        );
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Failed to initialize viewer: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadFile() async {
    try {
      final uri = Uri.parse(widget.documentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening document in external application...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open this document type'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open document. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download Document',
            onPressed: _downloadFile,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (errorMessage.isEmpty)
            WebViewWidget(controller: _controller)
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load document',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () {
                      setState(() {
                        errorMessage = '';
                        _initializeWebView();
                      });
                    },
                  ),
                ],
              ),
            ),
          if (isLoading && errorMessage.isEmpty)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
