import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String? username;
  final bool? admin;
  final String? state;
  final String? country;
  final String? address;
  final int? edad;
  final List<String>? gustos;

  Usuario({
    this.username,
    this.admin,
    this.state,
    this.country,
    this.address,
    this.edad,
    this.gustos,
  });

  factory Usuario.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Usuario(
      username: data?['username'] ?? "",
      admin: data?['admin'] ?? "",
      state: data?['state'] ?? "",
      country: data?['country'] ?? "",
      address: data?['address'] ?? "",
      edad: data?['edad'] ?? "",
      gustos:
          (data?['gustos'] is Iterable ? List.from(data?['gustos']) : null) ?? [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (username != null) "name": username,
      if (admin != null) "admin": admin,
      if (state != null) "state": state,
      if (country != null) "country": country,
      if (address != null) "address": address,
      if (edad != null) "edad": edad,
      if (gustos != null) "gustos": gustos,
    };
  }
}