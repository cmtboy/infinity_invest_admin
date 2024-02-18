import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MiningOnOrOff extends StatefulWidget {
  const MiningOnOrOff({Key? key}) : super(key: key);

  @override
  _MiningOnOrOffState createState() => _MiningOnOrOffState();
}

class _MiningOnOrOffState extends State<MiningOnOrOff> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _miningOn = false;

  @override
  void initState() {
    super.initState();
    _fetchMiningStatus();
  }

  Future<void> _fetchMiningStatus() async {
    try {
      DocumentSnapshot miningSnapshot =
          await _firestore.collection('admin').doc('mining').get();
      setState(() {
        _miningOn = miningSnapshot['on'] ?? false;
      });
    } catch (e) {
      print('Error fetching mining status: $e');
    }
  }

  Future<void> _toggleMiningStatus() async {
    try {
      await _firestore
          .collection('admin')
          .doc('mining')
          .update({'on': !_miningOn});
      setState(() {
        _miningOn = !_miningOn;
      });
    } catch (e) {
      print('Error toggling mining status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mining On/Off'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mining Status: ${_miningOn ? 'On' : 'Off'}',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleMiningStatus,
              child: Text(_miningOn ? 'Turn Off Mining' : 'Turn On Mining'),
            ),
          ],
        ),
      ),
    );
  }
}
