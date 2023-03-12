import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';



 class Themes {

   
  static AppTheme darkTheme({required String id}) {

    /*
    Map<int, Color> misColores = {
    1:const Color.fromARGB(255, 255, 255, 255)
    };
    */
    
    return AppTheme(
      id: id,
      description: "Tema personalizado (Cris).",
      data: ThemeData(

        primarySwatch: Colors.indigo,
        
        primaryColor: Colors.black,

        //colorScheme: const ColorScheme.dark(),

        scaffoldBackgroundColor: Colors.black87,

        indicatorColor: const Color(0xff0E1D36),

        iconTheme: IconThemeData(color: Colors.purple.shade200, opacity: 0.8),

        hintColor: const Color.fromARGB(255, 159, 152, 152),

        highlightColor:  const Color(0xff372901),
        
        hoverColor:  const Color(0xff3A3A3B),

        focusColor: const Color(0xff0B2512),
        
        disabledColor: Colors.grey,
        
        cardColor:  const Color(0xFF151515) ,
        
        canvasColor: Colors.black,
        
        brightness: Brightness.dark,

        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white),
          displayMedium: TextStyle(color: Colors.white),
          displaySmall: TextStyle(color: Colors.white)
        ),
        
        /*buttonTheme: ButtonThemeData(
          colorScheme: 
        )*/
        
        appBarTheme: const AppBarTheme(
          elevation: 0.0,
        ),
      )
    );
  }

  static AppTheme lightTheme({required String id}) {
    return AppTheme(
      id: id,
      description: "Tema personalizado (Cris).",
      data: ThemeData(
        primarySwatch: Colors.red,
        
        primaryColor: Colors.white,

        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.indigo,
        ),
        scaffoldBackgroundColor: Colors.white,

        indicatorColor: const Color(0xffCBDCF8),

        iconTheme: const IconThemeData(color: Colors.black, opacity: 0.8),

        hintColor: const Color.fromARGB(255, 159, 152, 152),

        highlightColor: const Color(0xffFCE192),
        
        hoverColor: const Color(0xff4285F4),

        focusColor:const Color(0xffA8DAB5),
        
        disabledColor: Colors.grey,
        
        cardColor:Colors.white,
        
        canvasColor: Colors.white54,
        
        brightness: Brightness.light,

        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.black),
          displayMedium: TextStyle(color: Colors.black),
          displaySmall: TextStyle(color: Colors.black)
        ),

        //Falta: buttonTheme

        appBarTheme: const AppBarTheme(
          elevation: 0.0,
        ),
      )
    );
  }

}