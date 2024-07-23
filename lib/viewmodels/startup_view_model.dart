import 'package:ai_teacher_chatbot/constants/route_names.dart';
import 'package:ai_teacher_chatbot/locator.dart';
import 'package:ai_teacher_chatbot/services/authentication_service.dart';
import 'package:ai_teacher_chatbot/services/navigation_service.dart';
import 'package:ai_teacher_chatbot/viewmodels/base_model.dart';

class StartUpViewModel extends BaseModel {
  final AuthenticationService _authenticationService =
      locator<AuthenticationService>();
  final NavigationService _navigationService = locator<NavigationService>();

  Future handleStartUpLogic() async {
    var hasLoggedInUser = await _authenticationService.isUserLoggedIn();

    if (hasLoggedInUser) {
      _navigationService.navigateTo(HomeViewRoute);
    } else {
      _navigationService.navigateTo(LoginViewRoute);
    }
  }
}