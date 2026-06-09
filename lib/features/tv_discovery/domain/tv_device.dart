import 'package:equatable/equatable.dart';

class TvDevice extends Equatable {
  const TvDevice({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.type,
    this.paired = false,
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final String type;
  final bool paired;

  factory TvDevice.fromMap(Map<dynamic, dynamic> map) {
    return TvDevice(
      id: map['id'] as String,
      name: map['name'] as String,
      host: map['host'] as String,
      port: (map['port'] as num).toInt(),
      type: map['type'] as String,
      paired: map['paired'] == true,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'type': type,
      'paired': paired,
    };
  }

  TvDevice copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? type,
    bool? paired,
  }) {
    return TvDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      type: type ?? this.type,
      paired: paired ?? this.paired,
    );
  }

  @override
  List<Object?> get props => [id, name, host, port, type, paired];
}
