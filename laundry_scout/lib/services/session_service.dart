class SessionService {
  static final SessionService _instance = SessionService._internal();
  factory SessionService() => _instance;
  SessionService._internal();

  bool hasShownUserFeedbackModalThisSession = false;
  bool hasShownOwnerFeedbackModalThisSession = false;

  void resetFeedbackFlags() {
    hasShownUserFeedbackModalThisSession = false;
    hasShownOwnerFeedbackModalThisSession = false;
  }
}