import 'dart:async';

import 'package:attheblocks/base_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpScreen extends StatefulWidget {
  String mobileNo;
  OtpScreen({super.key, required this.mobileNo});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _pinEditingController = TextEditingController();
  int _remainingTime = 30;
  bool _isResendEnabled = false;
  final String _expectedOtp = "1234";
  FirebaseAuth _auth = FirebaseAuth.instance;
  String Otp = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        if (mounted) {
          setState(() {
            _remainingTime--;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isResendEnabled = true;
          });
        }
        timer.cancel();
      }
    });
  }

  void resendOtp() {
    setState(() async {
      String phoneNumber = "+91${widget.mobileNo}";
      _remainingTime = 30;
      _isResendEnabled = false;
      startTimer();
      // ignore: use_build_context_synchronously
      await signInWithPhoneNumber(phoneNumber, context, widget.mobileNo);
      // Add your logic for sending a new OTP here
    });
  }

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
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
          fontSize: 20,
          color: Color.fromRGBO(30, 60, 87, 1),
          fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromARGB(255, 146, 135, 135)),
        borderRadius: BorderRadius.circular(20),
      ),
    );

    return Scaffold(
      appBar: AppBar(
          //title: Text('OTP Screen'),
          ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Verification',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                  padding: const EdgeInsets.all(5),
                  // decoration: BoxDecoration(
                  //     borderRadius: BorderRadius.circular(10),
                  //     color: Color.fromARGB(255, 252, 253, 253)),
                  child: Pinput(
                    controller: _pinEditingController,
                    length: 6,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration?.copyWith(
                            boxShadow: [
                          const BoxShadow(
                              blurRadius: 1,
                              spreadRadius: 1,
                              color: Color.fromARGB(255, 229, 245, 236))
                        ],
                            border: Border.all(
                                color:
                                    const Color.fromARGB(255, 146, 228, 177)))),
                  )),
              const SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Resend OTP in $_remainingTime seconds',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  _isResendEnabled
                      ? InkWell(
                          onTap: () {
                            resendOtp();
                          },
                          child: Container(
                              height: 45,
                              width: 196,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.black),
                              child: const Text(
                                'Resend OTP',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              )),
                        )
                      : Container(),
                ],
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  // verifyOtp();
                  setState(() {
                    Otp = _pinEditingController.text;
                    isLoading = true;
                  });
                  _signInWithPhoneNumber();
                },
                child: Container(
                    height: 45,
                    width: 196,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFF0A646C)),
                    child: isLoading == true
                        ? CircularProgressIndicator()
                        : const Text(
                            'Verify OTP',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          )),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithPhoneNumber() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final verificationID = prefs.getString('verificationId');
      String mobileNo = widget.mobileNo;

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: '$verificationID',
          smsCode: _pinEditingController.text.toString());
      await _auth.signInWithCredential(credential);

      Get.offAllNamed(
        BaseScreen.baseRouteName,
      );

      setState(() {
        isLoading = false;
      });

      print('Phone number authenticated successfully!');
    } catch (e) {
      // ignore: use_build_context_synchronously
      setState(() {
        isLoading = false;
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid OTP. Please try again.'),
        ),
      );
      print(e.toString());
    }
  }
}
