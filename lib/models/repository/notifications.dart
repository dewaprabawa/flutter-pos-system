import 'package:flutter/material.dart';
import 'package:possystem/services/database.dart';

class NotificationItem {
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] as int,
      title: map['title'] as String,
      body: map['body'] as String,
      isRead: (map['isRead'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'isRead': isRead ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}

class Notifications extends ChangeNotifier {
  static final Notifications instance = Notifications();

  List<NotificationItem> items = [];

  int get unreadCount => items.where((e) => !e.isRead).length;

  Future<void> initialize() async {
    final data = await Database.instance.query(
      'notifications',
      orderBy: 'createdAt DESC',
      limit: 100,
    );
    items = data.map((e) => NotificationItem.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> add(String title, String body) async {
    final now = DateTime.now();
    final data = {
      'title': title,
      'body': body,
      'isRead': 0,
      'createdAt': now.millisecondsSinceEpoch,
    };
    final id = await Database.instance.push('notifications', data);
    
    final item = NotificationItem(
      id: id,
      title: title,
      body: body,
      isRead: false,
      createdAt: now,
    );
    items.insert(0, item);
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    await Database.instance.batchUpdate(
      'notifications',
      items.where((e) => !e.isRead).map((e) => {'isRead': 1}).toList(),
      where: 'id = ?',
      whereArgs: items.where((e) => !e.isRead).map((e) => [e.id]).toList(),
    );

    items = items.map((e) => NotificationItem(
      id: e.id,
      title: e.title,
      body: e.body,
      isRead: true,
      createdAt: e.createdAt,
    )).toList();

    notifyListeners();
  }

  Future<void> clearAll() async {
    await Database.instance.reset('notifications');
    items.clear();
    notifyListeners();
  }
}
