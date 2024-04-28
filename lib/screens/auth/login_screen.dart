
import 'dart:developer';
import 'dart:io';

import 'package:chatie/helper/dialogs.dart';
import 'package:chatie/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_button/sign_in_button.dart';

import '../../api/apis.dart';
import '../../main.dart';

// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAnimate = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isAnimate = true;
      });
    });
  }

  _handleGoogleBtnClick() {
    // for showing progress bar

    Dialogs.showProgressBar(context);

    _signInWithGoogle().then((user) async {
      // for hiding progress bar

      Navigator.pop(context);
      if(user !=null){
        log('\nuser: ${user.user}.toString()');
        log('\nuserAdditionalInfo: ${user.additionalUserInfo}.toString()');
        if((await APIs.userExists())){
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const HomeScreen(),
              ));

        }else{
          await APIs.createUser().then((value) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(),
                ));

          });
          }
        }
    });
  }
  Future<UserCredential?> _signInWithGoogle() async {
    try {
      await InternetAddress.lookup('google.com');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
      await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return await APIs.auth.signInWithCredential(credential);
    } catch (e) {
      log("\n_signInWithGoogle: $e.toString()");
      Dialogs.showSnackbar(context, 'Something Went Wrong Check Internet Please!');
    }
    return null;
  }

  // sign out function

  // _signOut()async{
  //   await FirebaseAuth.instance.signOut();
  //   await GoogleSignIn().signOut();
  // }

  @override
  Widget build(BuildContext context) {
    // initilizing media query for getting device size
    mq = MediaQuery.of(context).size;
    return Scaffold(
      // App Bar
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Welcome To My Chat App"),
      ),
      body: Stack(
        children: [
          // App logo
          AnimatedPositioned(
              top: mq.height * .15,
              right: _isAnimate ? mq.width * .25 : -mq.width * .5,
              width: mq.width * .5,
              duration: const Duration(seconds: 1),
              child: Image.asset("assets/icon.png")),
          Positioned(
              bottom: mq.height * .25,
              left: mq.width * .2,
              width: mq.width * .7,
              child: SignInButton(
                Buttons.google,
                text: "Log in with Google",
                onPressed: () {
                  _handleGoogleBtnClick();
                },
              )),
        ],
      ),
    );
  }
}