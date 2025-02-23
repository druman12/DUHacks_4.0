import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'UploadInfoPage.dart';

class ClassDetailsPage extends StatefulWidget {
  final String classId;
  final DocumentSnapshot classData;
  final String currentUserId;

  const ClassDetailsPage({
    Key? key,
    required this.classId,
    required this.classData,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<ClassDetailsPage> createState() => _ClassDetailsPageState();
}

class _ClassDetailsPageState extends State<ClassDetailsPage> {
  bool _showMembers = false;

  void _goToUploadInfoPage(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadInfoPage(classId: widget.classId),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Information uploaded successfully')),
      );
    }
  }

  Future<void> _deleteClass(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: const Text('Are you sure you want to delete this class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('classes').doc(widget.classId).delete();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete class: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(String memberId) async {
    try {
      await FirebaseFirestore.instance.collection('classes').doc(widget.classId).update({
        'joinedUser': FieldValue.arrayRemove([memberId])
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove member: $e')),
        );
      }
    }
  }

  Future<void> _showRemoveConfirmation(BuildContext context, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text('Are you sure you want to remove this user from the class?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _removeMember(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classCreatorId = widget.classData['userId'];
    final classData = widget.classData.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(classData['className']),
        backgroundColor: Colors.blueGrey[600],
        actions: [
          if (widget.currentUserId == classCreatorId) ...[
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Upload Information',
              onPressed: () => _goToUploadInfoPage(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Delete Class',
              onPressed: () => _deleteClass(context),
            ),
          ]
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Name: ${classData['className']}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Subject: ${classData['subject']}',
                        style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Class Code: ${classData['classCode']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.currentUserId == classCreatorId) ...[
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showMembers = !_showMembers;
                    });
                  },
                  child: Text(_showMembers ? 'Hide Members' : 'Show Members'),
                ),
                if (_showMembers) _buildMembersList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').doc(widget.classId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final classData = snapshot.data!.data() as Map<String, dynamic>;
        final List<String> joinedUsers = List<String>.from(classData['joinedUser'] ?? []);

        return FutureBuilder<List<Map<String, String>>>(
          future: _fetchUsernames(joinedUsers),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = userSnapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  title: Text(user['username'] ?? 'Unknown User'),
                  subtitle: Text(user['email'] ?? ''),
                  trailing: widget.currentUserId == classData['userId']
                      ? IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _showRemoveConfirmation(context, user['id']!),
                  )
                      : null,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, String>>> _fetchUsernames(List<String> userIds) async {
    List<Map<String, String>> users = [];
    for (String userId in userIds) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        users.add({
          'id': userId,
          'username': userDoc['username'] ?? 'Unknown',
          'email': userDoc['email'] ?? '',
        });
      }
    }
    return users;
  }
}