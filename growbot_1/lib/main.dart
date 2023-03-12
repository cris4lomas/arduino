
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';
import 'firebase_options.dart';
import 'pages/pages.dart';
import 'utils/utils.dart';

const imagesRoute = 'lib/assets/images/';



void main() async{
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
  /*await FirebaseAppCheck.instance.activate(
    webRecaptchaSiteKey: 'recaptcha-v3-site-key',
    // Default provider for Android is the Play Integrity provider. You can use the "AndroidProvider" enum to choose
    // your preferred provider. Choose from:
    // 1. debug provider
    // 2. safety net provider
    // 3. play integrity provider
    androidProvider: AndroidProvider.debug,
  );*/
  runApp(const App()); 
}

final navigatorKey = GlobalKey<NavigatorState>();
 
class App extends StatefulWidget{

    const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {

  @override
  Widget build(BuildContext context) {

  return ThemeProvider(
    saveThemesOnChange: true,
    onInitCallback: (controller, previouslySavedThemeFuture) async {
    // Do some other task here if you need to
      String? savedTheme = await previouslySavedThemeFuture;
      if (savedTheme != null) {
        controller.setTheme(savedTheme);
      } else {
        controller.setTheme("my_dark");
      }
    },
    themes: <AppTheme>[
      Themes.darkTheme(id: 'my_dark'),
      Themes.lightTheme(id: 'my_light'),
      //AppTheme.light(id: 'my_light'),
      //AppTheme.dark(id: 'my_dark'),
    ],
    child: ThemeConsumer(
      child: Builder(
        builder: (themeContext) {

          return
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeProvider.themeOf(themeContext).data,
            scaffoldMessengerKey: Utils.messengerKey,
            navigatorKey: navigatorKey,
            title: 'Grow Bot',
            home: const PreviousHomePage(),
            initialRoute: '/',
            routes:  <String, WidgetBuilder>{
              // When navigating to the "/second" route, build the SecondScreen widget.  
              'CambiarPassword': (context) => const ThemeConsumer(child: PasswordPage(),), 
              'ResetPassword': (context) => const ThemeConsumer(child: ResetPasswordPage(),), 
              //'verifyEmail': (context) => const ThemeConsumer(child: VerifyEmailPage(),), 
              //'home': (context) => const ThemeConsumer(child: PreviousHomePage(),),
              //'recoverPass': (context) => const ThemeConsumer(child: ForgotPasswordPage(),),
              //'profile': (context) => const ThemeConsumer(child: ProfilePage(),),
              //'gps':(context) => const ThemeConsumer(child: SetupAdressGPSPage(),),
            },  
          );
        })
      )
    );
  }
}


class PreviousHomePage extends StatefulWidget {
  const PreviousHomePage({super.key});

  @override
  State<PreviousHomePage> createState() => _PreviousHomePageState();
}

class _PreviousHomePageState extends State<PreviousHomePage> {

  @override
  Widget build(BuildContext context) {
    
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot){

        if(snapshot.connectionState == ConnectionState.waiting){
          return const Center(child: CircularProgressIndicator(),);
        //} else if(snapshot.hasError){
        //  return const Center(child: Text("Error en el inicio de sesión"),);
        } else if(snapshot.hasData){
          return const MainPage();
        } else {
          return const LoginPage();
        }
      }
    );
  }
}