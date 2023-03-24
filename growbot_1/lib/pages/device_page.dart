import 'dart:async';
import 'dart:core';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:growbot_1/pages/pages.dart';
import 'package:theme_provider/theme_provider.dart';
import '../models/models.dart';
import '../utils/utils.dart';

// ignore: must_be_immutable
class DevicePage extends StatefulWidget {
  
  DevicePage({super.key, required this.deviceModifiedName, required this.deviceName});

  final String deviceName;
  String deviceModifiedName;
  final usrEmail = FirebaseAuth.instance.currentUser!.email!.split('@')[0].replaceAll(".", "-");

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {

  final fbref = FirebaseDatabase.instance.ref();
  final Device device = Device();
  bool textEditorVisibility = false;
  List<BluetoothDevice> devices =List<BluetoothDevice>.empty(growable: true);
  StreamSubscription<DatabaseEvent>? deviceListener;
  StreamSubscription<DatabaseEvent>? releNamesListener;
  StreamSubscription<DatabaseEvent>? releListener;
  List<String> releList = List<String>.empty(growable: true);
  List<String> releNamesList = List<String>.empty(growable: true);
  List<String> releStatesList = List<String>.empty(growable: true);
  bool leyendoReles = true;

  @override
  void initState() {
    super.initState();
    getDeviceInfo();
    getReleInfo();
    startListeners();
  }

  @override
  void dispose(){
    super.dispose();
    deviceListener?.cancel();
    releNamesListener?.cancel();
    releListener?.cancel();
  }

  void startListeners(){

    DatabaseReference deviceDatabase =
      FirebaseDatabase.instance.ref('dispositivos/${widget.deviceName}/SENSORES');
    deviceListener = deviceDatabase.onValue.listen((DatabaseEvent event) {
      //final data = event.snapshot.value;
      getDeviceInfo();
    });

    DatabaseReference releNamesDatabase =
      FirebaseDatabase.instance.ref('users/${widget.usrEmail}/nombresPersonalizados/reles');
    releNamesListener = releNamesDatabase.onValue.listen((DatabaseEvent event) {
      //final data = event.snapshot.value;
      getReleInfo();
    });

    DatabaseReference rele1Database =
      FirebaseDatabase.instance.ref('dispositivos/${widget.deviceName}/RELES');
    releListener = rele1Database.onValue.listen((DatabaseEvent event) {
      getReleInfo();
    });

  }

  void getDeviceInfo() async{

    final humedad = await fbref.child('dispositivos/${widget.deviceName}/SENSORES/HUMEDAD').get();
    final temperatura = await fbref.child('dispositivos/${widget.deviceName}/SENSORES/TEMPERATURA').get();
    final suelo = await fbref.child('dispositivos/${widget.deviceName}/SENSORES/SUELO').get();
    setState(() {
      if(humedad.exists){
        device.humedad = humedad.value.toString();
      }
      if(temperatura.exists){
        device.temperatura = temperatura.value.toString();
      }
      if(suelo.exists){
        device.suelo = suelo.value.toString();
      }
    });
  }

  void getReleInfo() async{

    setState(() {
      leyendoReles = true;
    });

    final rele1 = await fbref.child('dispositivos/${widget.deviceName}/RELES/RELE1').get();
    final rele2 = await fbref.child('dispositivos/${widget.deviceName}/RELES/RELE2').get();
    final rele3 = await fbref.child('dispositivos/${widget.deviceName}/RELES/RELE3').get();
    final rele4 = await fbref.child('dispositivos/${widget.deviceName}/RELES/RELE4').get();
    
    releStatesList.clear();
    releStatesList.add(rele1.value.toString());
    releStatesList.add(rele2.value.toString());
    releStatesList.add(rele3.value.toString());
    releStatesList.add(rele4.value.toString());

    var snapshot = await fbref.child('users/${widget.usrEmail}/nombresPersonalizados/reles').get();
    var iterator = snapshot.children.iterator;
    
    setState(() {
      releList.clear();
      releNamesList.clear();
    });

    while(iterator.moveNext()){
      setState(() {
        releList.add(iterator.current.key.toString());
        releNamesList.add(iterator.current.value.toString());
      });
    }

    setState(() {
      leyendoReles = false;
    });
    
  }

  void connectToBt() async{

    bool isEnabled;
    bool hasDevice = false;
    int deviceIndex = -1;

    await FlutterBluetoothSerial.instance.isEnabled;
    await FlutterBluetoothSerial.instance.requestEnable();
    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      });
    isEnabled = (await FlutterBluetoothSerial.instance.isEnabled) ?? false;
    if(!isEnabled){
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
      Utils.showErrorSnackBar("Se ha cancelado la solicitud.");
      return;
    }

    devices = List<BluetoothDevice>.empty(growable: true);

    FlutterBluetoothSerial.instance.startDiscovery().listen((r) async{
      final existingIndex = devices.indexWhere(
            (element) => element.address == r.device.address);
        if (existingIndex >= 0){
          devices[existingIndex] = r.device;
        }
        else{
          devices.add(r.device);
        }
        }).onDone(() async {
          var i = devices.iterator;
          hasDevice = false;
          while(i.moveNext()){
            var device = i.current;
            if(device.name == "GrowBot ${widget.deviceName}"){
              hasDevice = true;
              deviceIndex = devices.indexOf(device);
              break;
            }
          }
          if(hasDevice){
            Navigator.of(context).pop();
            BluetoothConnection connection = await BluetoothConnection.toAddress(devices[deviceIndex].address);
            if(connection.isConnected){
              // ignore: use_build_context_synchronously
              _startChat(context, devices[deviceIndex], connection);
            }
            else{
              // ignore: use_build_context_synchronously
              Utils.showErrorSnackBar("No se pudo conectar al dispositivo mediante bluetooth. Asegúrese de estar cerca y de haberlo emparejado previamente.");
            }}
          });
          
          
  }

  void _startChat(BuildContext context, BluetoothDevice server, BluetoothConnection connection) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return BluetoothPage(server: server, deviceName: widget.deviceName, connection: connection,);
        },
      ),
    );
  }

  double conocerHumedad(String dato){
    try{
      int valor = (int.parse(dato) - 1300).abs();
      if(valor < 0){
        valor = 0;
      } else if(valor > 1000){
        valor = 1000;
      }
      double result = valor.toDouble() / 10.00;

      return result;
    } on Exception{
      return 0.00;
    }

  }

  @override
  Widget build(BuildContext context) {

    double titleFontSize = MediaQuery.of(context).size.height / 30;
    double smallFontSize = MediaQuery.of(context).size.height / 45;
    double iconSize = MediaQuery.of(context).size.height / 30;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deviceModifiedName,
        style: GoogleFonts.roboto(fontSize: titleFontSize),),
        leading: IconButton(
          icon: Icon(Icons.keyboard_double_arrow_left,
            size: iconSize
          ),
          onPressed: () => Navigator.of(context).pop(),
          ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.height / 45),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height / 40,),
                ElevatedButton.icon(
                  icon:  Icon(Icons.bluetooth, size: iconSize),
                  onPressed: connectToBt,
                  label:
                    Text("Cambiar datos del WIFI del GrowBot **",
                      style: GoogleFonts.roboto(fontSize: smallFontSize))),
                SizedBox(height: MediaQuery.of(context).size.height / 45),
                Text("** Para cambiar los datos del wifi, es necesario tener encendido el bluetooth y haber emparejado previamente este dispositivo con el GrowBot.",
                style: GoogleFonts.roboto(
                  fontSize: smallFontSize
                )),
                SizedBox(height: MediaQuery.of(context).size.height / 40),

                Container(
                  margin: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.height / 45,),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey),
                      top: BorderSide(color: Colors.grey)
                      )
                    ),
                  child: Text("Sensores",
                    style: GoogleFonts.anton(fontSize: titleFontSize)),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 25),
                  child: Column(
                    children: [
                      IconText(
                        icon: Icons.sunny,
                        iconColor: Colors.orange,
                        fixedText: "ºTemperatura ambiente :",
                        dynamicText: device.temperatura,
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height / 40),
                      IconText(
                        icon: Icons.water_drop_rounded,
                        iconColor: Colors.lightBlue,
                        fixedText: "% Hum. de ambiente       :",
                        dynamicText: device.humedad,
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height / 40),
                      IconText(
                        faIcon: FontAwesomeIcons.pagelines,
                        iconColor: Colors.green.shade800,
                        fixedText: " % Humedad de suelo     :",
                        dynamicText: "% ${conocerHumedad(device.suelo)}",
                      ),
                    ],)
                ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.height / 45),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey),
                      top: BorderSide(color: Colors.grey)
                      )
                    ),
                  child: Text("Relés",
                    style: GoogleFonts.anton(fontSize: titleFontSize)),
                ),
                Text("Si los pulsás los podés programar!",
                style: GoogleFonts.roboto(
                  fontSize: smallFontSize
                )),
                SizedBox(height: MediaQuery.of(context).size.height / 40),
                leyendoReles
                ? const Center(child: CircularProgressIndicator(),)
                : (
                  releNamesList.isEmpty
                  ? Center(child: 
                    Text("No hay Relés disponibles...",
                      style: GoogleFonts.roboto(
                        fontSize: smallFontSize
                      )),
                  )
                  : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: releNamesList.length,
                          itemBuilder: ((context, index) {
                            return ReleButton(
                              deviceName: widget.deviceName,
                              rele: releList[index],
                              releName: releNamesList[index],
                              isOn: releStatesList[index],
                              afterCallBack: getReleInfo 
                              );
                          })),
                      ],
                    ),
                  )
                )
              ]),
          ),),
      )
    );
  }
}

class IconText extends StatelessWidget {
  const IconText({super.key, this.icon, this.faIcon, required this.iconColor, required this.fixedText, required this.dynamicText});

  final IconData? icon;
  final IconData? faIcon;
  final Color iconColor;
  final String fixedText;
  final String? dynamicText;


  @override
  Widget build(BuildContext context) {
    double iconSize = MediaQuery.of(context).size.height / 30;
    double mediumFontSize = MediaQuery.of(context).size.height / 40;
    double spaceBetweenIconAndText = MediaQuery.of(context).size.width / 40;
    double containerWidth = MediaQuery.of(context).size.width * 1/10;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        icon != null
        ? SizedBox(
            width: containerWidth,
            child: Icon(icon,
              size: iconSize,
              color: iconColor
            ),
          )
        : Container(
            alignment: Alignment.center,
            width: containerWidth,
            child: FaIcon(faIcon,
              size: iconSize,
              color: iconColor
            ),
          ),
        SizedBox(width: spaceBetweenIconAndText),
        SizedBox(
          width:containerWidth * 5,
          child: 
            Text(fixedText,
              style: GoogleFonts.roboto(fontSize: mediumFontSize)
            ),
        ),
        const Expanded(child: SizedBox(),),
        Text(dynamicText ?? "N/D",
        textAlign: TextAlign.end,
        style: GoogleFonts.roboto(fontSize: mediumFontSize)),
      ],
    );
  }
}

// ignore: must_be_immutable
class ReleButton extends StatefulWidget {
  ReleButton({super.key, required this.deviceName, required this.rele, required this.releName, required this.isOn, this.afterCallBack});

  final String deviceName;
  final String rele;
  final String releName;
  String isOn;
  final Function()? afterCallBack;

  @override
  State<ReleButton> createState() => _ReleButtonState();
}

class _ReleButtonState extends State<ReleButton> {

  bool? _editorVisible;
  bool? isOn;
  String? _releModifiedName;
  TextEditingController controller = TextEditingController();
  final usrEmail = FirebaseAuth.instance.currentUser!.email!.split('@')[0];

  @override
  initState(){
    super.initState();
    knowInitReleState();
  }

  void knowInitReleState() => setState( () =>isOn = widget.isOn == "true" ? true : false);

  void changeReleName() async{
    if(_releModifiedName == controller.text.trim() ||
    controller.text.trim().isEmpty){
      setState(() {
        _editorVisible = false;
      });
      return;
    }
    if(controller.text.length > 25){
      Utils.showErrorSnackBar("El nombre del relé no puede superar los 25 caracteres...");
      setState(() {
        _editorVisible = false;
      });
      return;
    }
    setState(() {
      _releModifiedName == controller.text.trim();
      _editorVisible = false;
    });

    final fbref = FirebaseDatabase.instance.ref();
    await fbref.child('users/$usrEmail/nombresPersonalizados/reles').update(
      {widget.rele: controller.text.trim()}
    );
    
  }

  @override
  Widget build(BuildContext context) {

  double iconSize = MediaQuery.of(context).size.height / 35;
  double mediumFontSize = MediaQuery.of(context).size.height / 35;
  Color primaryColor = ThemeProvider.themeOf(context).id == 'my_dark' ? Colors.white : Colors.black87;
  Color shadowColor = isOn != null ? (isOn! ? Colors.green : Colors.red) : Colors.red;

    return
    Visibility(
      visible: _editorVisible ?? false,
      replacement: 
        Padding(
          padding: EdgeInsets.only(left: MediaQuery.of(context).size.width / 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:[
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>
                      ThemeConsumer(
                        child: RelePage(
                          deviceName: widget.deviceName,
                          rele: widget.rele,
                          releName: widget.releName))
                    ));
                }, 
                child:
                  Container(
                    padding: EdgeInsets.all(MediaQuery.of(context).size.height / 100),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      boxShadow:[
                        for(double i = 1; i < 5; i++)
                          BoxShadow(
                            spreadRadius: -1,
                            color: shadowColor,
                            blurRadius: 3 * i,
                            blurStyle: BlurStyle.outer,
                          ),
                      ]),
                    child: Text(widget.releName,
                      style: GoogleFonts.roboto(
                        fontSize: mediumFontSize,
                        color: primaryColor,
                        shadows: [
                          Shadow(
                            color: shadowColor,
                            blurRadius: 3
                          ),
                          Shadow(
                            color: shadowColor,
                            blurRadius: 6
                          ),
                          Shadow(
                            color: shadowColor,
                            blurRadius: 9
                          ),
                          Shadow(
                            color: shadowColor,
                            blurRadius: 12
                          ),
                        ]
                        )
                      ),
                  )
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: ()=> setState(() {
                controller.text = _releModifiedName ?? widget.releName;
                _editorVisible = false;
              }), 
              icon: Icon(Icons.cancel, size: iconSize, color: Colors.red)),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: TextFormField(
                controller: controller..text = _releModifiedName ?? widget.releName,
                autofocus: true,
                maxLength: 25,
                maxLines: 1,
                onEditingComplete: changeReleName,
              ),
            ),
            IconButton(
              onPressed: changeReleName,
              icon: Icon(Icons.check_circle, size: iconSize, color: Colors.green.shade600)),
          ],
        ),
    );
  }
}