import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> _navigationKey = GlobalKey<NavigatorState>();

  GlobalKey<NavigatorState> get navigationKey => _navigationKey;

  void pop() {
    return _navigationKey.currentState?.pop();
  }

  Future<dynamic> navigateTo(String routeName, {dynamic arguments}) {
    if (_navigationKey.currentState != null) {
      return _navigationKey.currentState!.pushNamed(routeName, arguments: arguments);
    } else {
      // Handle the case when the currentState is null
      return Future.value(null);
    } 
  }
}