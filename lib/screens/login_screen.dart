import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_verification/screens/home_screen.dart';

enum MobileVerificationState {
  SHOW_MOBILE_FORM_STATE,
  SHOW_OTP_FORM_STATE,
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  MobileVerificationState currentState = MobileVerificationState.SHOW_MOBILE_FORM_STATE;

  TextEditingController _numberController = TextEditingController();
  TextEditingController _otpController = TextEditingController();

  FirebaseAuth _auth = FirebaseAuth.instance;

  String verificationId;

  bool showLoading = false;


  void signInWithPhoneAuthCred(AuthCredential phoneAuthCredential) async {

    setState(() {
      showLoading = true;
    });
    try {

      final authCredential = await _auth.signInWithCredential(phoneAuthCredential);

      setState(() {
        showLoading = false;
      });

      if(authCredential.user != null) {
        Navigator.push(context, MaterialPageRoute(builder: (context)=>HomeScreen()));
      }


    } on FirebaseAuthException catch (e) {
      setState(() {
        showLoading = false;
      });

      _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  getMobileFormWidget(context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: _numberController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Phone Number",
              hintText: "Enter phone number",
            ),
          ),
          SizedBox(
            height: 18,
          ),
          Container(
            width: MediaQuery
                .of(context)
                .size
                .width,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () async {

                setState(() {
                  showLoading = true;
                });

                await _auth.verifyPhoneNumber(
                  phoneNumber: _numberController.text.toString(),
                  verificationCompleted: (phoneAuthCredential) async {
                    setState(() {
                      showLoading = false;
                    });
                  },
                  verificationFailed: (verificationFailed) async{
                    setState(() {
                      showLoading = false;
                    });
                    _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text(verificationFailed.message)));
                  },
                  codeSent: (verificationId, resendingToken) async {
                    setState(() {
                      showLoading = false;
                      currentState = MobileVerificationState.SHOW_OTP_FORM_STATE;
                      this.verificationId = verificationId;
                    });
                  },
                  codeAutoRetrievalTimeout: (verificationId) async {

                  },
                );
              },
              child: Text("Send"),
            ),
          ),
        ],
      ),
    );
  }

  getOtpFormWidget(context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: _otpController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: "OTP Number",
              hintText: "Enter OTP",
            ),
          ),
          SizedBox(
            height: 18,
          ),
          Container(
            width: MediaQuery
                .of(context)
                .size
                .width,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () async {
                final phoneAuthCredential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: _otpController.text.toString());
                signInWithPhoneAuthCred(phoneAuthCredential);
              },
              child: Text("Verify"),
            ),
          ),
        ],
      ),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: showLoading ? Center(child: CircularProgressIndicator(),) : currentState == MobileVerificationState.SHOW_MOBILE_FORM_STATE
          ? getMobileFormWidget(context)
          : getOtpFormWidget(context),
    );
  }
}

