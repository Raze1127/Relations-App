import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import "package:firebase_database/firebase_database.dart";
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:intl/intl.dart';
import 'package:nanoid/nanoid.dart';
import 'package:flutter/services.dart';

class MyRegister extends StatefulWidget {
  const MyRegister({Key? key}) : super(key: key);

  @override
  _MyRegisterState createState() => _MyRegisterState();
}

class _MyRegisterState extends State<MyRegister> {





  var txt = TextEditingController();
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final codeController = TextEditingController();
  FirebaseDatabase database = FirebaseDatabase.instance;
  String code = "";
  String formattedDate = "";
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(

      builder:
          (context, snapshot1) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(
                  color: Color(0xff4c505b), //change your color here
                ),
              ),
              backgroundColor: Colors.white,
              body: SingleChildScrollView(
                child: Stack(
                    children: [
                      Container(
                          alignment: Alignment.center,
                          child:

                          RichText(

                            text: const TextSpan(
                              style: TextStyle(

                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff4c505b),
                              ),
                              children: <TextSpan>[
                                TextSpan(text: 'Создание\n', style: TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff4c505b),
                                ),),

                                TextSpan(text: 'Аккаунта', style: TextStyle(
                                  fontSize: 35,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff4c505b),
                                ),),
                              ],
                            ),
                            textAlign: TextAlign.left,
                          )

                      ),
                      Container(
                        padding: EdgeInsets.only(
                            right: 35,
                            left: 35,
                            top: MediaQuery
                                .of(context)
                                .size
                                .height * 0.23),
                        child: Column(children: [
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xff4c505b)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xff4c505b)),
                              ),
                              hintText: 'Имя',
                              hintStyle: const TextStyle(
                                  color: Color(0xff4c505b)),
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          TextField(
                            controller: emailController,
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xff4c505b)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xff4c505b)),
                              ),
                              hintText: 'Email',

                              hintStyle: const TextStyle(
                                  color: Color(0xff4c505b)),
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xff4c505b)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xff4c505b)),
                              ),
                              hintText: 'Пароль',
                              hintStyle: const TextStyle(
                                  color: Color(0xff4c505b)),
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ),



                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Войти',
                                  style: TextStyle(
                                    color: Color(0xff4c505b),
                                    fontSize: 27,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: const Color(0xff4c505b),
                                  child: IconButton(
                                    color: Colors.white,
                                    onPressed: () {
                                      if (emailController.text.trim() != "" &&
                                          passwordController.text.trim() !=
                                              "" &&
                                          nameController.text.trim() != "") {
                                        LogIn();

                                      }
                                    },
                                    icon: const Icon(Icons.arrow_forward),
                                  ),
                                ),
                              ]),

                          const SizedBox(
                            height: 20,
                          ),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, 'login');
                                  },
                                  child: const Text(
                                    '',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      fontSize: 18,
                                      color: Color(0xff4c505b),
                                    ),
                                  ),
                                ),
                              ]),

                        ]),
                      ),
                    ]),
              ),
            );
          }
    );
  }
  Future LogIn() async{
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim()
    );
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final fcmToken = await FirebaseMessaging.instance.getToken();
    code = nanoid(5);
    database.ref("Users/$uid").update({
      "code": code,
      "FcmToken": fcmToken,
      "IsReady": "No",
      "Name": nameController.text.trim(),
      "photo": "https://upload.wikimedia.org/wikipedia/commons/9/9a/%D0%9D%D0%B5%D1%82_%D1%84%D0%BE%D1%82%D0%BE.png"
    }
    );
    Navigator.pushNamed(
        context, 'creation');

  }
}