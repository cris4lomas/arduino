import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:theme_provider/theme_provider.dart';
import '../utils/utils.dart';

class RelePage extends StatefulWidget {
  const RelePage({super.key, required this.deviceName, required this.rele, required this.releName});

  final String deviceName;
  final String rele;
  final String releName;

  @override
  State<RelePage> createState() => _RelePageState();
}

class _RelePageState extends State<RelePage> {
  bool? isOn;
  TypeOfRele? tipo;
  StreamSubscription<DatabaseEvent>? releListener;
  int? _index;
  int? _indexPrevioAGuardar;
  bool? porTiempoHab;
  bool? porSensorHab;
  bool? hasData;
  bool? hasModifiedData;
  bool? manualOn;
  int? inicio;
  int? minutos;
  int? fin;
  
  final _formKeyTiempo = GlobalKey<FormState>();
  final _formKeyHumedad = GlobalKey<FormState>();
  final _formKeySuelo = GlobalKey<FormState>();
  final _formKeyTemperatura = GlobalKey<FormState>();

  final controlHoras = TextEditingController();
  final controlMinutos = TextEditingController();
  final controlHorasEncendido = TextEditingController();
  final controlTempEncendido = TextEditingController();
  final controlTempApagado = TextEditingController();
  final controlHumedadEncendido = TextEditingController();
  final controlHumedadApagado = TextEditingController();
  final controlSueloEncendido = TextEditingController();
  final controlSueloApagado = TextEditingController();

  
  @override
  void initState() {
    super.initState();
    hasData = false;
    getReleState();
    startListener();
  }

  @override
  void dispose(){
    super.dispose();
    releListener?.cancel();
    controlSueloApagado.dispose();
    controlSueloEncendido.dispose();
    controlHumedadApagado.dispose();
    controlHumedadEncendido.dispose();
    controlTempApagado.dispose();
    controlTempEncendido.dispose();
    controlMinutos.dispose();
    controlHoras.dispose();
    controlHorasEncendido.dispose();
  }

  void changeIndex(int index){
    if(_index == index){
      return;
    }

    setState((){
      _index = index;
      
      if(_index != _indexPrevioAGuardar || (hasModifiedData?? false))
      {
        hasData = true;
      } else{
        hasData = false;
      }
    });
  }

  void selectPorSensor() => changeIndex(3);

  void selectPorTiempo() => changeIndex(2);

  void selectManual() => changeIndex(1);

  void setHabilitedBlocks(){
    if(tipo == TypeOfRele.luz || tipo == TypeOfRele.riego){
      porTiempoHab = true;
      porSensorHab = false;
    } else{
      porTiempoHab = false;
      porSensorHab = true;
    }
  }

  void startListener() async{
    DatabaseReference releDatabase =
      FirebaseDatabase.instance.ref('dispositivos/${widget.deviceName}/RELES/${widget.rele}');
    
    releListener = releDatabase.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value.toString();
      setState(() => isOn =  data == "true" ? true : false);
    });
  }

  void getReleState() async{

    var snapshot = await FirebaseDatabase.instance.ref().child('dispositivos/${widget.deviceName}/RELES/${widget.rele}').get();
    String data = "";

    if(snapshot.exists){
      data = snapshot.value.toString();
    }

    setState(() => isOn =  data == "true" ? true : false);

    var snapshotType = await FirebaseDatabase.instance.ref().child('dispositivos/${widget.deviceName}/TIPORELES/${widget.rele}').get();

    if(snapshotType.exists){
      data = snapshotType.value.toString().trim();

      setState(() {
        if(data == "0"){
          tipo = TypeOfRele.luz;
        }
        if(data == "2"){
          tipo = TypeOfRele.riego;
        }
        if(data == "3"){
          tipo = TypeOfRele.vent;
        }
        if(data == "1"){
          tipo = TypeOfRele.humi;
        }
      });

    setHabilitedBlocks();
    }

    var snapshotTimes = await FirebaseDatabase.instance.ref().child('dispositivos/${widget.deviceName}/DATARELE/${widget.rele}').get();

    if(snapshotTimes.exists){

      setState(() {
        manualOn = snapshotTimes.child("MANUAL").value.toString() == "true" ? true : false;
        if(tipo == TypeOfRele.luz){
          minutos = int.tryParse(snapshotTimes.child("MINS").value.toString())?? 0;
        }
        inicio = int.tryParse(snapshotTimes.child("INICIO").value.toString())?? 0;
        fin = int.tryParse(snapshotTimes.child("FIN").value.toString())?? 0;

        _index = manualOn != null ? (manualOn! ? 1 : ((tipo == TypeOfRele.luz || tipo == TypeOfRele.riego) ? 2 : 3) ) : 0;
        _indexPrevioAGuardar = _index;
      });

    }

  }

  void turnOnOffRele() async{
    if(isOn != null){
      await FirebaseDatabase.instance.ref().child('dispositivos/${widget.deviceName}/RELES').update(
        {widget.rele: !isOn!}
      );
    }
  }

  void guardarInfo() async{

    if(_index == 1){
      setState(() {
        hasData = false;
        hasModifiedData = false;
        _indexPrevioAGuardar = _index;
        manualOn = true;
      });
      var snapshotTimes = FirebaseDatabase.instance.ref().child('dispositivos/${widget.deviceName}/DATARELE/${widget.rele}');
      snapshotTimes.update({
          "MANUAL": manualOn,
      });
      return;
    }

    if(tipo == TypeOfRele.luz){
      if(!_formKeyTiempo.currentState!.validate()){
        return;
      }
    }
    if(tipo == TypeOfRele.humi){
      if(!_formKeyHumedad.currentState!.validate()){
        return;
      }
    }
    if(tipo == TypeOfRele.riego){
      if(!_formKeyTiempo.currentState!.validate()){
        return;
      }
    }
    if(tipo == TypeOfRele.vent){
      if(!_formKeyTemperatura.currentState!.validate()){
        return;
      }
    }

    var snapshotTimes = FirebaseDatabase.instance.ref().child('dispositivos/${widget.deviceName}/DATARELE/${widget.rele}');

    if(tipo == TypeOfRele.luz || tipo == TypeOfRele.riego){
        snapshotTimes.update({
          "MANUAL": false,
          "INICIO":int.tryParse(controlHoras.text),
          "FIN": int.tryParse(controlHorasEncendido.text),
          "MINS": int.tryParse(controlMinutos.text)
        });
        setState(() {
          inicio = int.tryParse(controlHoras.text);
          fin = int.tryParse(controlHorasEncendido.text);
          minutos = int.tryParse(controlMinutos.text);
        });
      }
      if(tipo == TypeOfRele.humi){
        snapshotTimes.update({
          "MANUAL": false,
          "INICIO": int.tryParse(controlHumedadEncendido.text),
          "FIN": int.tryParse(controlHumedadApagado.text),
        });
        setState(() {
          inicio = int.tryParse(controlHumedadEncendido.text);
          fin = int.tryParse(controlHumedadApagado.text);
        });
      }

      /*
      if(tipo == TypeOfRele.riego){
        snapshotTimes.update({
          "MANUAL": false,
          "INICIO":int.tryParse(controlSueloEncendido.text),
          "FIN":int.tryParse(controlSueloApagado.text),
        });
        setState(() {
          inicio = int.tryParse(controlSueloEncendido.text);
          fin = int.tryParse(controlSueloApagado.text);
        });
      }

      */
      if(tipo == TypeOfRele.vent){
        snapshotTimes.update({
          "MANUAL": false,
          "INICIO":int.tryParse(controlTempEncendido.text),
          "FIN":int.tryParse(controlTempApagado.text),
        });
        setState(() {
          inicio = int.tryParse(controlTempEncendido.text);
          fin = int.tryParse(controlTempApagado.text);
        });
      }
    
    setState(() {
      hasData = false;
      hasModifiedData = false;
      _indexPrevioAGuardar = _index;
      manualOn = false;
    });

    Utils.showSuccessSnackBar("Datos guardados exitosamente.");
  }
  
  @override
  Widget build(BuildContext context) {

    double titleFontSize = MediaQuery.of(context).size.height / 30;
    double mediumFontSize = MediaQuery.of(context).size.height / 35;
    double smallFontSize = MediaQuery.of(context).size.height / 45;
    double iconSize = MediaQuery.of(context).size.height / 30;
    double mediumSizedBox = MediaQuery.of(context).size.height / 20;
    double smallSizedBox = MediaQuery.of(context).size.height / 35;
    double smallWidthSizedBox = MediaQuery.of(context).size.width / 35;
    double containerWidth = MediaQuery.of(context).size.width / 10;


    return Scaffold(
      appBar: AppBar(
        title: Text(widget.releName,
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
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.height / 45,),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey),
                      top: BorderSide(color: Colors.grey)
                      )
                    ),
                  child: Text("Elija un método de encendido",
                    style: GoogleFonts.anton(fontSize: titleFontSize)),
                ),
                SizedBox(height: smallSizedBox,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Estado actual: ",
                      style: GoogleFonts.roboto(
                        fontSize: mediumFontSize,
                      )
                    ),
                    Row(
                      children: [
                        Icon(Icons.circle,
                        color: isOn != null ? (isOn! ? Colors.green : Colors.red) : Colors.red,
                        size: iconSize
                        ),
                        SizedBox(width: smallWidthSizedBox,),
                        Text(isOn != null ? (isOn! ? "Encendido" : "Apagado") : "Apagado",
                          style: GoogleFonts.roboto(fontSize: smallFontSize)
                        ),
                      ],
                    ),
                  ]
                ),
                SizedBox(height: smallSizedBox,),
                //MANUAL ****************************
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: containerWidth,
                          child: IconButton(
                            icon: _index == 1 ? const Icon(Icons.circle) : const Icon(Icons.circle_outlined),
                            onPressed: selectManual,
                            iconSize: iconSize * 1.2
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(
                            vertical: MediaQuery.of(context).size.height / 45,),
                          decoration: const BoxDecoration(
                            border: Border(
                              )
                            ),
                          child: Text("Manual",
                            style: GoogleFonts.anton(fontSize: titleFontSize)),
                        ),
                      ],
                    ),
                    Visibility(
                      visible: _index == 1,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ReleOnOff(
                              isOn: isOn,
                              funcion: _indexPrevioAGuardar == 1 ? turnOnOffRele : null,
                              index: _indexPrevioAGuardar?? 0,
                            )
                          ]
                        ,)
                      )
                    ),
                    //POR TIEMPO ****************************
                    Visibility(
                      visible: porTiempoHab?? false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: containerWidth,
                            child: IconButton(
                              onPressed: selectPorTiempo,
                              icon: _index == 2 ? const Icon(Icons.circle) : const Icon(Icons.circle_outlined),
                              iconSize: iconSize * 1.2
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(
                              vertical: MediaQuery.of(context).size.height / 45,),
                            decoration: const BoxDecoration(
                              border: Border(
                                )
                              ),
                            child: Text("Por tiempo",
                              style: GoogleFonts.anton(fontSize: titleFontSize)),
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: _index == 2 && (porTiempoHab?? false),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 20),
                        child: Form(
                          key: _formKeyTiempo,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: containerWidth * 4,
                                    child: Text("Hora de \nencendido: \n(24hs.) ", style: GoogleFonts.roboto(fontSize: mediumFontSize))),
                                  SizedBox(
                                    width: containerWidth,
                                    child: TextFormField(
                                      controller: controlHoras..text = !(hasModifiedData?? false) ? (inicio?? 0).toString() : controlHoras.text,
                                      keyboardType: TextInputType.number,
                                      maxLength: 2,
                                      textAlign: TextAlign.center,
                                      textInputAction: TextInputAction.next,
                                      onEditingComplete: () => setState(()=>hasModifiedData = true),
                                      decoration: const InputDecoration(
                                        hintText: "hs.",
                                        counterText: "",
                                        ),
                                      validator: (val){
                                        if(val != null){
                                          if(int.parse(val) <= 23 && int.parse(val) >= 0){
                                            return null;
                                          } else{
                                            Utils.showErrorSnackBar("Debe ingresar una hora entre 0 y 23 inclusive.");
                                            return " ";
                                          }
                                        } else{
                                          Utils.showErrorSnackBar("Debe ingresar una hora entre 0 y 23 inclusive.");
                                          return " ";
                                        }
                                      },
                                    ),
                                  ),
                                  const Text(":"),
                                  SizedBox(
                                    width: containerWidth,
                                    child: TextFormField(
                                      controller: controlMinutos..text = !(hasModifiedData?? false) ? (minutos?? 0).toString() : controlMinutos.text,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      textInputAction: TextInputAction.next,
                                      onEditingComplete: () => setState(()=>hasModifiedData = true),
                                      decoration: const InputDecoration(
                                        hintText: "min.",
                                        counterText: "",
                                        ),
                                      maxLength: 2,
                                      validator: (val){
                                        if(val != null){
                                          if(int.parse(val) <= 59 && int.parse(val) >= 0){
                                            return null;
                                          } else{
                                            Utils.showErrorSnackBar("Debe ingresar los minutos entre 0 y 59 inclusive.");
                                            return " ";
                                          }
                                        } else{
                                          return null;
                                        }
                                      },
                                    ),
                                  ),
                                  Text("hs.", style: GoogleFonts.roboto(fontSize: smallFontSize)),
                                ]
                              ),
                              SizedBox(height: smallSizedBox),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: containerWidth * 4,
                                    child: Text("Tiempo de \nduración: \n(hs.) ", style: GoogleFonts.roboto(fontSize: mediumFontSize))),
                                  SizedBox(
                                    width: containerWidth,
                                    child: TextFormField(
                                          controller: controlHorasEncendido..text = !(hasModifiedData?? false) ? (fin?? 0).toString() : controlHorasEncendido.text,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          textInputAction: TextInputAction.next,
                                          onEditingComplete: () => setState(()=>hasModifiedData = true),
                                          decoration: const InputDecoration(
                                            hintText: "hs.",
                                            counterText: "",
                                            ),
                                          maxLength: 2,
                                          validator: (val){
                                            if(val != null){
                                              if(int.parse(val) > 0 && int.parse(val) < 24){
                                                return null;
                                              } else{
                                                Utils.showErrorSnackBar("Debe ingresar un tiempo en horas \nde encendido mayor a 0 y menor a 24.");
                                                return " ";
                                              }
                                            } else{
                                              return null;
                                            }
                                          },
                                        ),
                                  ),
                                  Text("hs.", style: GoogleFonts.roboto(fontSize: smallFontSize)),
                                ]
                              ),
                            ]
                          )
                        )
                      )
                    ),
                    //POR SENSOR ****************************
                    Visibility(
                      visible: porSensorHab?? false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: containerWidth,
                            child: IconButton(
                              onPressed: selectPorSensor,
                              icon: _index == 3 ? const Icon(Icons.circle) : const Icon(Icons.circle_outlined),
                              iconSize: iconSize * 1.2
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(
                              vertical: MediaQuery.of(context).size.height / 45,),
                            decoration: const BoxDecoration(
                              border: Border(
                                )
                              ),
                            child: Text("Por sensores",
                              style: GoogleFonts.anton(fontSize: titleFontSize)),
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: _index == 3 && (porSensorHab?? false),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width / 20),
                        child: Column(
                          children: [
                            if(tipo == TypeOfRele.vent)
                              SizedBox(
                                width: containerWidth*8,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(children: [
                                      Text("Encender en base a: ", style: GoogleFonts.roboto(fontSize: smallFontSize),),
                                      Container(
                                        alignment: Alignment.centerRight,
                                        width: containerWidth * 4,
                                        child: 
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                            Icon(Icons.sunny, color: Colors.orange, size: iconSize),
                                            Text("º Temperatura", style: GoogleFonts.roboto(fontSize: smallFontSize),),
                                          ],)
                                      )
                                    ],),
                                    SizedBox(height: mediumSizedBox,),
                                    Form(
                                      key: _formKeyTemperatura,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                            IconButton(
                                              onPressed: null,
                                              icon: 1 == 0 ? const Icon(Icons.circle) : const Icon(Icons.circle_outlined),
                                              iconSize: iconSize * 0.8
                                            ),
                                            Text("Encender cuando esté por encima de: ", style: GoogleFonts.roboto(fontSize: smallFontSize),),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: containerWidth * 2,
                                                child: TextFormField(
                                                  controller: controlTempEncendido..text = !(hasModifiedData?? false) ? (inicio?? 0).toString() : controlTempEncendido.text,
                                                  textInputAction: TextInputAction.next,
                                                  textAlign: TextAlign.center,
                                                  onEditingComplete: () => setState(()=>hasModifiedData = true),
                                                  keyboardType: TextInputType.number,
                                                  decoration: const InputDecoration(
                                                    hintText: "",
                                                    counterText: "",
                                                  ),
                                                  validator: (val){
                                                    if(val!=null){
                                                      try{
                                                        int temp = int.parse(val);
                                                        if(temp < 0 || temp > 100){
                                                          Utils.showErrorSnackBar("Ingrese una temperatura entre 0 y 100...");
                                                          return " ";
                                                        } else{
                                                          return null;
                                                        }
                                                      } on Exception{
                                                        Utils.showErrorSnackBar("Ingrese una temperatura entre 0 y 100...");
                                                        return " ";

                                                      }
                                                    } else{
                                                      Utils.showErrorSnackBar("Ingrese una temperatura entre 0 y 100...");
                                                      return " ";
                                                    }
                                                  }
                                                ),
                                              ),
                                              SizedBox(
                                                width: containerWidth * 2,
                                                child: Text("º Celsius", style: GoogleFonts.roboto(fontSize: smallFontSize))
                                              )
                                            ],
                                          ),

                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                            IconButton(
                                              onPressed: null,
                                              icon: 1 == 0 ? const Icon(Icons.circle) : const Icon(Icons.circle_outlined),
                                              iconSize: iconSize * 0.8
                                            ),
                                            Text("Apagar cuando llegue a: ", style: GoogleFonts.roboto(fontSize: smallFontSize),),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: containerWidth * 2,
                                                child: TextFormField(
                                                  controller: controlTempApagado..text = !(hasModifiedData?? false) ? (fin?? 0).toString() : controlTempApagado.text,
                                                  textInputAction: TextInputAction.done,
                                                  textAlign: TextAlign.center,
                                                  keyboardType: TextInputType.number,
                                                  onEditingComplete: () => setState(()=>hasModifiedData = true),
                                                  validator:(val) {
                                                    if(val!=null){
                                                      try{
                                                        int? tmp = int.tryParse(val);
                                                        int? tmpEncendido = int.tryParse(controlTempEncendido.text);
                                                        if(tmpEncendido == null || tmpEncendido == 0){
                                                          Utils.showErrorSnackBar("Ingrese primero la temperatura \na la que debe encenderse.");
                                                          return " ";
                                                        }
                                                        if(tmp == null){
                                                          Utils.showErrorSnackBar("Ingrese una temperatura entre 0 y 100...");
                                                          return " ";
                                                        }

                                                        if(tmp < 0 || tmp > 100){
                                                          Utils.showErrorSnackBar("Ingrese una temperatura entre 0 y 100...");
                                                          return " ";
                                                        }

                                                        if(tmp >= tmpEncendido){
                                                          Utils.showErrorSnackBar("Ingrese una temperatura menor \na la temperatura de encendido.");
                                                          return " ";
                                                        }
                                                        else{
                                                          return null;
                                                        }
                                                      } on Exception{
                                                        Utils.showErrorSnackBar("Ingrese una temperatura entre 0 y 100...");
                                                        return " ";

                                                      }
                                                    } else{
                                                      Utils.showErrorSnackBar("Ingrese una temperatura entre 0 y 100...");
                                                      return " ";
                                                    }
                                                  },
                                                  decoration: const InputDecoration(
                                                    hintText: "",
                                                    counterText: "",
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: containerWidth * 2,
                                                child: Text("º Celsius", style: GoogleFonts.roboto(fontSize: smallFontSize))
                                              )
                                            ],
                                          ),
                                        ],
                                      ),)

                                  ],
                                )
                              ),
                              //**********************+*** */
                              //humedad
                            if(tipo == TypeOfRele.humi)
                              SizedBox(
                                width: containerWidth*9,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Encender en base a: ", style: GoogleFonts.roboto(fontSize: smallFontSize),),
                                    Container(
                                      alignment: Alignment.centerRight,
                                      width: containerWidth * 6,
                                      child: 
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                          Icon(Icons.water_drop_rounded, color: Colors.lightBlue, size: iconSize),
                                          Text("% Humedad ambiente", style: GoogleFonts.roboto(fontSize: smallFontSize),),
                                        ],)
                                    ),
                                    SizedBox(height: mediumSizedBox/2,),
                                    Form(
                                      key: _formKeyHumedad,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                            IconButton(
                                              onPressed: null,
                                              icon: 1 == 0 ? const Icon(Icons.circle) : const Icon(Icons.circle_outlined),
                                              iconSize: iconSize * 0.8
                                            ),
                                            Text("Encender cuando esté por debajo de: ", style: GoogleFonts.roboto(fontSize: smallFontSize),),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: containerWidth * 2,
                                                child: TextFormField(
                                                  controller: controlHumedadEncendido..text = !(hasModifiedData?? false) ? (inicio?? 0).toString() : controlHumedadEncendido.text,
                                                  textInputAction: TextInputAction.next,
                                                  textAlign: TextAlign.center,
                                                  onEditingComplete: () => setState(()=>hasModifiedData = true),
                                                  keyboardType: TextInputType.number,
                                                  decoration: const InputDecoration(
                                                    hintText: "",
                                                    counterText: "",
                                                  ),
                                                  validator: (val){
                                                    if(val!=null){
                                                      try{
                                                        int hum = int.parse(val);
                                                        if(hum < 0 || hum > 100){
                                                          Utils.showErrorSnackBar("Ingrese un porcentaje de \nhumedad entre 0 y 100...");
                                                          return " ";
                                                        } else{
                                                          return null;
                                                        }
                                                      } on Exception{
                                                        Utils.showErrorSnackBar("Ingrese un porcentaje de \nhumedad entre 0 y 100...");
                                                        return " ";

                                                      }
                                                    } else{
                                                      Utils.showErrorSnackBar("Ingrese un porcentaje de \nhumedad entre 0 y 100...");
                                                      return " ";
                                                    }
                                                  }
                                                ),
                                              ),
                                              SizedBox(
                                                width: containerWidth * 3,
                                                child: Text("% Humedad", style: GoogleFonts.roboto(fontSize: smallFontSize))
                                              )
                                            ],
                                          ),

                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                            IconButton(
                                              onPressed: null,
                                              icon: 1 == 0 ? const Icon(Icons.circle) : const Icon(Icons.circle_outlined),
                                              iconSize: iconSize * 0.8
                                            ),
                                            Text("Apagar cuando llegue a: ", style: GoogleFonts.roboto(fontSize: smallFontSize),),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: containerWidth * 2,
                                                child: TextFormField(
                                                  controller: controlHumedadApagado..text = !(hasModifiedData?? false) ? (fin?? 0).toString() : controlHumedadApagado.text,
                                                  textInputAction: TextInputAction.done,
                                                  onEditingComplete: () => setState(()=>hasModifiedData = true),
                                                  textAlign: TextAlign.center,
                                                  keyboardType: TextInputType.number,
                                                  validator:(val) {
                                                    if(val!=null){
                                                      try{
                                                        int? hum = int.tryParse(val);
                                                        int? humEncendido = int.tryParse(controlHumedadEncendido.text);
                                                        if(humEncendido == null || humEncendido == 0){
                                                          Utils.showErrorSnackBar("Ingrese primero la humedad \na la que debe encenderse.");
                                                          return " ";
                                                          
                                                        }
                                                        if(hum == null){
                                                          Utils.showErrorSnackBar("Ingrese un porcentaje de \nhumedad entre 0 y 100...");
                                                          return " ";
                                                        }

                                                        if(hum < 0 || hum > 100){
                                                          Utils.showErrorSnackBar("Ingrese un porcentaje de \nhumedad entre 0 y 100...");
                                                          return " ";
                                                        }

                                                        if(hum <= humEncendido){
                                                          Utils.showErrorSnackBar("Ingrese un porcentaje menor \na la humedad de encendido.");
                                                          return " ";
                                                        } else{
                                                          return null;
                                                        }
                                                      } on Exception{
                                                        Utils.showErrorSnackBar("Ingrese un porcentaje de \nhumedad entre 0 y 100...");
                                                        return " ";

                                                      }
                                                    } else{
                                                      Utils.showErrorSnackBar("Ingrese un porcentaje de \nhumedad entre 0 y 100...");
                                                      return " ";
                                                    }
                                                  },
                                                  decoration: const InputDecoration(
                                                    hintText: "",
                                                    counterText: "",
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: containerWidth * 3,
                                                child: Text("% Humedad", style: GoogleFonts.roboto(fontSize: smallFontSize))
                                              )
                                            ],
                                          ),
                                        ],
                                      ),)

                                  ],
                                )
                              ),
                              //RIEGO***************************
                            if(tipo == TypeOfRele.riego)
                              SizedBox(
                                width: containerWidth*8,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Encender en base a: ", style: GoogleFonts.roboto(fontSize: smallFontSize),),
                                    Container(
                                      alignment: Alignment.centerRight,
                                      width: containerWidth * 6,
                                      child: 
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                          FaIcon(FontAwesomeIcons.pagelines, color: Colors.green, size: iconSize),
                                          Text("% Humedad de suelo", style: GoogleFonts.roboto(fontSize: smallFontSize),),
                                        ],)
                                    ),
                                    SizedBox(height: mediumSizedBox,),
                                    Form(
                                      key: _formKeySuelo,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                            IconButton(
                                              onPressed: null,
                                              icon: 1 == 0 ? const Icon(Icons.circle) : const Icon(Icons.circle_outlined),
                                              iconSize: iconSize * 0.8
                                            ),
                                            Text("Encender cuando esté por debajo de: ", style: GoogleFonts.roboto(fontSize: smallFontSize),),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SizedBox(
                                                width: containerWidth * 2,
                                                child: TextFormField(
                                                  controller: controlSueloEncendido..text = !(hasModifiedData?? false) ? (inicio?? 0).toString() : controlSueloEncendido.text,
                                                  textInputAction: TextInputAction.next,
                                                  textAlign: TextAlign.center,
                                                  onEditingComplete: () => setState(()=>hasModifiedData = true),
                                                  keyboardType: TextInputType.number,
                                                  decoration: const InputDecoration(
                                                    hintText: "",
                                                    counterText: "",
                                                  ),
                                                  validator: (val){
                                                    if(val!=null){
                                                      try{
                                                        int hum = int.parse(val);
                                                        if(hum < 0 || hum > 100){
                                                          Utils.showErrorSnackBar("Ingrese un porcentaje de \nhumedad entre 0 y 100...");
                                                          return " ";
                                                        } else{
                                                          return null;
                                                        }
                                                      } on Exception{
                                                        Utils.showErrorSnackBar("Ingrese un porcentaje de \nhumedad entre 0 y 100...");
                                                        return " ";

                                                      }
                                                    } else{
                                                      Utils.showErrorSnackBar("Ingrese un porcentaje de \nhumedad entre 0 y 100...");
                                                      return " ";
                                                    }
                                                  }
                                                ),
                                              ),
                                              SizedBox(
                                                width: containerWidth * 3,
                                                child: Text("% Humedad", style: GoogleFonts.roboto(fontSize: smallFontSize))
                                              )
                                            ],
                                          ),

                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              IconButton(
                                                onPressed: null,
                                                icon: 1 == 0 ? const Icon(Icons.circle) : const Icon(Icons.circle_outlined),
                                                iconSize: iconSize * 0.8
                                              ),
                                              Text("Encender durante: ", style: GoogleFonts.roboto(fontSize: smallFontSize),),
                                              SizedBox(
                                                width: containerWidth * 1.5,
                                                child: TextFormField(
                                                  controller: controlSueloApagado..text = !(hasModifiedData?? false) ? (fin?? 0).toString() : controlSueloApagado.text,
                                                  keyboardType: TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  textInputAction: TextInputAction.next,
                                                  decoration: const InputDecoration(
                                                    hintText: "",
                                                    counterText: "",
                                                    ),
                                                  maxLength: 3,
                                                  onEditingComplete: () => setState(()=>hasModifiedData = true),
                                                  validator: (val){
                                                    if(val != null){
                                                      if(int.parse(val) <= 120 && int.parse(val) >= 1){
                                                        return null;
                                                      } else{
                                                        Utils.showErrorSnackBar("Debe ingresar los minutos entre 1 y 120 inclusive.");
                                                        return " ";
                                                      }
                                                    } else{
                                                      return null;
                                                    }
                                                  },
                                                ),
                                              ),
                                              Text("minutos.", style: GoogleFonts.roboto(fontSize: smallFontSize),),
                                            ],
                                          ),
                                        ],
                                      ),)

                                  ],
                                )
                              ),
                          ]
                        ,)
                      )
                    ),
                    SizedBox(height: smallSizedBox,),
                    //************************************** */
                    //BOTON************************************
                    ElevatedButton.icon(
                      onPressed: ((hasData?? false) || (hasModifiedData?? false)) ? guardarInfo : null,
                      icon: 
                        Icon(Icons.save_outlined,
                          size: iconSize,
                        ),
                      label: Text("Guardar", style: GoogleFonts.roboto(fontSize: smallFontSize)))
                  ],
                ),
              ],
            ),
          )
        )
      )
    );
  }
}


class ReleOnOff extends StatelessWidget {
  const ReleOnOff({super.key, this.isOn, this.funcion, required this.index});

  final bool? isOn;
  final Function()? funcion;
  final int index;

  @override
  Widget build(BuildContext context) {
    double mediumFontSize = MediaQuery.of(context).size.height / 35;
    String text = isOn != null ? (isOn! ? "Apagar" : "Encender") : "Encender";
    Color shadowColor = index == 1 ? (isOn != null ? (isOn! ? Colors.red : Colors.green) : Colors.green) : Colors.grey;
    Color letterColor = index == 1 ? (ThemeProvider.themeOf(context).id == 'my_dark' ? Colors.white : Colors.black87) : Colors.black;
    return 
    GestureDetector(
        onTap: funcion, 
        child:
          Container(
            padding: EdgeInsets.all(MediaQuery.of(context).size.height / 100),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              boxShadow:[
                for(double i = 1; i < (letterColor == Colors.white ? 5 : 3); i++)
                  BoxShadow(
                    spreadRadius: -1,
                    color: shadowColor,
                    blurRadius: 3 * i,
                    blurStyle: BlurStyle.outer,
                  ),
                
                for(double i = 1; i < 5; i++)
                  BoxShadow(
                    spreadRadius: -1,
                    color: shadowColor,
                    blurRadius: 3 * i,
                    blurStyle: BlurStyle.inner,
                  ),
              ]),
            child: Text(text,
              style: GoogleFonts.roboto(
                fontSize: mediumFontSize,
                color: letterColor,
              )
            )
          )
    );
  }
}

enum TypeOfRele{
  luz,
  humi,
  vent,
  riego
}