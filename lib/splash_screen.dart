import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  static const String splashRoute = '/splashScreen';
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  // final ConnectivityController networkController =
  //     Get.find<ConnectivityController>();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start the fade-in animation
    _animationController.forward();

    Future.delayed(const Duration(seconds: 4), () {
      // Navigate to the main screen after the splash screen duration
      navigationTo();
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => LoginPage()),
      // );
    });
  }

  Future<void> navigationTo() async {
    // final prefs = await SharedPreferences.getInstance();
    // final mobile = prefs.getString('mobile');
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Get.offAllNamed('/baseScreen');
    } else {
      Get.offAllNamed('/logingScreen');
    }

    //Get.offAllNamed(BaseScreen.baseRouteName);
    // if (mobile != null && mobile.isNotEmpty) {
    //   // MPIN is set, redirect to MPIN entry screen
    //   //Get.offAllNamed('/mpin');
    //   Get.offAllNamed(BaseScreen.baseRouteName);
    //   // Navigator.of(context).pushReplacement(
    //   //   MaterialPageRoute(builder: (context) => MPINScreen()),
    //   // );
    // } else {
    //   // MPIN is not set, redirect to login page
    // Get.offAllNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 221, 175, 131),
      body: Stack(
        children: [
          Container(
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
                // image: DecorationImage(
                //   image: AssetImage('assets/images/splash_screen_img.png'),
                //   fit: BoxFit.fill,
                // ),
                ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(
                    height: 150,
                  ),
                  Container(
                    height: 50,
                    width: 150,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black),
                    child: const Image(
                      image: AssetImage("assets/images/atbi_logo.png"),
                      height: 143,
                      width: 161,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
              bottom: 0,
              child: Container(
                padding: EdgeInsets.all(10),
                alignment: Alignment.center,
                width: MediaQuery.of(context).size.width,
                child: Text(
                  "version 1.0.0",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
