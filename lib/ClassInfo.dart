import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'classDetailsPage.dart';

class ClassInfoPage extends StatefulWidget {
  final DocumentSnapshot infoData;
  final String userId;

  const ClassInfoPage({Key? key, required this.infoData, required this.userId}) : super(key: key);

  @override
  _ClassInfoPageState createState() => _ClassInfoPageState();
}

class _ClassInfoPageState extends State<ClassInfoPage> {
  PlatformFile? _selectedFile;
  String? _currentUserId;
  bool _isCreator = false;
  bool _hasUploadedPdf = false; // To track if the user has uploaded a PDF
  String? _uploadedPdfUrl; // Store the user's uploaded PDF URL

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserId();
    _checkUploadedPdf();
  }

  Future<void> _fetchCurrentUserId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        _currentUserId = currentUser.uid;
        _isCreator = widget.userId == _currentUserId;
      });
    }
  }

  Future<void> _checkUploadedPdf() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.infoData.reference.parent.parent!.id)
        .collection('info')
        .doc(widget.infoData.id)
        .get();

    final Map<String, dynamic>? data = userDoc.data();
    if (data != null && data.containsKey('submittedPdf')) {
      setState(() {
        _hasUploadedPdf = true;
        _uploadedPdfUrl = data['submittedPdf'];
      });
    }
  }

  Future<void> _openPDF(String pdfUrl) async {
    try {
      if (await canLaunch(pdfUrl)) {
        await launch(pdfUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open PDF')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open PDF: $e')),
      );
    }
  }

  Future<void> _submitPdf() async {
    if (_selectedFile == null) return;

    try {
      final file = File(_selectedFile!.path!);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('pdfs/${widget.infoData.id}/${_selectedFile!.name}');
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() => {});
      final pdfUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.infoData.reference.parent.parent!.id)
          .collection('info')
          .doc(widget.infoData.id)
          .update({'submittedPdf': pdfUrl});

      setState(() {
        _hasUploadedPdf = true;
        _uploadedPdfUrl = pdfUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit PDF: $e')),
      );
    }
  }

  Future<void> _deletePdf() async {
    try {
      final storageRef = FirebaseStorage.instance.refFromURL(_uploadedPdfUrl!);
      await storageRef.delete();

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.infoData.reference.parent.parent!.id)
          .collection('info')
          .doc(widget.infoData.id)
          .update({'submittedPdf': FieldValue.delete()});

      setState(() {
        _hasUploadedPdf = false;
        _uploadedPdfUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete PDF: $e')),
      );
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final infoData = widget.infoData.data() as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Class Info Details'),
        backgroundColor: Colors.blueGrey[400],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              infoData?['title'] ?? 'No Title',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
            ),
            const SizedBox(height: 16),
            Text(
              infoData?['description'] ?? 'No Description',
              style: TextStyle(fontSize: 18, color: Colors.blueGrey[600]),
            ),
            const SizedBox(height: 16),
            if (_uploadedPdfUrl != null)
              ElevatedButton(
                onPressed: () => _openPDF(_uploadedPdfUrl!),
                child: const Text('Open Submitted PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              ),
            if (!_isCreator && !_hasUploadedPdf) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickFile,
                child: const Text('Pick PDF File'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitPdf,
                child: const Text('Submit PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              ),
            ] else if (!_isCreator && _hasUploadedPdf) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _deletePdf,
                child: const Text('Delete Submitted PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
