import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gif/flutter_gif.dart';
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
  final _pageController = PageController(initialPage: 0);
  @override
  Widget build(BuildContext contex) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
        children: const <Widget>[
          MyContacts(),
          ChatScreen(),
          MyToDo(),
          MyProfile(),
        ],
      ),

      bottomNavigationBar:

      Container(
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
              GButton(icon: Icons.home, text: "Home"),
              GButton(icon: Icons.chat, text: "Chat"),
              GButton(icon: Icons.checklist, text: "To Do"),
              GButton(
                icon: Icons.map,
                text: "Map",
              )
            ],
          ),
        ),
      ),

    );
  }
}
class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final reference = FirebaseDatabase.instance.reference().child('messages');
  final ScrollController _scrollController = ScrollController();



  void _sendMessage(String text) async {
    _textController.clear();
    reference.push().set({
      'text': text,
      'sender': 'User',
    });
    final url =
    Uri.parse("https://api.writesonic.com/v2/business/content/chatsonic?engine=premium&language=ru");
    final headers = {
      "accept": "application/json",
      "content-type": "application/json",
      "X-API-KEY": "f4fdb61d-72bf-498f-92d6-df103e4a9204"
    };
    final payload = {
      "enable_google_results": false,
      "enable_memory": true,
      "input_text": text,
      "history_data": [
        {
          "is_sent": true,
          "message": "Веди себя как семейный психолог и отвечай только на вопросы, которые связанны с этой тематикой, а если вопросы будут не соответствовать теме, то отвечай, что не знаешь ответа на этот вопрос и попроси задать другой вопрос. Также предупреждай пользователя о том, что ты не семейный психолог и не можешь дать ему полноценную консультацию. И отвечай только на русском языке",
        },

      ]
    };
    final response = await http.post(url, headers: headers, body: json.encode(payload));

    var message = utf8.decode(response.bodyBytes);
    var decodedMessage = json.decode(message);
    var text2 = decodedMessage['message'];

    if (response.statusCode == 200) {
      reference.push().set({
        'text': text2,
        'sender': 'Bot',
      });
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }

  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.sender == 'User';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: <Widget>[
        if (!isUser)
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: const CircleAvatar(child: Text('Бот')),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: <Widget>[
              if (!isUser)

                Text('Bot', style: Theme.of(this.context).textTheme.subtitle1),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(this.context).size.width * 0.7,
                ),
                margin: const EdgeInsets.only(top: 5.0),
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: isUser ? Colors.blue : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                    bottomLeft: isUser ? Radius.circular(16.0) : Radius.circular(0.0),
                    bottomRight: isUser ? Radius.circular(0.0) : Radius.circular(16.0),
                  ),
                ),
                child: Text(message.text),
              ),
              if (isUser)
                Text('User', style: Theme.of(this.context).textTheme.subtitle1),
            ],
          ),
        ),
        if (isUser)
          Container(
            margin: const EdgeInsets.only(left: 16.0),
            child: const CircleAvatar(child: Text('User')),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xffE0E3E7),
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
        title: const Text('Chat'),
        ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: FirebaseAnimatedList(
              controller: _scrollController,
              query: reference,
              sort: (DataSnapshot a,DataSnapshot b) => b.key!.compareTo(a.key!),
              reverse: true,
              itemBuilder: (BuildContext context, DataSnapshot snapshot,
                  Animation<double> animation, int index) {

                return _buildMessage(ChatMessage.fromSnapshot(snapshot));
              },
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: Row(
              children: <Widget>[
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      controller: _textController,
                      onSubmitted: _sendMessage,
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Send a message',
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final String sender;

  const ChatMessage({required this.text, required this.sender});

  ChatMessage.fromSnapshot(DataSnapshot snapshot)
      : text = (snapshot.value as Map<dynamic, dynamic>)['text'] ?? '',
        sender = (snapshot.value as Map<dynamic, dynamic>)['sender'] ?? '';

  @override
  Widget build(BuildContext context) {
    final isUser = sender == 'User';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 10.0),
              child: const CircleAvatar(child: Text('Бот')),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                if (!isUser)
                  Text(
                    sender,
                    style: Theme.of(context).textTheme.subtitle1,
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  constraints: const BoxConstraints(maxWidth: 250),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 15.0,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.grey[300] : Colors.blue[200],
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isUser ? Colors.black : Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 10.0),
              child: const CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'sender': sender,
    };
  }
}


// class ChatScreen extends StatefulWidget {
//   const ChatScreen({Key? key}) : super(key: key);
//
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _textController = TextEditingController();
//   final reference = FirebaseDatabase.instance.reference().child('messages');
//
//   void _sendMessage(String text) async {
//     _textController.clear();
//     final url =
//     Uri.parse("https://api.writesonic.com/v2/business/content/chatsonic?engine=premium&language=ru");
//     final headers = {
//       "accept": "application/json",
//       "content-type": "application/json",
//       "X-API-KEY": "f4fdb61d-72bf-498f-92d6-df103e4a9204"
//     };
//     final payload = {
//       "enable_google_results": false,
//       "enable_memory": false,
//       "input_text": text
//     };
//     final response =
//     await http.post(url, headers: headers, body: json.encode(payload));
//
//
//     var message = utf8.decode(response.bodyBytes);
//     var decodedMessage = json.decode(message);
//     var text2 = decodedMessage['message'];
//
//     if (response.statusCode == 200) {
//       reference.push().set({
//         'text': text2,
//         'sender': 'Bot',
//       });
//     }
//   }
//
//   Widget _buildMessage(ChatMessage message) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: <Widget>[
//         Container(
//           margin: const EdgeInsets.only(right: 16.0),
//           child: const CircleAvatar(child: Text('Бот')),
//         ),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             Text('User', style: Theme.of(this.context).textTheme.subtitle1),
//             Container(
//               margin: const EdgeInsets.only(top: 5.0),
//               child: Text(message.text),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chat with Writesonic'),
//       ),
//       body: Column(
//         children: <Widget>[
//           Flexible(
//             child: FirebaseAnimatedList(
//               query: reference,
//               itemBuilder: (BuildContext context, DataSnapshot snapshot,
//                   Animation<double> animation, int index) {
//                 return _buildMessage(ChatMessage.fromSnapshot(snapshot));
//               },
//             ),
//           ),
//           Divider(height: 1.0),
//           Container(
//             decoration: BoxDecoration(color: Theme.of(context).cardColor),
//             child: Row(
//               children: <Widget>[
//                 Flexible(
//                   child: TextField(
//                     controller: _textController,
//                     onSubmitted: _sendMessage,
//                     decoration:
//                     const InputDecoration.collapsed(hintText: 'Send a message'),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: () => _sendMessage(_textController.text),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class ChatMessage {
//   final String text;
//   final String sender;
//
//   ChatMessage({required this.text, required this.sender});
//
//   ChatMessage.fromSnapshot(DataSnapshot snapshot)
//       : text = (snapshot.value as Map<dynamic, dynamic>)['text'] ?? '',
//         sender = (snapshot.value as Map<dynamic, dynamic>)['sender'] ?? '';
//
//   Map<String, dynamic> toJson() {
//     return {
//       'text': text,
//       'sender': sender,
//     };
//   }
// }





class MyContacts extends StatefulWidget {
  const MyContacts({Key? key}) : super(key: key);

  @override
  _MyContactsState createState() => _MyContactsState();
}

class _MyContactsState extends State<MyContacts> with TickerProviderStateMixin {
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
        });
      } else {
        database.ref("Relations/${relat.value.toString()}").update({
          "photo${part.value.toString()}": url,
        });
      }
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
    final snap =
        await ref.child('Relations/${snapshot.value.toString()}/date').get();
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

    if (relat.exists) {
      return relat.value.toString();
    } else {
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
    if (partner.value.toString() == "1") {
      final part = await ref
          .child('Relations/${snapshot.value.toString()}/partner2')
          .get();

      final relat =
          await ref.child("Users/${part.value.toString()}/FcmToken").get();
      return relat.value.toString();
    } else {
      final part = await ref
          .child('Relations/${snapshot.value.toString()}/partner1')
          .get();
      final relat =
          await ref.child("Users/${part.value.toString()}/FcmToken").get();
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
    if (partner.value.toString() == "1") {
      final part = await ref
          .child('Relations/${snapshot.value.toString()}/partner2')
          .get();

      final relat =
          await ref.child("Users/${part.value.toString()}/photo").get();
      print(relat.value.toString());
      return relat.value.toString();
    } else {
      final part = await ref
          .child('Relations/${snapshot.value.toString()}/partner1')
          .get();
      final relat =
          await ref.child("Users/${part.value.toString()}/photo").get();
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
      final relat = await ref
          .child('Relations/${snapshot.value.toString()}/photo2')
          .get();
      if (relat.value.toString() == "null") {
        return 'https://cdn-icons-png.flaticon.com/512/4054/4054617.png';
      } else {
        return relat.value.toString();
      }
    } else {
      final relat = await ref
          .child('Relations/${snapshot.value.toString()}/photo1')
          .get();
      if (relat.value.toString() == "null") {
        return 'https://cdn-icons-png.flaticon.com/512/4054/4054617.png';
      } else {
        return relat.value.toString();
      }
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
          builder:
              (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
            FlutterGifController controllerCry = FlutterGifController(vsync: this);
            FlutterGifController controller18 = FlutterGifController(vsync: this);
            FlutterGifController controllerBell = FlutterGifController(vsync: this);

            controllerBell.value = 1;
            controller18.value = 1;
            controllerCry.value = 1;

            if (snapshot.hasData) {
              return SafeArea(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(0, 20, 0, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                          image: snapshot.data![1].toString(),
                                          fit: BoxFit.cover,
                                          placeholder: kTransparentImage,
                                        ),
                                      )),
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
                                        const EdgeInsetsDirectional.fromSTEB(
                                            0, 10, 0, 0),
                                    child: Container(
                                        width: 45,
                                        height: 45,
                                        child: Image.network(
                                            'https://emojis.wiki/emoji-pics-lf/telegram/heart-on-fire-telegram.gif')),
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
                                      )),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(0, 30, 0, 0),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsetsDirectional
                                              .fromSTEB(0, 10, 0, 0),
                                          child: InkWell(
                                            onTap: () async {},
                                            child: Hero(
                                              tag: 'imageTag',
                                              transitionOnUserGestures: true,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(40),
                                                child:
                                                    FadeInImage.memoryNetwork(
                                                  image: snapshot.data![4]
                                                      .toString(),
                                                  width: 250,
                                                  height: 230,
                                                  fit: BoxFit.cover,
                                                  placeholder:
                                                      kTransparentImage,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
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
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(25, 35, 25, 0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              iconSize: 70,
                              icon: GifImage(
                                controller: controllerBell,
                                image:
                                    const AssetImage('assets/images/bell1.gif'),
                              ),
                              onPressed: () {
                                if (controllerBell.value == 179) {
                                  controllerBell.value = 1;
                                }
                                controllerBell.animateTo(179,
                                    duration:
                                        const Duration(milliseconds: 3600));

                                sendPushMessage(
                                    "Ваш партнер сильно нуждается в вашей помощи",
                                    "СРОЧНАЯ ПОМОЩЬ📣📣📣",
                                    snapshot.data![3].toString());
                              },
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  23, 0, 27, 0),
                              child: IconButton(
                                iconSize: 70,
                                icon: GifImage(
                                  controller: controller18,
                                  image:
                                      const AssetImage('assets/images/18.gif'),
                                ),
                                onPressed: () {
                                  if (controller18.value == 179) {
                                    controller18.value = 1;
                                  }
                                  controller18.animateTo(179,
                                      duration:
                                          const Duration(milliseconds: 3600));

                                  sendPushMessage("оууууу", "🔞🔞🔞🔞",
                                      snapshot.data![3].toString());
                                },
                              ),
                            ),
                            IconButton(
                              iconSize: 65,
                              icon: GifImage(
                                controller: controllerCry,
                                image:
                                    const AssetImage('assets/images/cry.gif'),
                              ),
                              onPressed: () {
                                if (controllerCry.value == 179) {
                                  controllerCry.value = 1;
                                }
                                controllerCry.animateTo(179,
                                    duration:
                                        const Duration(milliseconds: 3600));

                                sendPushMessage(
                                    "Ваш партнер нуждается в поддержке!",
                                    "😭😭😭",
                                    snapshot.data![3].toString());
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ));
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
        backgroundColor: const Color(0xFFE0E3E7),
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
                builder:
                    (BuildContext context, AsyncSnapshot<String> snapshot) {
                  var ref = fb.ref().child('Relations/${snapshot.data}/todos');
                  if (snapshot.hasData) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.792,
                      child: FirebaseAnimatedList(
                        padding: const EdgeInsets.only(top: 20),
                        query: ref,
                        shrinkWrap: true,
                        itemBuilder: (context, snapshot, animation, index) {
                          var v = snapshot.value.toString();
                          g = v.replaceAll(
                              RegExp("{|}|subtitle: |title: "), "");
                          g.trim();
                          l = g.split(',');
                          return GestureDetector(
                            onTap: () {},
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
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
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
                                    padding:
                                        const EdgeInsetsDirectional.fromSTEB(
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
                      ),
                    );
                  } else {
                    return const Center(child: Text(""));
                  }
                }),
          ],
        ));
  }
}

class AppConstants {
  static const String mapBoxAccessToken =
      'pk.eyJ1IjoicmF6ZTExMjciLCJhIjoiY2xkNnU4cGU2MGoxcjN1cWh4ZDNudmcxdiJ9.bIbOHaOGiNnxTpfI_dMWWA';

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
      if (!serviceEnabled) {}
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {}
    }
    locationData = await location.getLocation();
    final ref = FirebaseDatabase.instance.ref();
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final snapshot = await ref.child('Users/$uid/relations').get();
    final relation = await ref.child("Users/$uid/partner").get();
    FirebaseDatabase database = FirebaseDatabase.instance;
    database.ref("Relations/${snapshot.value.toString()}").update({
      "UserLocation${relation.value.toString()}":
          "${locationData.latitude!}()${locationData.longitude!}",
    });
    final relat =
        (await ref.child('Users/$uid/relations').get()).value.toString();
    final partner1 =
        (await ref.child('Relations/$relat/partner1').get()).value.toString();
    final partner2 =
        (await ref.child('Relations/$relat/partner2').get()).value.toString();
    final photo1 =
        (await ref.child('Users/$partner1/photo').get()).value.toString();
    final photo2 =
        (await ref.child('Users/$partner2/photo').get()).value.toString();
    final location1 = (await ref.child('Relations/$relat/UserLocation1').get())
        .value
        .toString();
    final location2 = (await ref.child('Relations/$relat/UserLocation2').get())
        .value
        .toString();
    if (uid == partner1) {
      return "$photo1()$photo2()$location1()$location2";
    } else {
      return "$photo2()$photo1()$location2()$location1";
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
        future: locate(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            List<String> stylist = snapshot.data.toString().split("()");
            final mapController = MapController();

            int calculateDistance(LatLng latLng1, LatLng latLng2) {
              const earthRadius = 6371000; // in meters
              final lat1 = latLng1.latitude;
              final lng1 = latLng1.longitude;
              final lat2 = latLng2.latitude;
              final lng2 = latLng2.longitude;
              final lat1Rad = math.pi * lat1 / 180;
              final lat2Rad = math.pi * lat2 / 180;
              final deltaLatRad = math.pi * (lat2 - lat1) / 180;
              final deltaLngRad = math.pi * (lng2 - lng1) / 180;
              final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
                  math.cos(lat1Rad) * math.cos(lat2Rad) *
                      math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
              final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
              final distance = earthRadius * c/1000;
              return distance.toInt();
            }
            var distance = calculateDistance(LatLng(double.parse(stylist[4]), double.parse(stylist[5])),  LatLng(double.parse(stylist[2]), double.parse(stylist[3])));

            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.black,
                title:  Center(
                  child: Text(
                    "${distance.toString()} km",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,

                    ),
                  ),
                ),
              ),
              floatingActionButton:   FloatingActionButton(
                  onPressed: () {

                    mapController.move(
                        LatLng(double.parse(stylist[4]), double.parse(stylist[5])), mapController.zoom);
                  },
                  backgroundColor: Colors.black,
                  child: Image.network(
                    'https://emojis.wiki/emoji-pics-lf/telegram/heart-on-fire-telegram.gif', width: 35, height: 35,)
              ),
              body: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  minZoom: 5,
                  maxZoom: 18,
                  zoom: 15,
                  center:
                      LatLng(double.parse(stylist[2]), double.parse(stylist[3])),
                ),
                children: [
                  TileLayer(
                    minZoom: 1,
                    urlTemplate:
                        'https://api.mapbox.com/styles/v1/raze1127/cld6ulc88000101s9y81fov5o/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoicmF6ZTExMjciLCJhIjoiY2xkNnU4cGU2MGoxcjN1cWh4ZDNudmcxdiJ9.bIbOHaOGiNnxTpfI_dMWWA',
                    additionalOptions: const {
                      'mapStyleId': AppConstants.mapBoxStyleId,
                      'accessToken': AppConstants.mapBoxAccessToken,
                    },
                  ),
                  MarkerLayer(markers: [
                    Marker(
                        point: LatLng(
                            double.parse(stylist[2]), double.parse(stylist[3])),
                        width: 50,
                        height: 50,
                        builder: (BuildContext context) {
                          if (snapshot.hasData) {
                            return Column(
                              children: <Widget>[
                                Container(
                                    width: 50,
                                    height: 50,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 2,
                                      ),
                                      shape: BoxShape.circle,
                                      color: Colors.black,
                                    ),
                                    child: GestureDetector(
                                        onTap: null,
                                        child: ClipOval(
                                          child: FadeInImage.memoryNetwork(
                                            placeholder: kTransparentImage,
                                            placeholderFit: BoxFit.cover,
                                            fit: BoxFit.cover,
                                            image: stylist[0],
                                          ),
                                        ))),
                              ],
                            );
                          } else {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                        }),
                    Marker(
                        point: LatLng(
                            double.parse(stylist[4]), double.parse(stylist[5])),
                        width: 50,
                        height: 50,
                        builder: (BuildContext context) {
                          if (snapshot.hasData) {
                            return Column(
                              children: <Widget>[
                                Container(
                                    width: 50,
                                    height: 50,
                                    clipBehavior: Clip.antiAlias,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 2,
                                      ),
                                      shape: BoxShape.circle,
                                      color: Colors.black,
                                    ),
                                    child: GestureDetector(
                                        onTap: null,
                                        child: ClipOval(
                                          child: FadeInImage.memoryNetwork(
                                            placeholder: kTransparentImage,
                                            placeholderFit: BoxFit.cover,
                                            fit: BoxFit.cover,
                                            image: stylist[1],
                                          ),
                                        ))),
                              ],
                            );
                          } else {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                        }),
                  ]),
                ],
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
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
                hintStyle:
                const TextStyle(color: Color(0xff4c505b), fontSize: 20),
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
                hintStyle:
                const TextStyle(color: Color(0xff4c505b), fontSize: 15),
              ),
            ),
          ),
          MaterialButton(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
              Navigator.pop(context);
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
