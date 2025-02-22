import 'package:flutter/material.dart';
import 'dart:math'; // For random class code generation
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'classPage.dart';

class ClassCreationPage extends StatefulWidget {
  const ClassCreationPage({super.key});

  @override
  _ClassCreationPageState createState() => _ClassCreationPageState();
}

class _ClassCreationPageState extends State<ClassCreationPage> {
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();

  String _generateClassCode() {
    final random = Random();
    return 'CLASS${random.nextInt(10000).toString().padLeft(4, '0')}'; // Example format: CLASS1234
  }

  void _createClass() async {
    final String className = _classNameController.text.trim();
    final String subject = _subjectController.text.trim();
    final String classCode = _generateClassCode();

    if (className.isEmpty || subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('classes').add({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'className': className,
        'subject': subject,
        'classCode': classCode,
        'createdAt': FieldValue.serverTimestamp(),
        'joinedUser': [],
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class created successfully')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserClassesPage()),
      );
    } catch (e) {
      print('Error creating class: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create class: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Class'),
        backgroundColor: Colors.blueGrey[700], // Unified color scheme
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            elevation: 5,
            shadowColor: Colors.blueGrey[300],
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _classNameController,
                    decoration: InputDecoration(
                      labelText: 'Class Name',
                      labelStyle: TextStyle(color: Colors.blueGrey[700]),
                      filled: true,
                      fillColor: Colors.blueGrey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blueGrey, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      labelStyle: TextStyle(color: Colors.blueGrey[700]),
                      filled: true,
                      fillColor: Colors.blueGrey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blueGrey, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _createClass,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[200],
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Create Class'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
