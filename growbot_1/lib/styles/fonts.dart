
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//Títulos

class Font1 extends StatelessWidget{
  
  final String text;
  final Color color;
  final double size;
  final TextOverflow overflow;
  final FontWeight weight;

  const Font1({Key? key, required this.text, this.color = const Color.fromARGB(255, 10, 10, 10), this.size = 0, this.overflow=TextOverflow.ellipsis, this.weight = FontWeight.w600}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1, //máxima cantidad de lineas. si la supera, irá a overflow
      overflow: overflow,
      style:
      //Usamos google fonts: 
      GoogleFonts.pacifico(
        //color: color,
        fontSize: size == 0 ? MediaQuery.of(context).size.height / 20 : size,
        fontWeight: weight,
        decoration: TextDecoration.underline,
        decorationStyle: TextDecorationStyle.double,
        //decorationColor: Colors.black
      )
    );
  }
}


class Font2 extends StatelessWidget{
  
  final String text;
  final Color color;
  final double size;
  final FontWeight weight;
  final double height; //altura entre líneas
  
  const Font2({Key? key, required this.text, this.color = const Color.fromARGB(255, 36, 36, 36), this.size = 0, this.weight = FontWeight.w400, this.height=1.2}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:
      GoogleFonts.oswald(
        color: color,
        fontSize: size == 0 ? MediaQuery.of(context).size.height / 25 :size,
        height: 0,
        fontWeight: weight)
    );
  }

}

class Font3 extends StatelessWidget{
  
  final String text;
  final Color color;
  final double size;
  final FontWeight weight;
  final double height; //altura entre líneas
  
  const Font3({Key? key, required this.text, this.color = const Color.fromARGB(255, 36, 36, 36), this.size = 0, this.weight = FontWeight.w400, this.height=1.2}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:
      GoogleFonts.lobster(
        //color: color,
        fontSize: size == 0 ? MediaQuery.of(context).size.height / 40 : size,
        fontWeight: weight)
    );
  }

}

class SnackBarFont extends StatelessWidget{
  
  final String text;
  final Color color;
  final double size;
  final FontWeight weight;
  final double height; //altura entre líneas
  
  const SnackBarFont({Key? key, required this.text, this.color = const Color.fromARGB(255, 255, 255, 255), this.size = 0, this.weight = FontWeight.w400, this.height=1.2}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style:
      GoogleFonts.poppins(
        color: color,
        fontSize: size == 0 ? MediaQuery.of(context).size.height / 45 :size,
        fontWeight: weight)
    );
  }

}