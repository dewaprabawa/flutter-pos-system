class Session {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final double startCash;
  final double expectedCash;
  final double? actualCash;
  final String cashierName;
  final int status; // 0 = active, 1 = closed

  Session({
    this.id,
    required this.startTime,
    this.endTime,
    required this.startCash,
    required this.expectedCash,
    this.actualCash,
    required this.cashierName,
    required this.status,
  });

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as int?,
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] as int),
      endTime: map['endTime'] != null ? DateTime.fromMillisecondsSinceEpoch(map['endTime'] as int) : null,
      startCash: (map['startCash'] as num).toDouble(),
      expectedCash: (map['expectedCash'] as num).toDouble(),
      actualCash: map['actualCash'] != null ? (map['actualCash'] as num).toDouble() : null,
      cashierName: map['cashierName'] as String,
      status: map['status'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'startCash': startCash,
      'expectedCash': expectedCash,
      'actualCash': actualCash,
      'cashierName': cashierName,
      'status': status,
    };
  }
}
