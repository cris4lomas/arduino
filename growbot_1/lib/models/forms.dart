import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../styles/styles.dart';


class CustomFormField extends StatelessWidget {
  const CustomFormField({

    Key? key,
    required this.hintText,
    required this.control,
    required this.icon,
    required this.color,
    this.obscure = false,
    this.inputFormatters,
    this.validator,
    this.focus,

  }) : super(key: key);

  final String hintText;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextEditingController control;
  final FocusNode? focus;
  final IconData icon;
  final Color color;
  final bool obscure;

  
  
  @override
  Widget build(BuildContext context) {

    final double scHeight = MediaQuery.of(context).size.height;
    final double scWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        style: GoogleFonts.signika(
          color: Colors.black
        ),
        inputFormatters: inputFormatters,
        focusNode: focus,
        obscureText: obscure,
        controller: control,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            icon,
            color: color
          ),
          constraints: BoxConstraints(
            minWidth: scWidth /2,
            maxWidth: scWidth * 8/10,
            maxHeight: scHeight / 10, 
          ),
          filled: true,
          fillColor: MyColors.icon1,
        ),
        
      )
    );
  }
}

extension ExtString on String {
  bool get isValidEmail {
    final emailRegExp = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    return emailRegExp.hasMatch(this);
  }

  bool get isValidName{
    final nameRegExp = RegExp(r"^\s*([A-Za-z]{1,}([\.,] |[-']| ))+[A-Za-z]+\.?\s*$");
    return nameRegExp.hasMatch(this);
  }

  bool get isValidPassword{
final passwordRegExp = 
    RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\><*~-]).{8,}/pre>');
    return passwordRegExp.hasMatch(this);
  }

  bool get isNotNull{
    // ignore: unnecessary_null_comparison
    return this != null;
}

  bool get isValidPhone{
    final phoneRegExp = RegExp(r"^\+?0[0-9]{10}$");
    return phoneRegExp.hasMatch(this);
  }

}

 bool isPasswordValid(String password, [int minLenght = 8, int maxLenght = 20]) {

    if (password.length < minLenght) return false;
    if (password.length > maxLenght) return false;
    
    if (!password.contains(RegExp(r"[a-z]"))) return false;
    if (!password.contains(RegExp(r"[A-Z]"))) return false;
    if (!password.contains(RegExp(r"[0-9]"))) return false;
    //if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>-_]'))) return false;
    return true;
  }