import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:growbot_1/models/models.dart';
import '../main.dart';
import '../styles/styles.dart';
import '../utils/utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  
  final FirebaseAuth db = FirebaseAuth.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController usrController = TextEditingController();
  TextEditingController passController = TextEditingController();

  @override
  void dispose(){
    super.dispose();
    usrController.dispose();
    passController.dispose();
  }
    
  Future iniciarSesion() async{

    if (! formKey.currentState!.validate()){
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try  {
      await db.signInWithEmailAndPassword(
        email: usrController.text.trim(),
        password: passController.text.trim()
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        Utils.showErrorSnackBar("El email ingresado no se encuentra registrado.");
      } else if (e.code == 'wrong-password') {
        Utils.showErrorSnackBar("Contraseña incorrecta.");
        } else{
          Utils.showErrorSnackBar(e.message);
        }
      }
      
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }


  @override
  Widget build(BuildContext context) {

  final litteSizedBox = MediaQuery.of(context).size.height / 25;
  final mediumSizedBox = MediaQuery.of(context).size.height / 15;
  final bigText = MediaQuery.of(context).size.height / 18;
  final littleText = MediaQuery.of(context).size.height / 45;
  final maxButtonWidth = MediaQuery.of(context).size.width / 3;
  final maxButtonHeight = mediumSizedBox;


    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: MediaQuery.of(context).size.height / 10,
              horizontal: MediaQuery.of(context).size.width / 10
            ),
            decoration: const BoxDecoration(color: Colors.black87),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 5,
                    child: Image.asset(
                      "${imagesRoute}Chala0_trans.png",
                      fit: BoxFit.cover,),
                  ),
                  Font2(
                    text: "Grow Bot",
                    color: Colors.white,
                    size: bigText,),
                  SizedBox(height: mediumSizedBox,),
                  Form(
                    key: formKey,
                    child:
                      Column( children: [
                        Card(
                          child: TextFormField(
                            controller: usrController,
                            autofocus: true,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: "Email",
                              icon: Icon(Icons.person)),
                            validator: (val) {
                              if(!val!.isValidEmail) {
                                return "Email incorrecto.";
                              } else {
                                return null;
                              }}
                          ),
                        ),
                        SizedBox(height: litteSizedBox,),
                        Card(
                          child: TextFormField(
                            controller: passController,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              hintText: "Contraseña",
                              icon: Icon(Icons.key)),
                            validator: (val) {
                              if(passController.text.trim().isEmpty){
                                return "Contraseña incorrecta.";
                              } else {
                                return null;
                              }},
                            onEditingComplete: (() => iniciarSesion()),
                          ),
                        ),
                      ],)
                  ),
                  SizedBox(height: litteSizedBox,),
                  ElevatedButton(
                    onPressed: iniciarSesion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 16, 156, 49),
                      maximumSize: Size(maxButtonWidth, maxButtonHeight),
                     ),
                    child: const Font3(
                      text: "Iniciar sesión",
                      color: Colors.white,)
                  ),
                  SizedBox(height: litteSizedBox,),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed("ResetPassword"),
                    child: Text("¿Olvidaste tu contraseña?",
                      style: GoogleFonts.roboto(
                        fontSize: littleText,
                        fontStyle: FontStyle.italic,
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.double
                      ),))
                ],)
            ),
          ),
        ),
      ),
    );
  }
}