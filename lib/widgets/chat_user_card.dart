import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatie/helper/my_date_util.dart';
import 'package:chatie/models/chat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../api/apis.dart';
import '../models/message.dart';
import '../screens/chat_screen.dart';
import '../widgets/dialogs/profile_dialog.dart'; // Update the import path

class ChatUserCard extends StatefulWidget {
  final ChatUser user;
  final MediaQueryData mq; // Add mq as a parameter

  const ChatUserCard({super.key, required this.user, required this.mq});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  Message? _message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: widget.mq.size.width * .04, vertical: 4),
      color: Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                user: widget.user,
              ),
            ),
          );
        },
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: APIs.getLastMessage(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list = data?.map((e) => Message.fromJson(e.data())).toList() ?? [];

            if (list.isNotEmpty) {
              _message = list[0];
            } else {
              // If no message is exchanged yet, display a default message
              _message = Message(
                fromId: '',
                toId: '',
                msg: 'Start your conversation',
                sent: DateTime.now().toString(), // You can modify the timestamp as needed
                type: Type.text, read: '',
              );
            }

            return ListTile(
              leading: InkWell(
                onTap: (){
                  showDialog(context: context, builder: (_)=> ProfileDialog(user: widget.user,));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.mq.size.height * .03),
                  child: CachedNetworkImage(
                    width: widget.mq.size.height * .055,
                    height: widget.mq.size.height * .055,
                    fit: BoxFit.cover,
                    imageUrl: widget.user.image,
                    errorWidget: (context, url, error) => const CircleAvatar(child: Icon(CupertinoIcons.person)),
                  ),
                ),
              ),
              title: Text(widget.user.name),
              subtitle: Text(
                _message!.msg,
                maxLines: 1,
              ),
              trailing: Text(
                _message!.type == Type.image ? 'image' : MyDateUtil.getLastMessageTime(context: context, time: _message!.sent),
                style: const TextStyle(color: Colors.black54),
              ),
            );
          },
        ),
      ),
    );
  }
}
