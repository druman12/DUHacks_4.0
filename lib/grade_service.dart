// lib/grades_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> assignGrade(String userId, String classId, String grade) async {
  try {
    CollectionReference gradesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('grades');

    await gradesRef.doc(classId).set({
      'grade': grade,
      'timestamp': FieldValue.serverTimestamp(),
    });

    print('Grade assigned successfully');
  } catch (e) {
    print('Failed to assign grade: $e');
  }
}
