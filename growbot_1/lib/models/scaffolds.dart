import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';
class LoggedInScaffold extends StatelessWidget {
  const LoggedInScaffold({super.key, required this.body, this.lead = false});

  final Widget body;
  final bool lead;



  @override
  Widget build(BuildContext context) {

    final double sizeDefault = MediaQuery.of(context).orientation == Orientation.portrait ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.height ;
    final double leadIconSize = sizeDefault / 9;
    final double customPadding = sizeDefault / 75;
    final User user = FirebaseAuth.instance.currentUser!;


    return Scaffold(
      appBar: AppBar(
        toolbarHeight: leadIconSize * 1.3,
        iconTheme: Theme.of(context).iconTheme,
        automaticallyImplyLeading: false,
        leading: 
          lead ? IconButton(
          icon: Icon(Icons.keyboard_double_arrow_left_sharp, size: leadIconSize/2,),
          onPressed: () => Navigator.of(context).pop(),
          )
          : null,
        leadingWidth: leadIconSize,
        actions: [
          //Botón que cambia de color en modo "splash" al clickearlo:
          /*ClipOval(
            child: Material(
              color: Colors.blue, // Button color
              child: InkWell(
                splashColor: Colors.red, // Splash color
                onTap: () {},
                child: SizedBox(width: 56, height: 56, child: Icon(Icons.menu)),
              ),
            ),
          ),*/
          Padding(
            padding: EdgeInsets.all(customPadding),
            child: ClipOval(
              child: Material(
                child: InkWell(
                  splashColor: Colors.white, // Splash color
                  onTap: () => Navigator.of(context).pushNamed('home'),
                  child: SizedBox(width: leadIconSize, height: leadIconSize, child: const Icon(Icons.favorite))),
                ),
              ),
          ),
          Padding(
            padding: EdgeInsets.all(customPadding),
            child: ClipOval(
              child: Material(
                child: InkWell(
                  splashColor: Colors.white, // Splash color
                  onTap: () => Navigator.of(context).pushNamed('home'),
                  child: SizedBox(width: leadIconSize, height: leadIconSize, child: const Icon(Icons.shopping_cart))),
                ),
              ),
          ),
          Padding(
            padding: EdgeInsets.all(customPadding),
            child: ClipOval(
              child: Material(
                child: InkWell(
                  onTap: () => Navigator.of(context).pushNamed('profile'),
                  child: user.photoURL != null
                  ? Image.network(user.photoURL!, width: leadIconSize, height: leadIconSize, fit: BoxFit.fill,)
                  : Icon(Icons.person, size: leadIconSize),
                  ),
                ),
              ),
          )          
        ],
      ),
      body: body,
   );
  }
}

class LoggedOutScaffold extends StatelessWidget {
  const LoggedOutScaffold({super.key, required this.body, this.lead = false});

  final Widget body;
  final bool lead;


  @override
  Widget build(BuildContext context) {

    final double sizeDefault = MediaQuery.of(context).orientation == Orientation.portrait ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.height ;
    final double leadIconSize = sizeDefault / 9;

    return Scaffold(
      appBar: AppBar(
        iconTheme: Theme.of(context).iconTheme,
        toolbarHeight: leadIconSize * 1.3,
        automaticallyImplyLeading: false,
        leading: 
          lead ? IconButton(
          icon: Icon(Icons.keyboard_double_arrow_left_sharp, size: leadIconSize/2,),
          onPressed: () => Navigator.of(context).pop(),
          )
          : null,
      ),
      body: body,
   );
  }
}

class CustomPersonScaffold extends StatelessWidget {
  const CustomPersonScaffold({super.key, required this.body});

  final Widget body;


  @override
  Widget build(BuildContext context) {

    final double sizeDefault = MediaQuery.of(context).orientation == Orientation.portrait ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.height ;
    final double leadIconSize = sizeDefault / 9;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: leadIconSize * 1.3,
        iconTheme: Theme.of(context).iconTheme,
        leading: IconButton(
          icon: Icon(Icons.keyboard_double_arrow_left_sharp, size: leadIconSize/2,),
          onPressed: () => Navigator.of(context).pop(),
          ),
          leadingWidth: leadIconSize,
        //automaticallyImplyLeading: false,
        actions: [

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.dark_mode),
              Switch(
                value:  ThemeProvider.themeOf(context).id == 'my_dark' ? true : false,
                onChanged:(val){
                  val ?
                  ThemeProvider.controllerOf(context).setTheme('my_dark')
                  :
                  ThemeProvider.controllerOf(context).setTheme('my_light');
                  //ThemeProvider.controllerOf(context).nextTheme();
                  }
                ),
            ],
          )
        ],
      ),
      body: body,
   );
  }
}