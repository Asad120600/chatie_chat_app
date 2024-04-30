import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:chatie/models/chat_user.dart';
import 'package:chatie/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';

class APIs {
  // for auth
  static FirebaseAuth auth = FirebaseAuth.instance;

  // for accessing Cloud Firestore

  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  // for accessing Firebase storage
  static FirebaseStorage storage = FirebaseStorage.instance;
  // for getting user

  static User get user => auth.currentUser!;

  // for checking if user exists or not

  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  // for storing self info
  static late ChatUser me;

  // for creating a new user

  static Future<void> createUser() async {
    final time = DateTime.now().microsecondsSinceEpoch.toString();
    final chatUser = ChatUser(
      id: user.uid,
      name: user.displayName.toString(),
      email: user.email.toString(),
      about: "Hey I'm Using ChatApp!",
      image: user.photoURL.toString(),
      createdAt: time,
      isOnline: false,
      lastActive: time,
      pushToken: '',
    );
    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  // for getting all users
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers() {
    return firestore
        .collection('users')
        .where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  // for getting specific user info

  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
      ChatUser chatUser) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  // update active status
  static Future<void> updateActiveStatus(bool isOnline) async {
    return firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken
    });
  }

// for updating user info
  static Future<void> updateUserInfo() async {
    await firestore.collection('users').doc(user.uid).update({
      'name': me.name,
      'about': me.about,
    });
  }

  // update profile picture
  static Future<void> updateProfilePicture(File file) async {
    // get image file extension
    final ext = file.path.split('.').last;
    log('Extension:$ext');
    // storage file ref with path

    final ref = storage.ref().child('profile_pictures/${user.uid}.$ext');
    // uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });

    // updating image in the firestore database
    me.image = await ref.getDownloadURL();
    await firestore.collection('users').doc(user.uid).update({
      'image': me.image,
    });
  }

  // for accessing firebase messaging
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  // for getting firebase messaging token
  static Future<void> getFirebaseMessagingToken() async {
    await fMessaging.requestPermission();

    fMessaging.getToken().then((t) => {
          if (t != null) {me.pushToken = t, log('Push Token: $t')}
        });
  }

  // for checking if user exists or not

  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
        await getFirebaseMessagingToken();
        // for setting user setting to active
        APIs.updateActiveStatus(true);
        log('My Data : ${user.data()}');
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  // for sending push notification

  static Future<void> sendPushNotification(
      ChatUser chatUser, String msg) async {
    try {
      final body = {
        "to": chatUser.pushToken,
        "notification": {
          "title": me.name,
          "body": msg,
          'android_channel_id': "chats"
        },
        "data": {
          "some_data": "User ID:${me.id}",
        },
      };
      var res = await post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader:
                'key=AAAAAAr0TPw:APA91bFKfRKrcQJpiRKlPmD_pSx2TNlnd7i6q44Xdhdg-_uwdmLFCj8F1zazt7eqIWqg_75miCHiEzWKJTc4y5l32NvolrNPpU2-TyX9tp-1yUu4cGmJmOl34ge7CuYM4kCJ68VT-TGU'
          },
          body: jsonEncode(body));
      log('Response status: ${res.statusCode}');
      log('Response body: ${res.body}');
    } catch (e) {
      log('\nsendPushNotificationE:$e');
    }
  }

  ///*************chat Screen related APIs**********

// for getting all the messages from specific conversation

  static String getConversationID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser user) {
    return FirebaseFirestore.instance
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .snapshots();
  }

  // for sending message

  static Future<void> sendMessage(
      ChatUser chatUser, String msg, Type type) async {
    // message sending time used as id
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    // message to snd
    final Message message = Message(
        toId: chatUser.id,
        msg: msg,
        read: '',
        type: type,
        sent: time,
        fromId: user.uid);
    final ref = firestore
        .collection('chats/${getConversationID(chatUser.id)}/messages/');
    await ref.doc(time).set(message.toJson()).then((value) =>
        sendPushNotification(chatUser, type == Type.text ? msg : 'image'));
  }

  // update read status of message
  static Future<void> updateMessageReadStatus(Message message) async {
    firestore
        .collection('chats/${getConversationID(message.fromId)}/messages/')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  // get last message of specific chat
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
      ChatUser user) {
    return FirebaseFirestore.instance
        .collection('chats/${getConversationID(user.id)}/messages/')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  // send chat Image
  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    // get image file extension
    final ext = file.path.split('.').last;
    // storage file ref with path

    final ref = storage.ref().child(
        'images/${getConversationID(chatUser.id)}/${DateTime.now().millisecond}.$ext');
    // uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });

    // updating image in the firestore database
    final imageUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imageUrl, Type.image);
  }

  //delete message
  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConversationID(message.toId)}/messages/')
        .doc(message.sent)
        .delete();

    if (message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }





  //update message
  static Future<void> updateMessage(Message message, String updatedMsg) async {
    await firestore
        .collection('chats/${getConversationID(message.toId)}/messages/')
        .doc(message.sent)
        .update({'msg': updatedMsg});
  }
}
