import 'package:equatable/equatable.dart';

class TvDevice extends Equatable {
  const TvDevice({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.type,
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final String type;

  factory TvDevice.fromMap(Map<dynamic, dynamic> map) {
    return TvDevice(
      id: map['id'] as String,
      name: map['name'] as String,
      host: map['host'] as String,
      port: (map['port'] as num).toInt(),
      type: map['type'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {'id': id, 'name': name, 'host': host, 'port': port, 'type': type};
  }

  @override
  List<Object?> get props => [id, name, host, port, type];
}
