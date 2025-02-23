import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> startClass(String classId) async {
    String meetingId = classId + DateTime.now().millisecondsSinceEpoch.toString();

    await _firestore.collection('classes').doc(classId).update({
      'liveSession': {
        'isLive': true,
        'meetingId': meetingId,
        'hostId': _auth.currentUser!.uid,
        'startedAt': FieldValue.serverTimestamp(),
      }
    });

    return meetingId;
  }

  Future<void> endClass(String classId) async {
    await _firestore.collection('classes').doc(classId).update({
      'liveSession': {
        'isLive': false,
      }
    });
  }
}