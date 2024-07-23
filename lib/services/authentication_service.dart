import 'package:ai_teacher_chatbot/locator.dart';
import 'package:ai_teacher_chatbot/models/user.dart' as custom_user;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:ai_teacher_chatbot/services/firestore_service.dart';

class AuthenticationService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirestoreService _firestoreService = locator<FirestoreService>();

  late custom_user.User _currentUser;
  custom_user.User get currentUser => _currentUser;

  Future loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      var authResult = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _populateCurrentUser(authResult.user);
      return authResult.user != null;
    } catch (e) {
      return e.toString();
    }
  }

  Future signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      var authResult = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // create a new user profile on firestore
      _currentUser = custom_user.User(
        id: authResult.user!.uid,
        email: email,
        fullName: fullName,
        userRole: role,
      );

      await _firestoreService.createUser(_currentUser);

      return authResult.user != null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> isUserLoggedIn() async {
    var user = _firebaseAuth.currentUser;
    
    if (user != null){
      await _populateCurrentUser(user);
    }

    return user != null;
  }

  Future _populateCurrentUser(firebase_auth.User? user) async {
    if (user != null) {
      _currentUser = await _firestoreService.getUser(user.uid);
    }
  }
}