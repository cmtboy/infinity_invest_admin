import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TotalDeposit extends StatefulWidget {
  const TotalDeposit({Key? key}) : super(key: key);

  @override
  State<TotalDeposit> createState() => _TotalDepositState();
}

class _TotalDepositState extends State<TotalDeposit> {
  double _totalDeposit = 0;

  @override
  void initState() {
    super.initState();
    _calculateTotalDeposit();
  }

  Future<void> _calculateTotalDeposit() async {
    double total = 0;

    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      querySnapshot.docs.forEach((userDoc) {
        List<dynamic> depositHistory = userDoc['deposit_history'] ?? [];
        depositHistory.forEach((history) {
          total += history['amount'] ?? 0;
        });
      });

      setState(() {
        _totalDeposit = total;
      });
    } catch (e) {
      print('Error calculating total deposit: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Total Deposit'),
      ),
      body: Center(
        child: Text(
          'Total Deposit: $_totalDeposit Taka',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
