// import 'package:cloud_firestore/cloud_firestore.dart';

// import 'package:flutter/foundation.dart';
// import 'package:momo_admin/notification_model.dart';

// class NotificationProvider with ChangeNotifier {
//   List<UserNotification> _notifications = [];

//   List<UserNotification> get notifications => _notifications;

//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   String get unreadNotificationCount {
//     final unreadNotifications =
//         _notifications.where((notification) => !notification.seen).toList();
//     // print(unreadNotifications);
//     return unreadNotifications.length.toString();
//   }

//   Future<List<UserNotification>> fetchNotifications(
//       String userUID, int loadCount) async {
//     try {
//       final userDocRef = _firestore.collection('users').doc(userUID);
//       final notificationsCollectionRef = userDocRef.collection('notifications');
//       final querySnapshot = await notificationsCollectionRef
//           .orderBy('timestamp',
//               descending: true) // Change 'timestamp' to the actual field name
//           .limit(loadCount)
//           .get();

//       final loadedNotifications = querySnapshot.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return UserNotification(
//           id: doc.id,
//           title: data['title'],
//           subtitle: data['subtitle'],
//           timestamp:
//               data['timestamp'] != null ? data['timestamp'].toDate() : null,
//           seen: data['seen'],
//         );
//       }).toList();
//       _notifications = loadedNotifications;
//       return loadedNotifications;
//     } catch (e) {
//       print("Error fetching notifications: $e");
//       throw e;
//     }
//   }

//   Future<void> markNotificationAsSeen(
//       String userUID, String notificationID) async {
//     final unreadNotifications =
//         _notifications.where((notification) => !notification.seen).toList();
//     print(unreadNotifications.length.toString());
//     try {
//       final userDocRef = _firestore.collection('users').doc(userUID);
//       final notificationDocRef =
//           userDocRef.collection('notifications').doc(notificationID);

//       await notificationDocRef.update({'seen': true});

//       // Update the notification in the local list
//       final notificationIndex = _notifications
//           .indexWhere((notification) => notification.id == notificationID);
//       if (notificationIndex != -1) {
//         _notifications[notificationIndex].seen = true;
//         notifyListeners();
//       }
//     } catch (e) {
//       print("Error marking notification as seen: $e");
//       throw e;
//     }
//   }



//   void notifyListeners() {
//     super.notifyListeners();
//   }
// }
  import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Future<void> saveNewNotification(
      String userUID, String title, String subtitle) async {
    try {
      final userDocRef = _firestore.collection('users').doc(userUID);
      final notificationsCollectionRef = userDocRef.collection('notifications');

      final newNotificationRef =
          notificationsCollectionRef.doc(); // Generate a unique document ID
      final timestamp = FieldValue.serverTimestamp(); // Server timestamp

      await newNotificationRef.set({
        'title': title,
        'subtitle': subtitle,
        'timestamp': timestamp,
        'seen': false,
      });
     
    } catch (e) {
      print("Error saving notification: $e");
      throw e;
    }
  }