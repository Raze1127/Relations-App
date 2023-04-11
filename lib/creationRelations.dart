import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "package:firebase_database/firebase_database.dart";
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:intl/intl.dart';
import 'package:nanoid/nanoid.dart';
import 'package:flutter/services.dart';

class CreationRelation extends StatefulWidget {
  const CreationRelation({Key? key}) : super(key: key);

  @override
  _MyCreationRelation createState() => _MyCreationRelation();
}

class _MyCreationRelation extends State<CreationRelation> {

  Future<String> GetCodee() async {
    final ref = FirebaseDatabase.instance.ref();
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final relat = await ref.child('Users/$uid/code').get();
    return relat.value.toString();
  }

  var txt = TextEditingController();

  final codeController = TextEditingController();
  FirebaseDatabase database = FirebaseDatabase.instance;
  String code = "";
  String formattedDate = "";
  String dateStart = "Нажмите для выбора\nдаты начала отношений";
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: GetCodee(),
        builder:
            (context, snapshot1) {
              if(snapshot1.hasData) {
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
                                    TextSpan(text: 'Создание\n',
                                      style: TextStyle(
                                        fontSize: 35,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff4c505b),
                                      ),),

                                    TextSpan(text: 'отношений',
                                      style: TextStyle(
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

                              GestureDetector(
                                onLongPress: () {
                                  Clipboard.setData(ClipboardData(
                                      text: snapshot1.data.toString()));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Скопировано"),));
                                },
                                child: Text(
                                  "Ваш код для приглашения:\n${snapshot1.data
                                      .toString()}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 20,),),
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                              TextField(
                                controller: codeController,
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
                                  hintText: 'Код приглашения',
                                  hintStyle: const TextStyle(
                                      color: Color(0xff4c505b)),
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                              ),


                              TextButton(
                                  onPressed: () {
                                    DatePicker.showDatePicker(context,
                                        showTitleActions: true,
                                        minTime: DateTime(1900, 1, 1),
                                        maxTime: DateTime.now(),
                                        onChanged: (date) {
                                          print('change $date');
                                        },
                                        onConfirm: (date) {
                                          formattedDate = date.toString();
                                          print(formattedDate);
                                          setState(() {
                                            dateStart =
                                                DateFormat('dd.MM.yyyy').format(
                                                    date);
                                          });
                                        },
                                        currentTime: DateTime.now(),
                                        locale: LocaleType.ru);
                                  },
                                  child: Text(
                                    dateStart,
                                    style: const TextStyle(
                                        color: Color(0xff4c505b), fontSize: 21),
                                  )),
                              const SizedBox(
                                height: 20,
                              ),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    const Text(
                                      'Начать',
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
                                          LogIn();
                                        },
                                        icon: const Icon(Icons.arrow_forward),
                                      ),
                                    ),
                                  ]),

                              const SizedBox(
                                height: 20,
                              ),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .spaceBetween,
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
              else{
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            }
    );

  }
  Future LogIn() async{
    String codee = "";
    final ref = FirebaseDatabase.instance.ref();
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final relat = await ref.child('Users/$uid/code').get();
    codee = relat.value.toString();

    if(codeController.text !=  "" && relat.exists){

      var vod = codeController.text.trim();
      final check = await ref.child('Relations/${vod+codee}').get();
      final check1 = await ref.child('Relations/${codee+vod}').get();
      if(check.exists || check1.exists){
        print('object');
        final snapshot = await ref.child('Relations/${vod+codee}/partner1').get();
        if (snapshot.exists) {

          database.ref("Relations/${vod+codee}").update({
            "partner2": uid,
            "date": formattedDate
          }
          );
          database.ref("Users/$uid").update({
            "IsReady": "Yes",
            "relations": vod+codee,
            "partner": 2
          }
          );
          Navigator.pushNamed(context, 'home');
        }
      }else{
        database.ref("Relations/${codee+vod}").update({
          "partner1": uid,
          "date": formattedDate
        }
        );
        database.ref("Users/$uid").update({
          "IsReady": "Yes",
          "relations": (codee+vod),
          "partner": 1
        }
        );
        Navigator.pushNamed(context, 'home');
      }
    }


  }
}