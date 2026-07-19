import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../network/api_client.dart';

class SocialAuthConfig {
  static const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
  static const appleServiceId = String.fromEnvironment('APPLE_SERVICE_ID');
  static const appleRedirectUri = String.fromEnvironment('APPLE_REDIRECT_URI');

  static bool get googleReady => googleServerClientId.isNotEmpty;
  static bool get appleReady => appleServiceId.isNotEmpty;
}

class SocialAuthService {
  SocialAuthService({ApiClient? api}) : api = api ?? ApiClient();

  final ApiClient api;
  bool _googleInitialized = false;

  Future<void> signInWithGoogle() async {
    if (!SocialAuthConfig.googleReady) {
      throw StateError('google_not_configured');
    }
    final signIn = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await signIn.initialize(
        clientId: SocialAuthConfig.googleClientId.isEmpty
            ? null
            : SocialAuthConfig.googleClientId,
        serverClientId: SocialAuthConfig.googleServerClientId,
      );
      _googleInitialized = true;
    }
    if (!signIn.supportsAuthenticate()) {
      throw UnsupportedError('google_authenticate_not_supported');
    }
    final account = await signIn.authenticate();
    final identityToken = account.authentication.idToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw StateError('google_identity_token_missing');
    }
    await api.federatedLogin(
      provider: 'google',
      identityToken: identityToken,
      displayName: account.displayName,
    );
  }

  Future<void> signInWithApple() async {
    if (!SocialAuthConfig.appleReady) {
      throw StateError('apple_not_configured');
    }
    if (!await SignInWithApple.isAvailable()) {
      throw UnsupportedError('apple_sign_in_not_available');
    }
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      webAuthenticationOptions: SocialAuthConfig.appleRedirectUri.isEmpty
          ? null
          : WebAuthenticationOptions(
              clientId: SocialAuthConfig.appleServiceId,
              redirectUri: Uri.parse(SocialAuthConfig.appleRedirectUri),
            ),
    );
    final identityToken = credential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw StateError('apple_identity_token_missing');
    }
    final displayName = [
      credential.givenName,
      credential.familyName,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
    await api.federatedLogin(
      provider: 'apple',
      identityToken: identityToken,
      authorizationCode: credential.authorizationCode,
      displayName: displayName,
    );
  }
}
