import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'UploadInfoPage.dart'; // Make sure this import matches your file structure

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

  // Navigation to Upload Info Page
  void _goToUploadInfoPage(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadInfoPage(classId: widget.classId),
      ),
    );

    if (result == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Information uploaded successfully')),
        );
      }
    }
  }

  // Delete Class Function
  Future<void> _deleteClass(BuildContext context) async {
    // Show confirmation dialog before deleting
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class'),
        content: const Text('Are you sure you want to delete this class? This action cannot be undone.'),
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
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .delete();

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

  // Remove Member Function
  Future<void> _removeMember(String memberId) async {
    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .update({
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

  // Show Remove Member Confirmation Dialog
  Future<void> _showRemoveConfirmation(BuildContext context, String userId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove $username from the class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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

  // Build Members List Widget
  Widget _buildMembersList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        final classData = snapshot.data!.data() as Map<String, dynamic>;
        final String classCreatorId = classData['userId'];

        // Changed from 'members' to 'joinedUser'
        final List<String> joinedUsers = List<String>.from(classData['joinedUser'] ?? []);

        if (widget.currentUserId != classCreatorId) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Members list is only visible to the class creator.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blueGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }

        if (joinedUsers.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No members in this class.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blueGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: joinedUsers)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.hasError) {
              return Center(
                child: Text('Error loading members: ${userSnapshot.error}'),
              );
            }

            if (!userSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final users = userSnapshot.data!.docs;

            return Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Class Members',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      Text(
                        '${users.length} members',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final userData = users[index].data() as Map<String, dynamic>;
                      final userId = users[index].id;
                      // Make sure to use the correct field name for username in your users collection
                      final username = userData['username'] ?? 'Unknown User';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey[200],
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          username,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: widget.classData['userId'] == widget.currentUserId
                            ? IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _showRemoveConfirmation(
                            context,
                            userId,
                            username,
                          ),
                        )
                            : null,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Build Main UI
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
              // Class Details Section
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
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blueGrey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Class Code: ${classData['classCode']}',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blueGrey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Members Section
              // ElevatedButton.icon(
              //   onPressed: () {
              //     setState(() {
              //       _showMembers = !_showMembers;
              //     });
              //   },
              //   icon: Icon(_showMembers ? Icons.visibility_off : Icons.visibility),
              //   label: Text(_showMembers ? 'Hide Members' : 'Show Members'),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.blueGrey[300],
              //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              //     shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //   ),
              // ),
              if (widget.currentUserId == widget.classData['userId'])
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showMembers = !_showMembers;
                    });
                  },
                  icon: Icon(_showMembers ? Icons.visibility_off : Icons.visibility),
                  label: Text(_showMembers ? 'Hide Members' : 'Show Members'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[300],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

              if (_showMembers) _buildMembersList(),

              const SizedBox(height: 24),

              // Uploaded Information Section
              const Text(
                'Uploaded Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 16),

              // Information List
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(widget.classId)
                    .collection('info')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final infoDocs = snapshot.data!.docs;

                  if (infoDocs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No information uploaded yet.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blueGrey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: infoDocs.length,
                    itemBuilder: (context, index) {
                      final info = infoDocs[index];
                      final data = info.data() as Map<String, dynamic>;

                      // Add your information display widget here
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(data['title'] ?? 'No Title'),
                          subtitle: Text(data['description'] ?? 'No Description'),
                          // Add more fields as needed
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
