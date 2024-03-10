// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart'; // Import this for TextInputType and FilteringTextInputFormatter

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({
    Key? key,
  }) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isEmailRegistered = false;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User Register Successfully'),
        ),
      );
      Get.back();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter valid data ' + e.toString()),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<String> providers =
          await _auth.fetchSignInMethodsForEmail(_emailController.text);
      if (providers.isNotEmpty) {
        // Email is already registered
        setState(() {
          _isEmailRegistered = true;
        });
      } else {
        // Email is not registered
        setState(() {
          _isEmailRegistered = false;
        });
        // You can proceed with registration here
      }
    } on FirebaseAuthException catch (e) {
      print('Error checking email: ${e.message}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
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
                  'Enter your Name',
                  Icons.person,
                  _nameController,
                ),
                const SizedBox(height: 10),
                _buildCurvedTextField(
                  'Enter your Email',
                  Icons.email,
                  _emailController,
                ),
                const SizedBox(height: 10),
                _buildCurvedTextField(
                  'Enter your Password',
                  Icons.lock,
                  _passwordController,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_emailController.text.isNotEmpty &&
                        _nameController.text.isNotEmpty &&
                        _passwordController.text.isNotEmpty) {
                      _register();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter valid data'),
                        ),
                      );
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
                          ? const CircularProgressIndicator()
                          : const Text(
                              'SIGN UP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Get.back();
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(fontSize: 15, color: Color(0xFF343434)),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Login here!',
                          style: TextStyle(
                              fontSize: 15,
                              color: Color.fromARGB(255, 255, 115, 0),
                              fontWeight: FontWeight.bold),
                        ),
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
    bool isMobile = false,
  }) {
    return Container(
      height: 50,
      // decoration: BoxDecoration(
      //   borderRadius: BorderRadius.circular(5),
      //   border: Border.all(color: Colors.grey.shade400),
      // ),
      child: TextFormField(
        controller: controller,
        onChanged: (value) {
          setState(() {});
        },
        keyboardType: isMobile ? TextInputType.phone : TextInputType.text,
        inputFormatters:
            isMobile ? [FilteringTextInputFormatter.digitsOnly] : [],
        decoration: InputDecoration(
          hintText: hintText,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          // border: InputBorder.none,
          // focusedBorder: OutlineInputBorder(
          //   borderRadius: BorderRadius.circular(5),
          //   borderSide: BorderSide(color: Colors.blue),
          // ),
          prefixIcon: Icon(iconData, color: Colors.grey.shade400),
        ),
        validator: (value) {
          if (value!.isEmpty) {
            return 'Please enter $hintText';
          } else if (isMobile && !isValidMobile(value)) {
            return 'Please enter a valid 10-digit mobile number';
          }
          return null;
        },
      ),
    );
  }

  bool isValidMobile(String value) {
    return RegExp(r'^[0-9]{10}$').hasMatch(value);
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
