import 'package:flutter/material.dart';
import '../styles/styles.dart';


class Utils {

  static GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();
  
  
  static showErrorSnackBar(String? text){
    
    if(text?.trim() == null) return;


    final snackBar = SnackBar(content: SnackBarFont(text: text!), backgroundColor: const Color.fromARGB(255, 129, 19, 19),);

    messengerKey.currentState!
      ..removeCurrentSnackBar()
      ..showSnackBar(snackBar);
    
    }

    static showSuccessSnackBar(String? text){
    
    if(text?.trim() == null) return;


    final snackBar = SnackBar(content: SnackBarFont(text: text!), backgroundColor: const Color.fromARGB(255, 3, 132, 57),);

    messengerKey.currentState!
      ..removeCurrentSnackBar()
      ..showSnackBar(snackBar);
    
    }
}