import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatie/helper/my_date_util.dart';
import 'package:chatie/models/chat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../api/apis.dart';
import '../main.dart';
import '../models/message.dart';
import '../screens/chat_screen.dart';
import 'dialogs/profile_dialog.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;

  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  // Last Message
  Message? _message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: mq.width * .04, vertical: 4),
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
            }

            return ListTile(
              //  user profile pic
              leading: InkWell(
                onTap: (){
                  showDialog(context: context, builder: (_)=> ProfileDialog(user: widget.user,));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height * .03),
                  child: CachedNetworkImage(
                    width: mq.height * .055,
                    height: mq.height * .055,
                    fit: BoxFit.cover,
                    imageUrl: widget.user.image,
                    errorWidget: (context, url, error) => const CircleAvatar(child: Icon(CupertinoIcons.person)),
                  ),
                ),
              ),

              // User name
              title: Text(widget.user.name),

              // Last Message
              subtitle: Text(
                _message != null ? (_message!.type == Type.image ? 'image' : _message!.msg) : widget.user.about,
                maxLines: 1,
              ),

              // Last Message Time
              trailing: _message == null
                  ? null
                  : (_message!.read.isEmpty && _message!.fromId != APIs.user.uid)
                  ? Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade400,
                  borderRadius: BorderRadius.circular(10),
                ),
              )
                  : Text(
                MyDateUtil.getLastMessageTime(context: context, time: _message!.sent),
                style: const TextStyle(color: Colors.black54),
              ),
            );
          },
        ),
      ),
    );
  }
}