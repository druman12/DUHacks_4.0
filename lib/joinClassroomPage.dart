import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinClassroomPage extends StatefulWidget {
  const JoinClassroomPage({super.key});

  @override
  _JoinClassroomPageState createState() => _JoinClassroomPageState();
}

class _JoinClassroomPageState extends State<JoinClassroomPage> {
  final TextEditingController _classCodeController = TextEditingController();

  void _joinClass() async {
    final String classCode = _classCodeController.text.trim();
    final String userId = FirebaseAuth.instance.currentUser!.uid;

    if (classCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a class code')),
      );
      return;
    }

    try {
      final classQuery = await FirebaseFirestore.instance
          .collection('classes')
          .where('classCode', isEqualTo: classCode)
          .limit(1)
          .get();

      if (classQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class not found')),
        );
        return;
      }

      final classDoc = classQuery.docs.first;
      final classRef = classDoc.reference;

      if (classDoc['userId'] == userId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot join your own class')),
        );
        return;
      }

      await classRef.update({
        'joinedUser': FieldValue.arrayUnion([userId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined the class successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error joining class: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join class: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Classroom'),
        backgroundColor: Colors.blueGrey[500],
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        color: Colors.grey[100], // Simple background color
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Enter Class Code',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _classCodeController,
                      decoration: InputDecoration(
                        labelText: 'Class Code',
                        labelStyle: const TextStyle(color: Colors.deepPurple),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.deepPurpleAccent,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: _joinClass,
                      icon: const Icon(Icons.class_),
                      label: const Text('Join Class'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15.0,
                          horizontal: 20.0,
                        ),
                        textStyle: const TextStyle(fontSize: 20),
                        backgroundColor: Colors.blueGrey[200],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
