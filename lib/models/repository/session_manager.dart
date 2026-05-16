import 'package:flutter/material.dart';
import 'package:possystem/models/session.dart';
import 'package:possystem/services/database.dart';

class SessionManager extends ChangeNotifier {
  static final SessionManager instance = SessionManager();

  Session? currentSession;

  bool get hasActiveSession => currentSession != null && currentSession!.status == 0;

  Future<void> initialize() async {
    final data = await Database.instance.query(
      'sessions',
      where: 'status = 0',
      orderBy: 'startTime DESC',
      limit: 1,
    );
    
    if (data.isNotEmpty) {
      currentSession = Session.fromMap(data.first);
    } else {
      currentSession = null;
    }
    notifyListeners();
  }

  Future<void> startSession(double startCash, String cashierName) async {
    final session = Session(
      startTime: DateTime.now(),
      startCash: startCash,
      expectedCash: startCash,
      cashierName: cashierName,
      status: 0,
    );
    
    final id = await Database.instance.push('sessions', session.toMap());
    currentSession = Session(
      id: id,
      startTime: session.startTime,
      startCash: session.startCash,
      expectedCash: session.expectedCash,
      cashierName: session.cashierName,
      status: session.status,
    );
    notifyListeners();
  }

  Future<void> addExpectedCash(double amount) async {
    if (currentSession == null) return;
    final newExpected = currentSession!.expectedCash + amount;
    await Database.instance.update(
      'sessions',
      currentSession!.id,
      {'expectedCash': newExpected},
    );
    currentSession = Session(
      id: currentSession!.id,
      startTime: currentSession!.startTime,
      startCash: currentSession!.startCash,
      expectedCash: newExpected,
      cashierName: currentSession!.cashierName,
      status: currentSession!.status,
    );
    notifyListeners();
  }

  Future<void> closeSession(double actualCash) async {
    if (currentSession == null) return;
    final now = DateTime.now();
    await Database.instance.update(
      'sessions',
      currentSession!.id,
      {
        'actualCash': actualCash,
        'endTime': now.millisecondsSinceEpoch,
        'status': 1,
      },
    );
    currentSession = null;
    notifyListeners();
  }
}
