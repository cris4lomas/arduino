
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../main.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
    final _formKey = GlobalKey<FormState>();
    TextEditingController control1 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double titleFontSize = MediaQuery.of(context).size.height / 30;
    double textFontSize = MediaQuery.of(context).size.height / 35;
    double iconSize = MediaQuery.of(context).size.height / 30;
    double sizedBoxHeight = MediaQuery.of(context).size.height / 30;


    void resetearContrasenia() async{

      String email = control1.text.trim();
      
      showDialog(
        context: context,
        builder: (context){
          return const Center(child: CircularProgressIndicator());
        });

      if(_formKey.currentState!.validate()){
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

        Utils.showSuccessSnackBar("Email enviado con éxito.\nNo olvide revisar su bandeja de spam.");
        navigatorKey.currentState!.popUntil((route) => route.isFirst);
      } else{
        Navigator.of(context).pop();
        Utils.showErrorSnackBar("Ha ocurrido un error. Verifique su conexión a internet.");
      }
    }


    return Scaffold(
      appBar: AppBar(
        title: Text("Resetear contraseña",
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
                  textInputAction: TextInputAction.done,
                  maxLength: 45,
                  style: GoogleFonts.roboto(fontSize: textFontSize),
                  decoration: const InputDecoration(
                    hintText: "Ingrese su mail"
                  ),
                  validator: (value) {
                    String txt = value.toString().trim(); 
                    if((txt.isValidEmail)) {
                      return null;
                    }
                    else
                    {
                      return "Email no válido.";
                    }
                  },
                ),
              ),
              SizedBox(height: sizedBoxHeight),
              ElevatedButton(
                onPressed: resetearContrasenia,
                child: Text("Enviar email",
                style: GoogleFonts.roboto(fontSize: textFontSize),))
            ],
          ),
        ),)
    );
  }
}