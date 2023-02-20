
import 'package:flutter/material.dart';

class MyLoading extends StatefulWidget {
  const MyLoading({Key? key}) : super(key: key);

  @override
  _MyLoadingState createState() => _MyLoadingState();
}

class _MyLoadingState extends State<MyLoading> {



  @override
  Widget build(BuildContext context) {
    print("ПРИВЕЕт");
   return Center(
     child: Image.asset('assets/images/logo.png',
     width: 50,
     height: 50,
     ),
   );


  }
}