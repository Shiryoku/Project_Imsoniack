import 'package:flutter/material.dart';

class SubscriptionManager extends ValueNotifier<bool> {
  // Singleton instance
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  
  factory SubscriptionManager() {
    return _instance;
  }

  SubscriptionManager._internal() : super(false); // Default to not subscribed

  void subscribe() {
    value = true;
  }
  
  void unsubscribe() {
    value = false;
  }
  
  bool get isSubscribed => value;
}
