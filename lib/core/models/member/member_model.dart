import 'package:json_annotation/json_annotation.dart';

class MemberModel {
  @JsonKey(name: 'id', fromJson: _toInt)
  final int idMember;
  final String? nama;
  @JsonKey(name: 'no_hp')
  final String? telepon;
  final String? email;
  final String? alamat;
  @JsonKey(name: 'jenis_kel')
  final String? jenisKel;
  @JsonKey(name: 'kategori_cust')
  final String? kategoriCust;
  @JsonKey(name: 'tanggal_lahir')
  final String? tanggalLahir;
  @JsonKey(name: 'id_pos')
  final String? idPos;
  final dynamic points;
  @JsonKey(name: 'datecreated')
  final String? datecreated;

  MemberModel({
    this.idMember = 0,
    this.idPos,
    this.nama,
    this.telepon,
    this.email,
    this.alamat,
    this.jenisKel,
    this.kategoriCust,
    this.tanggalLahir,
    this.points,
    this.datecreated,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      idMember: json['id'] != null 
          ? _toInt(json['id']) 
          : (json['id_member'] != null ? _toInt(json['id_member']) : 0),
      idPos: json['id_pos'] as String?,
      nama: (json['nama'] ?? json['name']) as String?,
      telepon: (json['no_hp'] ?? json['telepon']) as String?,
      email: json['email'] as String?,
      alamat: (json['alamat'] ?? json['address']) as String?,
      jenisKel: (json['jenis_kel'] ?? json['gender']) as String?,
      kategoriCust: json['kategori_cust'] as String?,
      tanggalLahir: (json['tanggal_lahir'] ?? json['birth_date']) as String?,
      points: json['points'] ?? json['value_pts'],
      datecreated: (json['datecreated'] ?? json['created_at']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': idMember,
      'id_pos': idPos,
      'nama': nama,
      'no_hp': telepon,
      'email': email,
      'alamat': alamat,
      'jenis_kel': jenisKel,
      'kategori_cust': kategoriCust,
      'tanggal_lahir': tanggalLahir,
      'points': points,
      'datecreated': datecreated,
    };
  }

  MemberModel copyWith({
    int? idMember,
    String? idPos,
    String? nama,
    String? telepon,
    String? email,
    String? alamat,
    String? jenisKel,
    String? kategoriCust,
    String? tanggalLahir,
    dynamic points,
    String? datecreated,
  }) {
    return MemberModel(
      idMember: idMember ?? this.idMember,
      idPos: idPos ?? this.idPos,
      nama: nama ?? this.nama,
      telepon: telepon ?? this.telepon,
      email: email ?? this.email,
      alamat: alamat ?? this.alamat,
      jenisKel: jenisKel ?? this.jenisKel,
      kategoriCust: kategoriCust ?? this.kategoriCust,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      points: points ?? this.points,
      datecreated: datecreated ?? this.datecreated,
    );
  }
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
  }
  return 0;
}
