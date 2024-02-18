import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:infinity_invest_admin/notification_provider.dart';

class WithdrawRequestModel {
  String name;
  double amount;
  String receiveAddress;
  String method;
  String uid;

  WithdrawRequestModel({
    required this.method,
    required this.name,
    required this.amount,
    required this.receiveAddress,
    required this.uid,
  });
}

class WithdrawRequestScreen extends StatefulWidget {
  const WithdrawRequestScreen({Key? key}) : super(key: key);

  @override
  State<WithdrawRequestScreen> createState() => _WithdrawRequestScreenState();
}

class _WithdrawRequestScreenState extends State<WithdrawRequestScreen> {
  final CollectionReference _adminCollection =
      FirebaseFirestore.instance.collection('admin');

  Future<List<WithdrawRequestModel>> _fetchWithdrawRequests() async {
    try {
      DocumentSnapshot withdrawDoc =
          await _adminCollection.doc('withdraw').get();

      List<dynamic> withdrawRequestsData = withdrawDoc['requests'];

      List<WithdrawRequestModel> withdrawRequests = withdrawRequestsData
          .map((data) => WithdrawRequestModel(
                method: data['method'],
                name: data['name'] ?? '',
                amount: double.parse(data['amount'] ?? '0.0'),
                receiveAddress: data['receiveAddress'] ?? '',
                uid: data['uid'] ?? '',
              ))
          .toList();

      return withdrawRequests;
    } catch (e) {
      throw Exception('Error fetching withdraw requests: $e');
    }
  }

  bool isLoading = false;
  Future<void> _approveRequest(WithdrawRequestModel request) async {
    // Get user document from 'users' collection
    DocumentReference userDocRef =
        FirebaseFirestore.instance.collection('users').doc(request.uid);

    try {
      setState(() {
        isLoading = true;
      });
      // Add the approved request to the 'withdraw_history' array
      await userDocRef.update({
        'withdraw_history': FieldValue.arrayUnion([
          {
            'name': request.name,
            'amount': request.amount,
            'receiveAddress': request.receiveAddress,
          }
        ]),
      });
      saveNewNotification(request.uid, 'Admin Approved your withdraw Request',
          'you get soon your withdral balance');
      // Remove the approved request from the 'requests' array
      await removeRequestToAdmin(request);
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Request approved successrfully"),
        ),
      );
      setState(() {});
      print('Request approved successfully!');
    } catch (e) {
      print('Error approving request: $e');
    }
  }

  Future<void> _declineRequest(WithdrawRequestModel request) async {
    try {
      setState(() {
        isLoading = true;
      });
      // Get user document from 'users' collection
      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection('users').doc(request.uid);

      // Add the declined amount to the user's old balance
      DocumentSnapshot userDoc = await userDocRef.get();
      double currentBalance = double.parse(userDoc['balance'] ?? '0.0');
      double requestAmount = request.amount;

      // Update user balance by adding the request amount
      double newBalance = currentBalance + requestAmount;
      await userDocRef.update({'balance': newBalance.toString()});
      // Remove the declined request from the 'requests' array
      await removeRequestToAdmin(request);
      saveNewNotification(request.uid, 'Admin decined your withdraw Request',
          'Sended withdral balance re added your balance');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Request declined successrfully"),
        ),
      );
      setState(() {});
      print('Request declined successfully!');
    } catch (e) {
      print('Error declining request: $e');
    }
  }

  removeRequestToAdmin(WithdrawRequestModel request) async {
    final adminDocRef =
        FirebaseFirestore.instance.collection('admin').doc('withdraw');

    final adminDataSnapshot = await adminDocRef.get();
    final adminDataMap = adminDataSnapshot.data();

    if (adminDataMap == null || !adminDataMap.containsKey('requests')) {
      print('Error: depositRequest data not found');
      return;
    }

    List<Map<String, dynamic>> depositRequests =
        (adminDataMap['requests'] as List).cast<Map<String, dynamic>>();
    // print(depositRequests);
    final targetIndex = depositRequests.indexWhere((item) =>
        item['uid'] == request.uid &&
        double.parse(item['amount']) == request.amount);

    // print("target index $targetIndex");

    if (targetIndex != -1) {
      depositRequests.removeAt(targetIndex);

      adminDataMap['requests'] = depositRequests;
      print("updated depositRequests $depositRequests");
      await adminDocRef.update(adminDataMap);
      print("teget index deleted sucessfully");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: isLoading ? CircularProgressIndicator() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      appBar: AppBar(
        title: Text('Withdraw Requests'),
      ),
      body: FutureBuilder(
        future: _fetchWithdrawRequests(),
        builder: (context, AsyncSnapshot<List<WithdrawRequestModel>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text('No withdraw requests found');
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                WithdrawRequestModel request = snapshot.data![index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: "${request.receiveAddress}"));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Number copied to clipboard"),
                            ),
                          );
                        },
                        child: ListTile(
                          title: Text('${request.name} - \$${request.amount}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Number: ${request.receiveAddress}'),
                              Text("Method: ${request.method}")
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.check),
                                onPressed: () => _approveRequest(request),
                              ),
                              IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () => _declineRequest(request),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
