import 'package:ai_teacher_chatbot/ui/views/home_view.dart';
import 'package:flutter/material.dart';
import 'package:ai_teacher_chatbot/constants/route_names.dart';
import 'package:ai_teacher_chatbot/ui/views/login_view.dart';
import 'package:ai_teacher_chatbot/ui/views/signup_view.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case LoginViewRoute:
      return _getPageRoute(
        routeName: settings.name ?? 'LoginView',
        viewToShow: LoginView(),
      );
    case SignUpViewRoute:
      return _getPageRoute(
        routeName: settings.name ?? 'SignUpView',
        viewToShow: SignUpView(),
      );
    case HomeViewRoute:
      return _getPageRoute(
        routeName: settings.name ?? 'HomeView',
        viewToShow: const HomeView(),
      );
    default:
      return MaterialPageRoute(
          builder: (_) => Scaffold(
                body: Center(
                    child: Text('No route defined for ${settings.name}')),
              ));
  }
}

PageRoute _getPageRoute({required String routeName, required Widget viewToShow}) {
  return MaterialPageRoute(
      settings: RouteSettings(
        name: routeName,
      ),
      builder: (_) => viewToShow);
}