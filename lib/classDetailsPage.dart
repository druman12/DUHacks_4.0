import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:classroom/UploadInfoPage.dart';
import 'package:classroom/ClassInfo.dart';
import 'pdf_viewer_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClassDetailsPage extends StatelessWidget {
  final String classId;
  final DocumentSnapshot classData;

  const ClassDetailsPage({
    Key? key,
    required this.classId,
    required this.classData, required currentUserId,
  }) : super(key: key);

  Future<File> _downloadPDF(String pdfUrl) async {
    final response = await http.get(Uri.parse(pdfUrl));
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${pdfUrl.split('/').last}');
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  Future<void> _assignGrade(BuildContext context, String infoId) async {
    final TextEditingController gradeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Grade'),
          content: TextField(
            controller: gradeController,
            decoration: InputDecoration(labelText: 'Enter Grade'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final grade = gradeController.text;
                if (grade.isNotEmpty) {
                  await _updateGrade(infoId, grade);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Grade assigned successfully')),
                  );
                }
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateGrade(String infoId, String grade) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('info')
          .doc(infoId)
          .update({'grade': grade});
    } catch (e) {
      print('Failed to update grade: $e');
    }
  }

  void _openPDF(BuildContext context, String pdfUrl) async {
    try {
      final file = await _downloadPDF(pdfUrl);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerPage(filePath: file.path),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open PDF: $e')),
      );
    }
  }

  Future<void> _deleteInfo(BuildContext context, String infoId) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('info')
          .doc(infoId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Information deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete information: $e')),
      );
    }
  }

  Future<void> _deleteClass(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('classes').doc(classId).delete();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete class: $e')),
      );
    }
  }

  Future<String> _getCurrentUserRole() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      return userDoc['role'] as String;
    } catch (e) {
      print('Error fetching user role: $e');
      return 'guest'; // Default or error role
    }
  }

  void _goToUploadInfoPage(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UploadInfoPage(classId: classId)),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Information uploaded successfully')),
      );
    }
  }

  void _goToClassInfoPage(BuildContext context, DocumentSnapshot infoData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassInfoPage(infoData: infoData, userId: classData['userId']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final classCreatorId = classData['userId'];
    return Scaffold(
      appBar: AppBar(
        title: Text(classData['className']),
        backgroundColor: Colors.blueGrey[600],
        actions: [
          if (currentUserId == classCreatorId) ...[
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _goToUploadInfoPage(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () => _deleteClass(context),
            ),
          ]
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Class Name: ${classData['className']}',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            Text(
              'Subject: ${classData['subject']}',
              style: const TextStyle(fontSize: 20, color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            Text(
              'Class Code: ${classData['classCode']}',
              style: const TextStyle(fontSize: 20, color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Uploaded Information:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .collection('info')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final infoDocs = snapshot.data!.docs;

                  if (infoDocs.isEmpty) {
                    return const Center(child: Text('No information uploaded yet.'));
                  }

                  return ListView.builder(
                    itemCount: infoDocs.length,
                    itemBuilder: (context, index) {
                      final info = infoDocs[index];
                      final Map<String, dynamic>? data = info.data() as Map<String, dynamic>?;

                      final pdfUrl = data != null && data.containsKey('pdfUrl') ? data['pdfUrl'] as String? : null;
                      final submittedPdf = data != null && data.containsKey('submittedPdf') ? data['submittedPdf'] as String? : null;
                      final infoId = info.id;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        color: Colors.blueGrey[50],
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: InkWell(
                          onTap: () => _goToClassInfoPage(context, info),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  info['title'],
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  info['description'],
                                  style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
                                ),
                                const SizedBox(height: 12),
                                if (pdfUrl != null && pdfUrl.isNotEmpty)
                                  ElevatedButton.icon(
                                    onPressed: () => _openPDF(context, pdfUrl),
                                    icon: const Icon(Icons.picture_as_pdf),
                                    label: const Text('Open PDF'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey[200],
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                  ),
                                if (submittedPdf != null && submittedPdf.isNotEmpty)
                                  ElevatedButton.icon(
                                    onPressed: () => _openPDF(context, submittedPdf),
                                    icon: const Icon(Icons.picture_as_pdf),
                                    label: const Text('View Submitted PDF'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey[200],
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                if (currentUserId == classCreatorId)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => _assignGrade(context, infoId),
                                        child: const Text('Assign Grade'),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteInfo(context, infoId),
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
