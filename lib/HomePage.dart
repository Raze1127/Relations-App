import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';



import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gifimage/flutter_gifimage.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:transparent_image/transparent_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pageIndex = 0;
  final _pageController = PageController(
      initialPage: 0
  );

  @override
  Widget build(BuildContext contex) {
    return Scaffold(
      body:
      PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
        children: const <Widget>[
          MyContacts(),
          MyQandA(),
          MyToDo(),
          MyProfile(),

        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 7.5),
          child: GNav(
            backgroundColor: Colors.black,
            color: Colors.white,
            activeColor: Colors.white,
            gap: 8,
            selectedIndex: _pageIndex,
            onTabChange: (index) {
              setState(() => _pageIndex = index);
              _pageController.jumpToPage(index);
            },
            padding: const EdgeInsets.all(16),
            tabs: const [
              GButton(icon: Icons.home,
                  text: "Home"),
              GButton(icon: Icons.question_answer, text: "Q&A"),
              GButton(icon: Icons.checklist, text: "To Do"),

              GButton(icon: Icons.map, text: "Map",)
            ],),
        ),
      ),
    );
  }
}

class MyQandA extends StatefulWidget {
  const MyQandA({Key? key}) : super(key: key);

  @override
  _MyQandAstate createState() => _MyQandAstate();
}

class _MyQandAstate extends State<MyQandA> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  var value = 1;
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;

  Future<String> GetQ() async {
    final ref = FirebaseDatabase.instance.ref();
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final relat = await ref.child('Users/$uid/relations').get();
    final num = await ref.child('Relations/${relat.value.toString()}/num').get();
    if(num.exists) {


      final q = await ref
          .child('Questions/${num.value.toString()}')
          .get();
      return q.value.toString();

    } else {
      final q = await ref
          .child('Questions/1')
          .get();
      return q.value.toString();
    }

  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: GetQ(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              key: scaffoldKey,
              body: Center(child: Text(snapshot.data.toString())),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },

    );
  }

}

class MyContacts extends StatefulWidget {
  const MyContacts({Key? key}) : super(key: key);

  @override
  _MyContactsState createState() => _MyContactsState();
}

class _MyContactsState extends State<MyContacts>  with TickerProviderStateMixin{
  final scaffoldKey = GlobalKey<ScaffoldState>();
  var value = 1;
  firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;



  File? _photo;
  final ImagePicker _picker = ImagePicker();

  Future imgFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
        uploadFile(0);
      } else {
        print('No image selected.');
      }
    });
  }

  Future imgFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
        uploadFile(0);
      } else {
        print('No image selected.');
      }
    });
  }


  Future imgFromGalleryMain() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
        uploadFile(1);
      } else {
        print('No image selected.');
      }
    });
  }

  Future imgFromCameraMain() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _photo = File(pickedFile.path);
        uploadFile(1);
      } else {
        print('No image selected.');
      }
    });
  }


  Future uploadFile(int i) async {
    if (_photo == null) return;
    final fileName = basename(_photo!.path);
    final destination = 'files/$fileName';
    File compressedFile = await FlutterNativeImage.compressImage(_photo!.path,
        quality: 50, percentage: 70);
    try {
      final ref = firebase_storage.FirebaseStorage.instance
          .ref(destination)
          .child('file/');
      await ref.putFile(compressedFile);
      String url = (await ref.getDownloadURL()).toString();
      FirebaseDatabase database = FirebaseDatabase.instance;
      final refe = FirebaseDatabase.instance.ref();
      final User? user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;
      final relat = await refe.child("Users/$uid/relations").get();
      final part = await refe.child("Users/$uid/partner").get();
      if (relat.exists && part.exists) {
        if (i == 0) {
          database.ref("Users/$uid").update({
            "photo": url,
          }
          );
        }
        else {
          database.ref("Relations/${relat.value.toString()}").update({
            "photo${part.value.toString()}": url,
          }
          );
        }
      }
    } catch (e) {
      print('error occured');
    }
    setState(() {});
  }


  void sendPushMessage(String body, String title, String token) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
          'key=AAAAxkBoobs:APA91bEOkequ3bZVO0Wh3njtyM8huxybgpJ2G2lBXSYpBrsiuhZ4IijJiqARKAGg_IzbrWrLfnESXw0zKn0ukjkfc9hQ8WTc-h6-Ws9YTdxqLS9dGdBc7S643pa12RKVoGZNOyVDf2u0',
        },
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{
              'body': body,
              'title': title,
            },
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done'
            },
            "to": token,
          },
        ),
      );
      print('done');
      print(token);
    } catch (e) {
      print("error push notification");
    }
  }




  Future<String> GetRelation() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print(fcmToken);
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
    print('User granted permission: ${settings.authorizationStatus}');
    final ref = FirebaseDatabase.instance.ref();
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final snapshot = await ref.child('Users/$uid/relations').get();
    final snap = await ref.child('Relations/${snapshot.value.toString()}/date').get();
    final date = DateTime.parse(snap.value.toString());
    int daysBetween(DateTime from, DateTime to) {
      from = DateTime(from.year, from.month, from.day);
      to = DateTime(to.year, to.month, to.day);
      return (to.difference(from).inHours / 24).round();
    }
    final date2 = DateTime.now();
    final difference = daysBetween(date, date2);
    return difference.toString();
  }

  Future<String> GetPhoto() async {
    final ref = FirebaseDatabase.instance.ref();
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final relat = await ref.child('Users/$uid/photo').get();

    if(relat.exists){
      return relat.value.toString();
    }else{
      return 'https://brilliant24.ru/files/cat/bg_template_01.png';
    }

  }



  Future<String> GetFcm() async {

    final ref = FirebaseDatabase.instance.ref();
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final snapshot = await ref.child('Users/$uid/relations').get();
    final partner = await ref.child("Users/$uid/partner").get();
    print(snapshot.value.toString());
    if(partner.value.toString() == "1"){
      final part = await ref.child('Relations/${snapshot.value.toString()}/partner2').get();

      final relat = await ref.child("Users/${part.value.toString()}/FcmToken").get();
      return relat.value.toString();
    }else{
      final part = await ref.child('Relations/${snapshot.value.toString()}/partner1').get();
      final relat = await ref.child("Users/${part.value.toString()}/FcmToken").get();
      return relat.value.toString();
    }


  }

  Future<String> GetPhoto2() async {
    final ref = FirebaseDatabase.instance.ref();
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final snapshot = await ref.child('Users/$uid/relations').get();
    final partner = await ref.child("Users/$uid/partner").get();
    print(snapshot.value.toString());
      if(partner.value.toString() == "1"){

        final part = await ref.child('Relations/${snapshot.value.toString()}/partner2').get();

        final relat = await ref.child("Users/${part.value.toString()}/photo").get();
        print(relat.value.toString());
        return relat.value.toString();
      }else{
        final part = await ref.child('Relations/${snapshot.value.toString()}/partner1').get();
        final relat = await ref.child("Users/${part.value.toString()}/photo").get();
        return relat.value.toString();
      }



  }


  Future<String> GetPhoto3() async {
    final ref = FirebaseDatabase.instance.ref();
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final snapshot = await ref.child('Users/$uid/relations').get();

    final relation = await ref.child("Users/$uid/partner").get();

    if (relation.value.toString() == "1") {
      final relat =
      await ref.child('Relations/${snapshot.value.toString()}/photo2').get();
      return relat.value.toString();
    } else {
      final relat =
      await ref.child('Relations/${snapshot.value.toString()}/photo1').get();
      return relat.value.toString();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xffE0E3E7),
        body: FutureBuilder(
          future: Future.wait([
            GetPhoto(),
            GetPhoto2(),
            GetRelation(),
            GetFcm(),
            GetPhoto3(),
          ]),

          builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
            GifController controllerCry= GifController(vsync: this);
            GifController controller18= GifController(vsync: this);
            GifController controllerBell= GifController(vsync: this);

            controllerBell.value = 1;
            controller18.value = 1;
            controllerCry.value = 1;

            if(snapshot.hasData) {
             return SafeArea(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0, 20, 0, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    5, 0, 0, 0),
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: GestureDetector(
                                    child: FadeInImage.memoryNetwork(
                                      image: snapshot.data![1].toString(),
                                      fit: BoxFit.cover,
                                      placeholder: kTransparentImage,
                                    ),
                                  )
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  20, 0, 20, 0),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,

                                children: [
                                  Padding(
                                    padding:
                                    const EdgeInsetsDirectional.fromSTEB(0, 10, 0, 0),
                                    child: Container(
                                        width: 45,
                                        height: 45,
                                        child: Image.network('https://emojis.wiki/emoji-pics-lf/telegram/heart-on-fire-telegram.gif')),
                                  ),
                                  Align(
                                    alignment: const AlignmentDirectional(0, 0),
                                    child: AutoSizeText(
                                      snapshot.data![2].toString(),
                                      textAlign: TextAlign.center,
                                      minFontSize: 25,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: const AlignmentDirectional(0, 0),
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      0, 0, 5, 0),
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                    ),
                                    child: GestureDetector(
                                      onTap: imgFromGallery,
                                      child: FadeInImage.memoryNetwork(
                                        image: snapshot.data![0].toString(),
                                        fit: BoxFit.cover,
                                        placeholder: kTransparentImage,
                                      ),
                                    )
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            0, 30, 0, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    30, 0, 30, 0),
                                child: Card(
                                  clipBehavior: Clip.antiAliasWithSaveLayer,
                                  color: const Color(0xFFE0E3E7),
                                  elevation: 20,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                  child: Padding(
                                    padding:
                                    const EdgeInsetsDirectional.fromSTEB(
                                        0, 10, 0, 0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment: MainAxisAlignment
                                          .spaceAround,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(
                                              0, 10, 0, 0),
                                          child: InkWell(
                                            onTap: () async {

                                            },
                                            child: Hero(
                                              tag: 'imageTag',
                                              transitionOnUserGestures: true,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius
                                                    .circular(40),
                                                child: FadeInImage.memoryNetwork(
                                                    image: snapshot.data![4].toString(),
                                                    width: 250,
                                                    height: 230,
                                                    fit: BoxFit.cover,
                                                    placeholder: kTransparentImage,

                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment: CrossAxisAlignment
                                              .center,
                                          children: [

                                            IconButton(
                                                icon: const Icon(
                                                  Icons.photo,
                                                  color: Color(0xff101213),
                                                  size: 30,
                                                ),
                                                onPressed: () {
                                                  imgFromGalleryMain();
                                                },
                                              ),

                                            IconButton(
                                              icon: const Icon(
                                                Icons.photo_camera,
                                                color: Color(0xff101213),
                                                size: 30,
                                              ),
                                              onPressed: () {
                                                imgFromCameraMain();
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            25, 35, 25, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              iconSize: 70,
                              icon: GifImage(
                                controller: controllerBell,
                                image: const AssetImage('assets/images/bell1.gif'),
                              ),

                              onPressed: () {
                                if  (controllerBell.value == 179) {
                                  controllerBell.value = 1;
                                }
                                controllerBell.animateTo(179, duration: const Duration(milliseconds: 3600));

                                sendPushMessage("Ваш партнер сильно нуждается в вашей помощи", "СРОЧНАЯ ПОМОЩЬ📣📣📣", snapshot.data![3].toString());
                              },
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  23, 0, 27, 0),
                              child: IconButton(
                                iconSize: 70,
                                icon:GifImage(
                                  controller: controller18,
                                  image: const AssetImage('assets/images/18.gif'),
                                ),
                                onPressed: () {
                                  if  (controller18.value == 179) {
                                    controller18.value = 1;
                                  }
                                  controller18.animateTo(179, duration: const Duration(milliseconds: 3600));

                                  sendPushMessage("оууууу", "🔞🔞🔞🔞", snapshot.data![3].toString());
                                },
                              ),
                            ),
                            IconButton(
                              iconSize: 65,
                              icon: GifImage(
                                controller: controllerCry,
                                image: const AssetImage('assets/images/cry.gif'),
                              ),
                              onPressed: () {
                                if  (controllerCry.value == 179) {
                                  controllerCry.value = 1;
                                }
                                controllerCry.animateTo(179, duration: const Duration(milliseconds: 3600));


                                sendPushMessage("Ваш партнер нуждается в поддержке!", "😭😭😭", snapshot.data![3].toString());
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }else{
              return const Center(child: CircularProgressIndicator());
            }
          },
        )
    );
  }
}

class MyToDo extends StatefulWidget {
  const MyToDo({Key? key}) : super(key: key);

  @override
  _MyToDoState createState() => _MyToDoState();
}

class _MyToDoState extends State<MyToDo> {
  var relations = "";

  Future<String> GetRelations() async {
    final ref = FirebaseDatabase.instance.ref();
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final snapshot = await ref.child('Users/$uid/relations').get();
    return snapshot.value.toString();
  }


  final fb = FirebaseDatabase.instance;
  var l;
  var g;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xffE0E3E7),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.black,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const addnote(),
              ),
            );
          },
          child: const Icon(
            Icons.add,
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0, 50, 0, 0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                    child: Text(
                      'Общие дела',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                ],
              ),
            ),
            FutureBuilder<String>(
                future: GetRelations(),
                builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                  var ref = fb.ref().child('Relations/${snapshot.data}/todos');
                  if (snapshot.hasData) {
                    return FirebaseAnimatedList(
                      padding: const EdgeInsets.only(top: 20),
                      query: ref,
                      shrinkWrap: true,
                      itemBuilder: (context, snapshot, animation, index) {
                        var v = snapshot.value.toString();
                        g = v.replaceAll(RegExp("{|}|subtitle: |title: "), "");
                        g.trim();
                        l = g.split(',');
                        return GestureDetector(
                          onTap: () {

                          },
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                10, 25, 10, 10),
                            child: Material(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 20,
                              child: ListTile(

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                tileColor: const Color(0xFFE0E3E7),

                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    var snap = snapshot.key.toString();

                                    ref.child(snap).remove();
                                  },
                                ),

                                title: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      10, 10, 10, 0),
                                  child: Text(
                                    l[1],
                                    style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      10, 10, 10, 10),
                                  child: Text(
                                    l[0],
                                    style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    return const Center(child: Text(""));
                  }
                }
            ),
          ],
        )
    );
  }

}




class AppConstants {
  static const String mapBoxAccessToken = 'pk.eyJ1IjoicmF6ZTExMjciLCJhIjoiY2xkNnU4cGU2MGoxcjN1cWh4ZDNudmcxdiJ9.bIbOHaOGiNnxTpfI_dMWWA';

  static const String mapBoxStyleId = 'cld6ulc88000101s9y81fov5o';

  static final myLocation = LatLng(51.5090214, -0.1982948);
}

class MyProfile extends StatelessWidget {
  const MyProfile({Key? key}) : super(key: key);

  Future<String> locate() async {
    Location location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {

      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {

      }
    }
    locationData = await location.getLocation();
    final ref = FirebaseDatabase.instance.ref();
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final snapshot = await ref.child('Users/$uid/relations').get();
    final relation = await ref.child("Users/$uid/partner").get();
    FirebaseDatabase database = FirebaseDatabase.instance;
    database.ref("Relations/${snapshot.value.toString()}").update({
      "UserLocation${relation.value.toString()}": "${locationData.latitude!}()${locationData.longitude!}",
    }
    );
    final relat = (await ref.child('Users/$uid/relations').get()).value.toString();
    final partner1 = (await ref.child('Relations/$relat/partner1').get()).value.toString();
    final partner2 = (await ref.child('Relations/$relat/partner2').get()).value.toString();
    final photo1 = (await ref.child('Users/$partner1/photo').get()).value.toString();
    final photo2 = (await ref.child('Users/$partner2/photo').get()).value.toString();
    final location1 = (await ref.child('Relations/$relat/UserLocation1').get()).value.toString();
    final location2 = (await ref.child('Relations/$relat/UserLocation2').get()).value.toString();
    if(uid == partner1){
      return "$photo1()$photo2()$location1()$location2";
    }else{
      return "$photo2()$photo1()$location2()$location1";
    }

  }


  @override
  Widget build(BuildContext context) {

    return FutureBuilder<String>(
      future: locate(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if(snapshot.hasData){
          List<String> stylist = snapshot.data.toString().split("()");
          return FlutterMap(
            options: MapOptions(
              minZoom: 5,
              maxZoom: 18,
              zoom: 15,
              center: LatLng(double.parse(stylist[2]),double.parse(stylist[3])),
            ),
            children: [
              TileLayer(
                minZoom: 1,
                urlTemplate: 'https://api.mapbox.com/styles/v1/raze1127/cld6ulc88000101s9y81fov5o/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoicmF6ZTExMjciLCJhIjoiY2xkNnU4cGU2MGoxcjN1cWh4ZDNudmcxdiJ9.bIbOHaOGiNnxTpfI_dMWWA',
                additionalOptions: const {
                  'mapStyleId': AppConstants.mapBoxStyleId,
                  'accessToken': AppConstants.mapBoxAccessToken,
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(double.parse(stylist[2]),double.parse(stylist[3])),
                    width: 50,
                    height: 50,
                    builder: (BuildContext context) {
                            if(snapshot.hasData){
                              return Column(
                                children:  <Widget>[
                                  Container(
                                      width: 50,
                                      height: 50,
                                      clipBehavior: Clip.antiAlias,
                                      decoration:  BoxDecoration(
                                        border: Border.all(
                                          width: 2,
                                        ),
                                        shape: BoxShape.circle,
                                        color: Colors.black,

                                      ),
                                      child: GestureDetector(
                                          onTap: null,
                                          child:
                                          ClipOval(
                                            child: FadeInImage.memoryNetwork(
                                              placeholder: kTransparentImage,
                                              placeholderFit: BoxFit.cover,
                                              fit: BoxFit.cover,
                                              image: stylist[0],
                                            ),
                                          )
                                      )
                                  ),
                                ],
                              );
                            }else{
                              return const Center(child: CircularProgressIndicator());
                            }
                          }
                      ),


                  Marker(
                      point: LatLng(double.parse(stylist[4]),double.parse(stylist[5])),
                      width: 50,
                      height: 50,
                      builder: (BuildContext context) {
                        if(snapshot.hasData){
                          return Column(
                            children:  <Widget>[
                              Container(
                                  width: 50,
                                  height: 50,
                                  clipBehavior: Clip.antiAlias,
                                  decoration:  BoxDecoration(
                                    border: Border.all(
                                      width: 2,
                                    ),
                                    shape: BoxShape.circle,
                                    color: Colors.black,

                                  ),
                                  child: GestureDetector(
                                      onTap: null,
                                      child:
                                      ClipOval(
                                        child: FadeInImage.memoryNetwork(
                                          placeholder: kTransparentImage,
                                          placeholderFit: BoxFit.cover,
                                          fit: BoxFit.cover,
                                          image: stylist[1],
                                        ),
                                      )
                                  )
                              ),
                            ],
                          );
                        }else{
                          return const Center(child: CircularProgressIndicator());
                        }
                      }
                  ),
                    ]

                  ),
                ],
              );


        }else{
          return const Center(child: CircularProgressIndicator());
        }


      }
    );
  }
}





class addnote extends StatefulWidget {
  const addnote({Key? key}) : super(key: key);

  @override
  _addnoteState createState() => _addnoteState();
}

class _addnoteState extends State<addnote> {
  TextEditingController second = TextEditingController();

  TextEditingController third = TextEditingController();

  final fb = FirebaseDatabase.instance;

  @override
  Widget build(BuildContext context) {
    var rng = Random();
    var k = rng.nextInt(10000);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Создание заметки"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 30, 20, 0),
            child: TextField(
              controller: second,
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xff4c505b)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xff4c505b)),
                ),
                hintText: 'Название',
                hintStyle: const TextStyle(color: Color(0xff4c505b),
                    fontSize: 20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 30),
            child: TextField(
              controller: third,
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xff4c505b)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xff4c505b)),
                ),
                hintText: 'Описание',
                hintStyle: const TextStyle(
                    color: Color(0xff4c505b),
                    fontSize: 15
                ),
              ),
            ),
          ),

          MaterialButton(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            color: Colors.black,
            onPressed: () {
              GetRelations() async {
                final refe = FirebaseDatabase.instance.ref();
                final User? user = FirebaseAuth.instance.currentUser;
                final uid = user?.uid;
                final snapshot = await refe.child('Users/$uid/relations').get();
                var str = snapshot.value.toString();
                var ref = fb.ref().child('Relations/$str/todos/$k');
                ref.set({
                  "title": second.text,
                  "subtitle": third.text,
                }).asStream();
              }
              GetRelations();
              Navigator.pop(
                  context);
            },
            child: const Text(
              "Сохранить",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}