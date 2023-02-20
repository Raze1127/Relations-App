import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'HomePage.dart';
import 'creationRelations.dart';
import 'firebase_options.dart';
import 'loading.dart';
import 'login.dart';
import 'register.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: 'main',
        theme: ThemeData(
          fontFamily: 'FiraSans',
        ),
        routes: {

          'main': (context) => const mainPage(),
          'login': (context) => const MyLogin(),
          'register': (context) => const MyRegister(),
          'home': (context) => const HomePage(),
          'creation': (context) => const CreationRelation(),
        },
  )
  );

}

class mainPage extends StatelessWidget{
  const mainPage({Key? key}) : super(key: key);

  Future<String> GetStatee() async {
    final ref = FirebaseDatabase.instance.ref();
    final User? user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final relat = await ref.child('Users/$uid/IsReady').get();
    return relat.value.toString();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body:
    StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return FutureBuilder(
            future: GetStatee(),
            builder: (context, snapshot1) {
              if (snapshot1.hasData ) {
                final value = snapshot1.data;
                if (value == "Yes") {
                  return const HomePage();
                } else {
                  return const CreationRelation();
                }
              } else {
                return const MyLoading();
              }
            },
          );
        } else {
          return const MyLogin();
        }
      },
    ),

  );
}

