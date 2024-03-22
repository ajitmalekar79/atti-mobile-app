import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'otp_auth_screen.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  bool rememberMe = false;
  final TextEditingController _phoneNumberController = TextEditingController();
  String countryCode = '+91';
  bool _loading = false;
  FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> signInWithPhoneNumber(
      String phoneNumber, context, mobile) async {
    bool isSuccess = false;
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        isSuccess = true;
      },
      verificationFailed: (FirebaseAuthException e) async {
        isSuccess = false;
        print(e);
      },
      codeSent: (String verificationId, int? resendToken) async {
        isSuccess = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('verificationId', verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
    return isSuccess;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SizedBox(
        height: double.infinity,
        child: Stack(
          children: <Widget>[
            logingbody(width, height),
          ],
        ),
      ),
    );
  }

  logingbody(width, height) {
    return Container(
      height: height * 62,
      margin: EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              height: 100,
            ),
            Row(
              children: [
                Container(
                  height: 48,
                  width: 100,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(0),
                  //  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0),
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                            blurRadius: 1, color: Colors.black, spreadRadius: 1)
                      ]),
                  child: CountryCodePicker(
                    onChanged: (value) {
                      countryCode = value.toString();
                    },

                    // Initial selection and favorite can be one of code ('IT') OR dial_code('+39')
                    initialSelection: '+91',
                    favorite: const ['+91', ''],

                    // optional. Shows only country name and flag
                    showCountryOnly: false,
                    // optional. Shows only country name and flag when popup is closed.
                    showOnlyCountryWhenClosed: false,
                    // optional. aligns the flag and the Text left
                    alignLeft: false,
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(0),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                              blurRadius: 1,
                              color: Colors.black,
                              spreadRadius: 1)
                        ]),
                    child: TextField(
                        keyboardType: TextInputType.number,
                        controller: _phoneNumberController,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: 'Enter Phone Number',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                        )),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            InkWell(
              onTap: _loading
                  ? null
                  : () async {
                      setState(() {
                        _loading = true;
                      });
                      _onSubmit();
                    },
              child: Container(
                height: 45,
                width: 196,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(0),
                    color: Colors.black),
                child: _loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool validateMobileNumber(String value) {
    // Regular expression to validate a mobile number
    // Adjust the pattern based on your specific requirements
    final RegExp mobileRegex = RegExp(r'^[0-9]{10}$');
    return mobileRegex.hasMatch(value);
  }

  void _onSubmit() async {
    String phoneNumber = '$countryCode${_phoneNumberController.text.trim()}';
    if (validateMobileNumber(_phoneNumberController.text.trim())) {
      setState(() {
        _loading = false;
      });
      Get.to(
          OtpScreen(
            mobileNo: _phoneNumberController.text.trim(),
          ),
          transition: Transition.fade,
          duration: const Duration(seconds: 1));
      signInWithPhoneNumber(
          phoneNumber, context, _phoneNumberController.text.trim());
    } else {
      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Phone Number'),
        ),
      );
    }
  }
}
