import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllUserScreen extends StatefulWidget {
  const AllUserScreen({Key? key}) : super(key: key);

  @override
  State<AllUserScreen> createState() => _AllUserScreenState();
}

class _AllUserScreenState extends State<AllUserScreen> {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  String _searchQuery = '';

  void _updateSearchQuery(String newQuery) {
    setState(() {
      _searchQuery = newQuery;
    });
  }

  Future<void> _deleteUser(String uid) async {
    try {
      await usersCollection.doc(uid).delete();
      print('User with UID $uid deleted successfully.');
    } catch (e) {
      print('Error deleting user: $e');
    }
  }

  Future<void> _showDeleteConfirmationDialog(String uid) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this user?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteUser(uid);
                Navigator.of(context).pop();
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditBalanceDialog(String uid, String currentBalance) async {
    TextEditingController balanceController =
        TextEditingController(text: currentBalance);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Balance'),
          content: TextField(
            controller: balanceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'New Balance'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String newBalance = balanceController.text.trim();
                await _updateUserBalance(uid, newBalance);
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _blockUser(String uid, bool currentDisabled) async {
    try {
      await usersCollection.doc(uid).update({'disabled': !currentDisabled});
      print(
          'User with UID $uid: Blocked status updated to ${!currentDisabled}');
    } catch (e) {
      print('Error updating user block status: $e');
    }
  }

  Future<void> _updateUserBalance(String uid, String newBalance) async {
    try {
      await usersCollection.doc(uid).update({'balance': newBalance});
      print('User with UID $uid: Balance updated to $newBalance');
    } catch (e) {
      print('Error updating user balance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text('All Users'),
        actions: [
          SizedBox(width: 60),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 10),
              child: TextField(
                onChanged: _updateSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Email/Phone/Name',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 10,
          ),
          Center(
            child: StreamBuilder<QuerySnapshot>(
              stream: usersCollection.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text('Total Users: Loading...');
                }
                var users = snapshot.data!.docs;
                return Text('Total Users: ${users.length}');
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersCollection.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }
          var users = snapshot.data!.docs;
          // Filter users based on search query
          var filteredUsers = users.where((user) {
            var userData = user.data() as Map<String, dynamic>;
            var fullName = '${userData['first_name']} ${userData['last_name']}';
            return userData['phone'].contains(_searchQuery) ||
                userData['email'].contains(_searchQuery) ||
                fullName.contains(_searchQuery);
          }).toList();
          return ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              var user = filteredUsers[index];
              var userData = user.data() as Map<String, dynamic>;
              var uid = user.id;
              var currentBalance = userData['balance'].toString();
              Color tileColor =
                  userData['disabled'] ?? false ? Colors.red : Colors.white;

              return Card(
                color: tileColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(
                        '${userData['first_name']} ${userData['last_name']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phone: ${userData['phone']}'),
                        Text("Balance: ${currentBalance}"),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.block),
                          onPressed: () {
                            bool isDisabled = userData['disabled'] ?? false;
                            _blockUser(uid, isDisabled);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            _showEditBalanceDialog(uid, currentBalance);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _showDeleteConfirmationDialog(uid);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
