import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:growbot_1/pages/pages.dart';
import 'package:theme_provider/theme_provider.dart';

import '../utils/utils.dart';

class MainPage extends StatefulWidget {
  
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  List<String> devicesList = List<String>.empty(growable: true);
  List<String> modifiedDevicesNamesList = List<String>.empty(growable: true);
  final fbref = FirebaseDatabase.instance.ref();
  final usrEmail = FirebaseAuth.instance.currentUser!.email!.split('@')[0].replaceAll(".", "-");
  final usrEmailComplete = FirebaseAuth.instance.currentUser!.email!;
  int selectedIndex = 0;
  bool buscandoDispositivos = true;
  
  @override
  void initState() {
    super.initState();
    readDevicesListFromFirebase();
  }

  @override
  void dispose(){
    super.dispose();
  }

  void readDevicesListFromFirebase() async{
    
    setState(() => buscandoDispositivos = true);
    devicesList.clear();

    final snapshot = await fbref.child('users/$usrEmail/dispositivos').get();
    if (snapshot.exists) {
        Iterator i = snapshot.children.iterator;
        while(i.moveNext()){
          DataSnapshot data = i.current;
          setState(() =>devicesList.add(data.value.toString()));
        }
    }
    readModifiedDevicesNamesListFromFirebase();

  }

  void readModifiedDevicesNamesListFromFirebase() async{

    modifiedDevicesNamesList.clear();

    if(devicesList.isEmpty){
      return;
    }
    for(int i = 0; i < devicesList.length; i++){
      var snapshot = await fbref.child('users/$usrEmail/nombresPersonalizados/growbots/${devicesList[i]}').get();
      
      if (snapshot.exists) {
        setState(() => modifiedDevicesNamesList.add(snapshot.value.toString()));
      }
    }

    setState(() => buscandoDispositivos = false);
  }

  void cambiarPassword() => Navigator.of(context).pushNamed("CambiarPassword");

  void cerrarSesion() async{
    await FirebaseAuth.instance.signOut();
  }

  void onItemTapped(int index) {
    if(selectedIndex == index){
      return;
    }
    setState(() {
      selectedIndex = index;
    });
    if(index == 0){
      readDevicesListFromFirebase();
    }
  }

  @override
  Widget build(BuildContext context) {

    double smallFontSize = MediaQuery.of(context).size.height / 45;
    double mediumFontSize = MediaQuery.of(context).size.height / 40;
    double bigFontSize = MediaQuery.of(context).size.height / 30;
    double iconSize = MediaQuery.of(context).size.height / 30;
    double bigIconSize = MediaQuery.of(context).size.height / 25;

    return Scaffold(
      appBar: AppBar(
        title: selectedIndex == 0 
        ? Text("Grow Bots", style: GoogleFonts.roboto(fontSize: bigFontSize))
        : Text("Perfil", style: GoogleFonts.roboto(fontSize: bigFontSize)),
        actions: [
          Row(
            children: [
              Icon(Icons.dark_mode, size: iconSize),
              Switch(
                value: ThemeProvider.themeOf(context).id == "my_dark" ? true : false,
                onChanged: (val) {
                  val
                  ? ThemeProvider.controllerOf(context).setTheme('my_dark')
                  : ThemeProvider.controllerOf(context).setTheme('my_light');
                })
            ],
          ),
        ],
      ),
      body: 

      selectedIndex == 0 ?
      (modifiedDevicesNamesList.isEmpty
      ? ( buscandoDispositivos
        ? const Center(child: CircularProgressIndicator())
        : Center(child: Text("No tiene dispositivos asignados.", style: GoogleFonts.roboto(fontSize: mediumFontSize)))
        )
      : SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: Center(
          child:  ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: devicesList.length,
            itemBuilder: ((context, index){
              return Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).size.height/20,
                  right: MediaQuery.of(context).size.width / 10,
                  left: MediaQuery.of(context).size.width / 10
                ),
                child: EditButton(
                  deviceName: devicesList[index],
                  deviceModifiedName: modifiedDevicesNamesList[index],),
              );
            })),
          )
        )
      )
      //CAMBIO DE ÍTEM DE BOTTOM NAVIGATION BAR
      : Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.height / 40),
        child: (Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(child: Text("Email:", style: GoogleFonts.roboto(fontSize: bigFontSize))),
              SizedBox(height: MediaQuery.of(context).size.height / 20),
              Text(usrEmailComplete, style: GoogleFonts.roboto(fontSize: mediumFontSize)),
              SizedBox(height: MediaQuery.of(context).size.height / 30),
              ElevatedButton.icon(
                onPressed: cambiarPassword,
                icon: Icon(Icons.key, size: iconSize),
                label: Text("Cambiar contraseña", style: GoogleFonts.roboto(fontSize: smallFontSize))),
              SizedBox(height: MediaQuery.of(context).size.height / 30),
              ElevatedButton.icon(
                onPressed: cerrarSesion,
                icon: Icon(Icons.logout, size: iconSize),
                label: Text("Cerrar sesión", style: GoogleFonts.roboto(fontSize: smallFontSize))),
            ],)
          )
        ),
      ),
      bottomNavigationBar:
        BottomNavigationBar(items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              size: bigIconSize),
            label: "Inicio"),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              size: bigIconSize),
            label: "Perfil"),
          ],
          currentIndex: selectedIndex,
          onTap:(value) => onItemTapped(value),
        )
   );
  }
}

// ignore: must_be_immutable
class EditButton extends StatefulWidget {
  EditButton({super.key, required this.deviceName, required this.deviceModifiedName});

  String deviceName;
  String deviceModifiedName;

  @override
  State<EditButton> createState() => _EditButtonState();
}

class _EditButtonState extends State<EditButton> {

  bool? _editorVisible;
  String? _deviceModifiedName;

  @override
  initState(){
    super.initState();
    _deviceModifiedName = widget.deviceModifiedName;
  }

  @override
  Widget build(BuildContext context) {

  final usrEmail = FirebaseAuth.instance.currentUser!.email!.split('@')[0];
  double iconSize = MediaQuery.of(context).size.height / 40;
  double smallFontSize = MediaQuery.of(context).size.height / 40;
  TextEditingController controller = TextEditingController();

  void changeDeviceName() async{
    if(controller.text.trim().isEmpty){
      return;
    }
    if(controller.text.trim().length > 25){
      Utils.showErrorSnackBar("El nombre del GrowBot debe tener como máximo 25 caracteres.");
      return;
    }
    final fbref = FirebaseDatabase.instance.ref();
    await fbref.child('users/$usrEmail/nombresPersonalizados/growbots').update(
      {widget.deviceName: controller.text.trim()}
    );
    setState(() {
      _editorVisible = false;
      _deviceModifiedName = controller.text.trim();
    });
  }

    return
    Visibility(
      visible: _editorVisible ?? false,
      replacement: 
        Padding(
          padding: EdgeInsets.only(left: MediaQuery.of(context).size.width / 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:[
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>
                      ThemeConsumer(
                        child: DevicePage(
                          deviceName: widget.deviceName,
                          deviceModifiedName: _deviceModifiedName ?? widget.deviceModifiedName))
                    ));
                }, 
                child: Text(_deviceModifiedName ?? widget.deviceModifiedName, style: GoogleFonts.roboto(fontSize: smallFontSize))
              ),
              IconButton(
                icon: FaIcon(FontAwesomeIcons.solidPenToSquare, size: iconSize),
                onPressed: () => setState(() {
                  _editorVisible = true;
                })
              ),
              SizedBox(width: MediaQuery.of(context).size.width / 25),
            ]
          ),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: ()=> setState(() {
                controller.text = _deviceModifiedName ?? widget.deviceModifiedName;
                _editorVisible = false;
              }), 
              icon: Icon(Icons.cancel, size: iconSize, color: Colors.red)),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: TextFormField(
                controller: controller..text = _deviceModifiedName ?? widget.deviceModifiedName,
                autofocus: true,
                maxLength: 25,
                maxLines: 1,
                onEditingComplete: changeDeviceName
              ),
            ),
            IconButton(onPressed: changeDeviceName,
              icon: Icon(Icons.check_circle, size: iconSize, color: Colors.green.shade600)),
          ],
        ),
    );
  }
}