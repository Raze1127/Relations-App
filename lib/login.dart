import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyLogin extends StatefulWidget {
  const MyLogin({Key? key}) : super(key: key);

  @override
  _MyLoginState createState() => _MyLoginState();
}

class _MyLoginState extends State<MyLogin> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  @override
  void dispose(){
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(children: [
          Container(
            padding: const EdgeInsets.only(left: 35, top: 80),

          ),
          SingleChildScrollView(

            child: Container(

              padding: EdgeInsets.only(
                  right: 35,
                  left: 35,
                  top: MediaQuery.of(context).size.height * 0.2),

              child: Column(children: [
                const Text(
                  "Вход",
                  style: TextStyle(color: Color(0xff4c505b), fontSize: 60),
                ),

                const SizedBox(
                  height: 140,
                ),

                //Image.asset("assets/images/logo2.png"),

                TextField(
                  controller: emailController,
                  cursorColor: const Color(0xff4c505b),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    fillColor: Colors.grey.shade100,
                    filled: true,
                    hintText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xff4c505b)),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 30,
                ),
                TextField(
                  controller: passwordController,
                  cursorColor: const Color(0xff4c505b),
                  textInputAction: TextInputAction.done,
                  obscureText: true,
                  decoration: InputDecoration(
                    fillColor: Colors.grey.shade100,
                    filled: true,
                    hintText: 'Пароль',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xff4c505b)),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [const Text(
                    '',
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
                        onPressed: signIn,
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 50,
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, 'register');
                        },
                        child: const Text(
                          'Регестрация',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontSize: 18,
                            color: Color(0xff4c505b),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance
                              .sendPasswordResetEmail(email: emailController.text.trim());
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Вам на email, который вы ввели в поле выше выслано письмо с ссылкой на восстановление"),));
                        },
                        child: const Text(
                          'Забыли пароль?',
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
          ),
        ]),
      ),
    );

  }
  Future signIn() async{
    await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim()
    );
  }
}