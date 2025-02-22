import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class UploadInfoPage extends StatefulWidget {
  final String classId;

  const UploadInfoPage({Key? key, required this.classId}) : super(key: key);

  @override
  _UploadInfoPageState createState() => _UploadInfoPageState();
}

class _UploadInfoPageState extends State<UploadInfoPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();
  PlatformFile? _selectedFile;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf','zip'],
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e')),
      );
    }
  }

  Future<void> _uploadInfo() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final dueDate = dueDateController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and description cannot be empty.')),
      );
      return;
    }

    try {
      String? pdfUrl;

      if (_selectedFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('class_pdfs/${_selectedFile!.name}');

        // Upload the file
        if (_selectedFile!.bytes != null) {
          await storageRef.putData(_selectedFile!.bytes!);
        } else if (_selectedFile!.path != null) {
          final file = File(_selectedFile!.path!);
          await storageRef.putFile(file);
        }

        pdfUrl = await storageRef.getDownloadURL();
      }

      // Prepare data to store in Firestore
      Map<String, dynamic> data = {
        'title': title,
        'description': description,
        'createdAt': Timestamp.now(),
        'pdfUrl': pdfUrl, // Save the URL of the uploaded PDF if available
      };


      // Store the info in Firestore
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('info')
          .add(data);

      // Pop the page and pass a success flag back
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload info: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Information'),
        backgroundColor: Colors.blueGrey[400],
      ),
      body: SingleChildScrollView(  // Wrap the Column in a scrollable view
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 5,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Attach PDF (optional)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadInfo,
              child: const Text('Upload Info'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[400],
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
