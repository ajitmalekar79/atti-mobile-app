import 'package:attheblocks/auth/forgot_password.dart';
import 'package:attheblocks/auth/mobile_login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  PostAuthTocken _postAuthTocken = Get.find<PostAuthTocken>();

  bool _isButtonDisabled = true;
  String _errorMessage = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool isSuccess = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // _getIdToken();
      setState(() {
        _isLoading = false;
      });
      Get.offAllNamed('/baseScreen');
      print('User logged in: ${userCredential.user!.email}');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid data'),
        ),
      );
    }
    setState(() {
      _isLoading = false;
    });
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
          //Get.offAllNamed('/baseScreen');
        } else {
          setState(() {
            _isLoading = false;
          });
        }

        print('tocken   ' + idTokenResult.token.toString());

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
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(120),
                      color: Colors.black),
                  child: Image.asset(
                    "assets/images/atbi_logo.png",
                    height: 120,
                    width: 120,
                  ),
                ),
                const SizedBox(height: 40),
                _buildCurvedTextField(
                  'Enter your Email',
                  Icons.person,
                  _emailController,
                ),
                const SizedBox(height: 10),
                _buildCurvedTextField(
                  'Enter your Password',
                  Icons.lock,
                  _passwordController,
                  isPassword: true,
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    if (_emailController.text.isNotEmpty &&
                        _passwordController.text.isNotEmpty) {
                      _login();
                    } else {
                      setState(() {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter email and password.'),
                          ),
                        );
                      });
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.disabled)) {
                          return Colors.black;
                        }
                        return Colors.black;
                      },
                    ),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                    shape: MaterialStateProperty.all<OutlinedBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 0.9,
                    child: Align(
                        alignment: Alignment.center,
                        child: _isLoading
                            ? Container(
                                height: 10,
                                width: 10,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'LOGIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                ),
                              )),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.to(ForgotPassword());
                      },
                      child: const Text(
                        'Forget Password?   ',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () {
                    Get.to(const MobileLoginScreen(),
                        transition: Transition.rightToLeft,
                        duration: Duration(milliseconds: 500));
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: "Login with mobile number",
                      style: TextStyle(fontSize: 15, color: Color(0xFF343434)),
                      children: <TextSpan>[
                        // TextSpan(
                        //   text: 'Sign up!',
                        //   style: TextStyle(
                        //       fontSize: 15,
                        //       color: Color.fromARGB(255, 255, 115, 0),
                        //       fontWeight: FontWeight.bold),
                        // ),
                      ],
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

  Widget _buildCurvedTextField(
    String hintText,
    IconData iconData,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Container(
      height: 50,
      child: TextFormField(
        controller: controller,
        onChanged: (value) {
          setState(() {
            _isButtonDisabled = _emailController.text.isEmpty ||
                _passwordController.text.isEmpty;
          });
        },
        decoration: InputDecoration(
          hintText: hintText,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          // border: InputBorder.none,
          // focusedBorder: OutlineInputBorder(
          //   borderRadius: BorderRadius.circular(5),
          //   borderSide: const BorderSide(color: Colors.blue),
          // ),
          // prefixIcon: Icon(iconData, color: Colors.grey.shade400),
        ),
        obscureText: isPassword,
      ),
    );
  }
}

class CustomDivider extends StatelessWidget {
  final String text;
  final Color color;
  final double thickness;
  final double height;

  const CustomDivider({
    Key? key,
    required this.text,
    required this.color,
    required this.thickness,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Divider(
            color: color,
            thickness: thickness,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: color,
            thickness: thickness,
          ),
        ),
      ],
    );
  }
}
