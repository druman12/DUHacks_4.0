import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinClassroomPage extends StatefulWidget {
  @override
  _JoinClassroomPageState createState() => _JoinClassroomPageState();
}

class _JoinClassroomPageState extends State<JoinClassroomPage> {
  final TextEditingController _classCodeController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _joinClassroom() async {
    String classCode = _classCodeController.text.trim();
    String userId = _auth.currentUser?.uid ?? "";

    if (classCode.isEmpty || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid class code")),
      );
      return;
    }

    try {
      QuerySnapshot classQuery = await FirebaseFirestore.instance
          .collection("classes")
          .where("classCode", isEqualTo: classCode)
          .limit(1)
          .get();

      if (classQuery.docs.isNotEmpty) {
        DocumentSnapshot classSnapshot = classQuery.docs.first;
        String classId = classSnapshot.id; // Get the actual document ID
        List<dynamic> joinedUsers = classSnapshot["joinedUser"] ?? [];

        if (joinedUsers.contains(userId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You have already joined this class")),
          );
          return;
        }

        // Add user to class
        await FirebaseFirestore.instance.collection("classes").doc(classId).update({
          "joinedUser": FieldValue.arrayUnion([userId]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Successfully joined the classroom!")),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Classroom not found. Please check the code.")),
        );
      }
    } catch (e) {
      print("Error joining class: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error joining class: $e")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Join Classroom")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _classCodeController,
              decoration: const InputDecoration(
                labelText: "Enter Class Code",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _joinClassroom,
              child: const Text("Join Class"),
            ),
          ],
        ),
      ),
    );
  }
}