import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatie/helper/my_date_util.dart';
import 'package:chatie/models/chat_user.dart';
import 'package:chatie/screens/view_profile_screen.dart';
import 'package:chatie/widgets/message_card.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/apis.dart';
import '../main.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // for storing all messages
  List<Message> _list = [];

  // for handling message text changes
  final _textController = TextEditingController();

  // for storing value of showing or hiding emoji
  // is uploading for checking image is uploading or not
  bool _showEmoji = false, _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: WillPopScope(
          onWillPop: () {
            if (_showEmoji) {
              setState(() {
                _showEmoji = !_showEmoji;
              });
              return Future.value(false);
            } else {
              return Future.value(true);
            }
          },
          child: Scaffold(
            backgroundColor: const Color.fromARGB(255, 234, 248, 255),
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: _appBar(),
            ),

            // body
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: APIs.getAllMessages(widget.user),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const SizedBox();
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;

                          _list = data!
                              .map((e) => Message.fromJson(e.data()))
                              .toList();

                          if (_list.isNotEmpty) {
                            return ListView.builder(
                              reverse: true,
                              itemCount: _list.length,
                              padding: EdgeInsets.only(
                                top: mq.height * .01,
                              ),
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                return MessageCard(
                                  message: _list[index],
                                );
                              },
                            );
                          } else {
                            return const Center(
                              child: Text(
                                'Say Hi ! 👋 ',
                                style: TextStyle(fontSize: 24),
                              ),
                            );
                          }
                      }
                    },
                  ),
                ),
                if (_isUploading)
                  const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )),
                _chatInput(),
                if (_showEmoji)
                  EmojiPicker(
                    textEditingController: _textController,
                    config: Config(
                      height: mq.height * .35,
                      bottomActionBarConfig: const BottomActionBarConfig(
                          showSearchViewButton: false),
                      checkPlatformCompatibility: true,
                      emojiViewConfig: EmojiViewConfig(
                        emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                        columns: 8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _appBar() {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ViewProfileScreen(
                      user: widget.user,
                    )));
      },
      child: StreamBuilder(
        stream: APIs.getUserInfo(widget.user),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              snapshot.connectionState == ConnectionState.none) {
            // Handle case where snapshot has not yet received data
            return const Center(
                child:
                    CircularProgressIndicator(
                    strokeWidth: 1,
                    color: Colors.black12,
                    strokeAlign: BorderSide.strokeAlignCenter,
                    )); // Or any other loading indicator
          }

          if (!snapshot.hasData) {
            // Handle case where snapshot has no data
            return const Text('No data available');
          }

          // Proceed with data processing
          final data = snapshot.data!.docs;
          final list = data.map((e) => ChatUser.fromJson(e.data())).toList();

          if (list.isEmpty) {
            // Handle case where list is empty
            return const Text('Empty list');
          }

          // Assuming list is not empty, proceed with UI rendering
          return Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_outlined,
                  color: Colors.black54,
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(mq.height * .03),
                child: CachedNetworkImage(
                  width: mq.height * .05,
                  height: mq.height * .05,
                  fit: BoxFit.cover,
                  imageUrl: list[0].image,
                  errorWidget: (context, url, error) =>
                      const CircleAvatar(child: Icon(CupertinoIcons.person)),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list[0].name,
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    list[0].isOnline
                        ? 'Online'
                        : MyDateUtil.getLastActiveTime(
                            context: context, lastActive: list[0].lastActive),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  )
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: mq.height * .01, horizontal: mq.height * .02),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        setState(() => _showEmoji = !_showEmoji);
                      },
                      icon: const Icon(
                        Icons.emoji_emotions_outlined,
                        color: Colors.blueAccent,
                        size: 26,
                      )),
                  Expanded(
                      child: TextField(
                    controller: _textController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    onTap: () {
                      if (_showEmoji) setState(() => _showEmoji = !_showEmoji);
                    },
                    decoration: const InputDecoration(
                        hintText: ' Type Something ..... ',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.blueAccent)),
                  )),

                  // pick image from gallery
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        // picking multiple  images
                        final List<XFile> images =
                            await picker.pickMultiImage(imageQuality: 70);
                        // uploading and sending one by one

                        for (var i in images) {
                          log('Image Path: ${i.path}');
                          setState(() => _isUploading = true);

                          await APIs.sendChatImage(widget.user, File(i.path));
                          setState(() => _isUploading = false);
                        }
                      },
                      icon: const Icon(
                        Icons.image,
                        color: Colors.blueAccent,
                        size: 26,
                      )),

                  // take image from camera
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        // pick an image
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 70);

                        if (image != null) {
                          log('Image Path: ${image.path}');
                          setState(() => _isUploading = true);
                          await APIs.sendChatImage(
                              widget.user, File(image.path));
                          setState(() => _isUploading = false);
                        }
                      },
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.blueAccent,
                        size: 26,
                      )),
                  SizedBox(
                    width: mq.width * .02,
                  )
                ],
              ),
            ),
          ),
          MaterialButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                APIs.sendMessage(widget.user, _textController.text, Type.text);
                _textController.text = '';
              }
            },
            shape: const CircleBorder(),
            minWidth: 0,
            padding:
                const EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 5),
            color: Colors.blueAccent,
            child: const Icon(
              Icons.send_rounded,
              color: Colors.white,
              size: 28,
            ),
          )
        ],
      ),
    );
  }
}
