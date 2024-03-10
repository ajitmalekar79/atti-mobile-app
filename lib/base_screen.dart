import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';
import 'dashboard/screens/home_screen.dart';

class BaseScreen extends StatefulWidget {
  static const String routeName = '/';
  static const String baseRouteName = '/baseScreen';
  static const String homeRouteName = '/home';

  const BaseScreen({super.key});

  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  bool isSuccess = false;
  bool _isLoading = true;
  final PostAuthTocken _postAuthTocken = Get.find<PostAuthTocken>();

  @override
  void initState() {
    super.initState();
    _getIdToken();
  }

  Future<String?> _getIdToken() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        IdTokenResult idTokenResult = await user.getIdTokenResult();
        isSuccess = await _postAuthTocken
            .postAuthTocken(idTokenResult.token.toString());

        if (isSuccess) {
          setState(() {
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }

        return idTokenResult.token;
      }
    } catch (e) {
      print('Error retrieving ID token: $e');
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                color: Colors.black,
              ))
            : HomeScreen());
  }
}
