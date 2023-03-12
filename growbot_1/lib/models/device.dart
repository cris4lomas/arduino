class Device {
  late String humedad;
  late String temperatura;
  late String suelo;
  
  Device(){
    humedad = "N/D";
    temperatura = "N/D";
    suelo = "N/D";
  }


  /*
  factory Device.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    late data = snapshot.data();
    return Device(
      ledArduino: data?['LEDARDUINO'] ?? "",
      ledWifi: data?['LEDWIFI'] ?? "",
      rele: data?['RELE'] ?? "",
      //gustos:
      //    (data?['gustos'] is Iterable ? List.from(data?['gustos']) : null) ?? [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (ledArduino != null) "LEDARDUINO": ledArduino,
      if (ledWifi != null) "LEDWIFI": ledWifi,
      if (rele != null) "RELE": rele,
      //if (gustos != null) "gustos": gustos,
    };
  }
*/
}