import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'createClass.dart';
import 'joinClassroomPage.dart';
import 'signin.dart';
import 'classDetailsPage.dart';

class UserClassesPage extends StatefulWidget {
  const UserClassesPage({super.key});

  @override
  _UserClassesPageState createState() => _UserClassesPageState();
}

class _UserClassesPageState extends State<UserClassesPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController; // Controller for tabs

  final List<Color> cardColors = [
    Colors.purple.shade100,
    Colors.lime.shade200,
    Colors.blueGrey.shade300,
    Colors.cyan.shade100,
    Colors.yellow.shade200,
    Colors.lightGreen.shade300,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _navigateToCreateClassPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClassCreationPage()),
    );
  }

  void _navigateToJoinClassPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JoinClassroomPage()),
    );
  }

  void _logout() async {
    await _auth.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInPage()),
          (route) => false,
    );
  }

  Widget _buildClassList(Stream<QuerySnapshot> classStream) {
    return StreamBuilder<QuerySnapshot>(
      stream: classStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No classes found.'));
        }

        final classes = snapshot.data!.docs;

        return ListView.builder(
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final classData = classes[index];
            final data = classData.data() as Map<String, dynamic>;
            final currentUserId = data.containsKey('userId') ? data['userId'] : null;
            final assignedColor = cardColors[index % cardColors.length];

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClassDetailsPage(
                      classId: classData.id,
                      classData: classData,
                      currentUserId: currentUserId,
                    ),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: assignedColor,
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classData['className'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Subject: ${classData['subject']}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Class Code: ${classData['classCode']}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Created at: ${classData['createdAt'] != null ? (classData['createdAt'] as Timestamp).toDate().toString() : 'N/A'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes'),
        backgroundColor: Colors.blueGrey[500],
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToJoinClassPage,
            tooltip: 'Join Classroom',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade300,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Created Classes"),
            Tab(text: "Joined Classes"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildClassList(
            _firestore
                .collection('classes')
                .where('userId', isEqualTo: _auth.currentUser!.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
          ),
          _buildClassList(
            _firestore
                .collection('classes')
                .where('joinedUser', arrayContains: _auth.currentUser!.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateClassPage,
        backgroundColor: Colors.green.shade500,
        elevation: 8,
        child: const Icon(Icons.create),
      ),
    );
  }
}