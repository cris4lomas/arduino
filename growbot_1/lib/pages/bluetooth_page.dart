import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../utils/utils.dart';

// ignore: must_be_immutable
class BluetoothPage extends StatefulWidget {
  BluetoothPage({super.key, required this.server, required this.deviceName, this.connection});

  final BluetoothDevice server;
  final String deviceName;
  BluetoothConnection? connection;
  final usrEmail = FirebaseAuth.instance.currentUser!.email!.split('@')[0].replaceAll(".", "-");

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  
  DatabaseReference? fbRef;
  TextEditingController ssidController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController usrPassController = TextEditingController();
  String? ssid;
  String? pass;
  final int triesMax = 3;
  int triesDone = 0;
  StreamSubscription<DatabaseEvent>? listener;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final usrEmailComplete = FirebaseAuth.instance.currentUser!.email!.trim();

  @override
  void initState() {
    setState(() {
      fbRef = FirebaseDatabase.instance.ref("users/${widget.usrEmail}/wifi");
    });
    getSsidAndPass();
    startListener();
    super.initState();
    triesDone = 0;
  }

  @override
  void dispose(){
    widget.connection!.finish();
    triesDone = 0;
    super.dispose();
    listener?.cancel();
  }

  void startListener() {
    DatabaseReference firebaseListener =
      FirebaseDatabase.instance.ref('dispositivos/${widget.deviceName}/CONEXION');
    listener = firebaseListener.onValue.listen((DatabaseEvent event) {
      if(event.snapshot.value == true){
        DateTime fecha = DateTime.now();
        //debería ser  setTime(8,29,0,1,1,11); // set time to Saturday 8:29:00am Jan 1 2011
        String fechaFormateada = "${fecha.hour} ${fecha.minute} ${fecha.second} ${fecha.month} ${fecha.day} ${fecha.year}";
        FirebaseDatabase.instance.ref('dispositivos/${widget.deviceName}').update({'CONEXION': false});
        FirebaseDatabase.instance.ref('dispositivos/${widget.deviceName}').update({'FECHA': fechaFormateada});
        FirebaseDatabase.instance.ref().child('dispositivos/${widget.deviceName}').update({"INFONUEVA": false});
        Utils.showSuccessSnackBar("Conexión exitosa!");
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    });
  }

  void getSsidAndPass() async{
    var data = await fbRef?.get();

    if(data!.exists){
      setState(() {
        ssid = data.child("ssid").value.toString();
        pass = data.child("pass").value.toString();
      });
    }
  }

  void setNewData(String data) async{
    if(data == "ssid") {
      await fbRef?.update({data: ssid});
    }
    if(data == "pass"){
      await fbRef?.update({data: pass});
    }
  }

  void setNewPassword() => setNewData("pass");
  void setNewSsid() => setNewData("ssid");

  void connectGrowBotToWifi() async{

    if(!formKey.currentState!.validate()){
      return;
    }

    showDialog(
      context: context,
      builder: (context){
        return const Center(child: CircularProgressIndicator(),);
    });

    while(triesDone < triesMax){
      triesDone++;
      if(widget.connection!.isConnected){
        connectToWifi();
        triesDone = 0;
        break;
      } else{
        widget.connection = await BluetoothConnection.toAddress(widget.server.address);
        connectGrowBotToWifi();
      }
    }
    
    if(triesDone >= triesMax){
      Utils.showErrorSnackBar("Se ha desconectado el dispositivo bluetooth y la operación no se pudo realizar. Asegúrese de estar cerca del GrowBot e intente nuevamente.");
    }
  }

    void connectToWifi() async {

      String usrPass = usrPassController.text.trim();

      String msg = "$ssid\r\n$pass\r\n$usrEmailComplete\r\n$usrPass\r\n";

      try {
        widget.connection!.output.add(Uint8List.fromList(utf8.encode(msg)));
        await widget.connection!.output.allSent;

        Utils.showSuccessSnackBar("Aguarde un momento... si los datos son correctos, pronto se conectará.");
      } catch (e) {
        // Ignore error, but notify state
        Utils.showErrorSnackBar("Ha habido un error al enviar los datos del wifi. Código: ${e.toString()}");
      }
    }


  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.server.name.toString()),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Nombre de red:"),
                    TextFormField(
                      controller: ssidController..text = ssid?? "",
                      textInputAction: TextInputAction.next,
                      onEditingComplete: (){
                        ssid = ssidController.text.trim();
                        setNewSsid();
                      },
                      validator: (value) {
                        if(value == null){
                          return "Debe ingresar un valor";
                        } else{
                          return null;
                        }
                      },
                    ),
                    const SizedBox(height:25),
                    const Text("Contraseña del WiFi:"),
                    TextFormField(
                      controller: passController..text = pass?? "",
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () {
                        pass = passController.text.trim();
                        setNewPassword();
                      },
                      validator: (value) {
                        if(value == null){
                          return "Debe ingresar un valor";
                        } else{
                          return null;
                        }
                      },
                    ),
                    const SizedBox(height:25),
                    const Text("Su contraseña:"),
                    TextFormField(
                      controller: usrPassController,
                      decoration: const InputDecoration(
                        hintText: "Ingrese su contraseña"
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onEditingComplete: connectGrowBotToWifi,
                      validator: (value) {
                        if(value == null){
                          return "Debe ingresar su contraseña";
                        } else{
                          if(value.trim().length < 6){
                            return "Contraseña incorrecta";
                          } else{
                            return null;
                          }
                        }
                      },
                    ),
                    ElevatedButton(
                      onPressed: connectGrowBotToWifi, 
                      child: const Text("Conectar GrowBot a WiFi"))
                  ],
                ),
              ),
            ),
          ),),
      )
    );
  }
}


/*
****************************************
RECIBIR DATOS POR BLUETOOTH
****************************************
  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }
*/