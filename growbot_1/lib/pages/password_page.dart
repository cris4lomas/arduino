
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:growbot_1/main.dart';
import 'package:growbot_1/models/forms.dart';

import '../utils/utils.dart';

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
    final _formKey = GlobalKey<FormState>();
    bool text1Visible = false;
    bool text2Visible = false;
    String txt1 = "";
    String txt2 = "";
    TextEditingController control1 = TextEditingController();
    TextEditingController control2 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double titleFontSize = MediaQuery.of(context).size.height / 30;
    double textFontSize = MediaQuery.of(context).size.height / 35;
    double iconSize = MediaQuery.of(context).size.height / 30;
    double sizedBoxHeight = MediaQuery.of(context).size.height / 30;
    
    final String usrEmail = FirebaseAuth.instance.currentUser!.email!;


    void cambiarContrasenia() async{

      showDialog(
        context: context,
        builder: (context){
          return const Center(child: CircularProgressIndicator());
        });

      if(_formKey.currentState!.validate()){
        await FirebaseAuth.instance.currentUser!.updatePassword(control1.text).then((value) async{
          await FirebaseAuth.instance.signInWithEmailAndPassword(email: usrEmail, password: control1.text);
        });

        Utils.showSuccessSnackBar("Contraseña cambiada con éxito.");
        control1.clear();
        control2.clear();
        navigatorKey.currentState!.popUntil((route) => route.isFirst);
      } else{
        Navigator.of(context).pop();
        Utils.showErrorSnackBar("Revise las contraseñas ingresadas.");
      }
    }


    return Scaffold(
      appBar: AppBar(
        title: Text("Cambiar contraseña",
        style: GoogleFonts.roboto(fontSize: titleFontSize),),
        leading: IconButton(
          icon: Icon(Icons.keyboard_double_arrow_left,
            size: iconSize
          ),
          onPressed: () => Navigator.of(context).pop(),
          ),
      ),
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                child: TextFormField(
                  controller: control1,
                  obscureText: !text1Visible,
                  textInputAction: TextInputAction.next,
                  maxLength: 20,
                  style: GoogleFonts.roboto(fontSize: textFontSize),
                  decoration: InputDecoration(
                    hintText: "Ingrese la nueva contraseña",
                    suffixIcon: 
                      text1Visible 
                        ? IconButton(icon: const Icon(Icons.remove_red_eye), onPressed: () => setState((){
                          txt1 = control1.text;
                          text1Visible = !text1Visible;
                          })) 
                        : IconButton(icon: const Icon(Icons.remove_red_eye_outlined), onPressed: () => setState((){
                          txt1 = control1.text;
                          text1Visible = !text1Visible;
                        }))
                  ),
                  validator: (value) {
                    String txt = value.toString().trim(); 
                    if(isPasswordValid(txt)) {
                      return null;
                    }
                    else if(txt.length < 8){
                      return "La contraseña debe contener al menos 8 caracteres";
                    }
                    else if(txt.length > 20){
                      return "La contraseña debe contener como máximo 20 caracteres";
                    }
                    else {
                      return "La contraseña debe contener al menos 1 minúscula, \n1 mayúscula y 1 número.";
                    }
                  },
                ),
              ),
              SizedBox(height: sizedBoxHeight),
              Card(
                child: TextFormField(
                  controller: control2,
                  obscureText: !text2Visible,
                  textInputAction: TextInputAction.done,
                  maxLength: 20,
                  onEditingComplete: cambiarContrasenia,
                  style: GoogleFonts.roboto(fontSize: textFontSize),
                  decoration: InputDecoration(
                    hintText: "Repita la contraseña",
                    suffixIcon: 
                      text2Visible 
                        ? IconButton(icon: const Icon(Icons.remove_red_eye), onPressed: () => setState((){
                          txt2 = control2.text;
                          text2Visible = !text2Visible;
                          control2.text = txt2;
                          })) 
                        : IconButton(icon: const Icon(Icons.remove_red_eye_outlined), onPressed: () => setState((){
                          txt2 = control2.text;
                          text2Visible = !text2Visible;
                          control2.text = txt2;
                        }))
                  ),
                  validator: (value) {
                    String txt = value.toString().trim(); 
                    if(txt != control1.text){
                      return "Las contraseñas no coinciden.";
                    } else{
                      return null;
                    }
                  },
                ),
              ),
              SizedBox(height: sizedBoxHeight),
              ElevatedButton(
                onPressed: cambiarContrasenia,
                child: Text("Aceptar",
                style: GoogleFonts.roboto(fontSize: textFontSize),))
            ],
          ),
        ),)
    );
  }
}