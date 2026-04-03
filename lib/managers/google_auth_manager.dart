import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthManager {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '851461803179-us2iqf5s9ttu59jp68462qckp10u91q4.apps.googleusercontent.com'
  );
  Future<String?> getGoogleIdToken() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      return googleAuth.idToken; // Nhờ có serverClientId, idToken mới không bị null
    } catch (e) {
      throw Exception("Lỗi khi kết nối với Google: $e");
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}