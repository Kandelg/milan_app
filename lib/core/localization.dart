import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milan_app/data/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported UI languages.
enum AppLanguage { english, nepali }

/// Persists the chosen language and exposes the active one to the widget tree.
class LocaleController extends Notifier<AppLanguage> {
  static const String _prefsKey = 'app_language';

  @override
  AppLanguage build() {
    _load();
    return AppLanguage.english;
  }

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString(_prefsKey);
    if (stored == AppLanguage.nepali.name) {
      state = AppLanguage.nepali;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.name);
  }

  void toggle() {
    setLanguage(
      state == AppLanguage.english ? AppLanguage.nepali : AppLanguage.english,
    );
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, AppLanguage>(LocaleController.new);

/// All user-facing strings in English and Nepali.
///
/// Access via `AppStrings.of(context)`.
class AppStrings {
  AppStrings(this.language);

  factory AppStrings.of(BuildContext context) {
    return AppStrings(
      ProviderScope.containerOf(context).read(localeControllerProvider),
    );
  }

  final AppLanguage language;

  bool get _ne => language == AppLanguage.nepali;

  // --- Brand / splash -------------------------------------------------------
  String get appName => _ne ? 'बिहे एन्ड डेट' : 'Bihe & Date';
  String get tagline => _ne ? 'आफ्नो साथी खोज्नुहोस्' : 'Find your person';

  // --- Auth -----------------------------------------------------------------
  String get welcomeBack => _ne ? 'स्वागत छ' : 'Welcome back';
  String get signIn => _ne ? 'साइन इन' : 'Sign in';
  String get signUp => _ne ? 'साइन अप' : 'Sign up';
  String get createAccount => _ne ? 'खाता बनाउनुहोस्' : 'Create account';
  String get email => _ne ? 'इमेल' : 'Email';
  String get password => _ne ? 'पासवर्ड' : 'Password';
  String get confirmPassword => _ne ? 'पासवर्ड पुष्टि' : 'Confirm password';
  String get fullName => _ne ? 'पूरा नाम' : 'Full name';
  String get forgotPassword => _ne ? 'पासवर्ड बिर्सनुभयो?' : 'Forgot password?';
  String get noAccount => _ne ? 'खाता छैन?' : "Don't have an account?";
  String get haveAccount => _ne ? 'खाता छ?' : 'Already have an account?';

  // --- Magic Link ---------------------------------------------------------
  String get signInWithMagicLink => _ne ? 'इमेल लिङ्कबाट साइन इन' : 'Sign in with email link';
  String get magicLinkSent => _ne ? 'लिङ्क पठाइयो!' : 'Link sent!';
  String get checkYourInbox => _ne
      ? 'आफ्नो इमेल चेक गर्नुहोस् र लिङ्कमा क्लिक गर्नुहोस्।'
      : 'Check your email and click the link to sign in.';
  String get verifying => _ne ? 'प्रमाणीत गर्दै…' : 'Verifying…';
  String get pleaseWait => _ne ? 'कृपया पर्खनुहोस्' : 'Please wait…';
  String get phone => _ne ? 'मोबाइल नम्बर' : 'Mobile number';
  String get phoneHint => _ne ? '९८XXXXXXXX' : '98XXXXXXXX';

  // --- Navigation -----------------------------------------------------------
  String get discover => _ne ? 'खोज्नुहोस्' : 'Discover';
  String get home => _ne ? 'होम' : 'Home';
  String get matches => _ne ? 'मिलन' : 'Matches';
  String get messages => _ne ? 'सन्देश' : 'Messages';
  String get profile => _ne ? 'प्रोफाइल' : 'Profile';
  String get myProfile => _ne ? 'मेरो प्रोफाइल' : 'My profile';

  // --- Home tabs ------------------------------------------------------------
  String get forYou => _ne ? 'तपाईंका लागि' : 'For You';
  String get new_ => _ne ? 'नयाँ' : 'New';
  String get requested => _ne ? 'अनुरोध' : 'Requested';
  String get received => _ne ? 'प्राप्त' : 'Received';
  String get sent => _ne ? 'पठाइएको' : 'Sent';
  String get liked => _ne ? 'लाइक' : 'Liked';
  String get notifications => _ne ? 'सूचना' : 'Notifications';
  String get likeBack => _ne ? 'लाइक गर्नुहोस्' : 'Like back';
  String get acceptRequest => _ne ? 'स्वीकार गर्नुहोस्' : 'Accept';
  String get declineRequest => _ne ? 'अस्वीकार' : 'Decline';
  String get markAllRead => _ne ? 'सबै पढेको' : 'Mark all read';
  String get pending => _ne ? 'पर्खिरहेको' : 'Pending';

  // --- Actions --------------------------------------------------------------
  String get save => _ne ? 'सुरक्षित गर्नुहोस्' : 'Save';
  String get cancel => _ne ? 'रद्द' : 'Cancel';
  String get confirm => _ne ? 'पुष्टि' : 'Confirm';
  String get back => _ne ? 'पछाडि' : 'Back';
  String get next => _ne ? 'अर्को' : 'Next';
  String get finish => _ne ? 'समाप्त' : 'Finish';
  String get retry => _ne ? 'पुनः प्रयास' : 'Try again';
  String get signOut => _ne ? 'साइन आउट' : 'Sign out';
  String get done => _ne ? 'भयो' : 'Done';

  // --- Onboarding -----------------------------------------------------------
  String get aboutYou => _ne ? 'तपाईंको बारेमा' : 'About you';
  String get iAm => _ne ? 'म हुँ' : 'I am';
  String get interestedIn => _ne ? 'मलाई चाहिन्छ' : 'Interested in';
  String get yourBirthday => _ne ? 'तपाईंको जन्मदिन' : 'Your birthday';
  String get addPhotos => _ne ? 'फोटो थप्नुहोस्' : 'Add photos';
  String get addPhoto => _ne ? 'फोटो थप्नुहोस्' : 'Add photo';
  String get bio => _ne ? 'बायो' : 'Bio';
  String get city => _ne ? 'सहर' : 'City';
  String get occupation => _ne ? 'पेशा' : 'Occupation';
  String get interests => _ne ? 'रुचि' : 'Interests';

  // --- Discover -------------------------------------------------------------
  String get noOneNew => _ne ? 'कसैं छैन' : 'No one new for now';
  String get changeFilters => _ne ? 'फिल्टर बदल्नुहोस्' : 'Change filters';
  String get filters => _ne ? 'फिल्टर' : 'Filters';
  String get reset => _ne ? 'रिसेट' : 'Reset';
  String get showResults => _ne ? 'नतिजा देखाउनुहोस्' : 'Show results';
  String get showMe => _ne ? 'मलाई देखाउनु' : 'Show me';

  // --- Lifestyle details ----------------------------------------------------
  String get height => _ne ? 'उचाइ' : 'Height';
  String get heightHint => _ne ? 'से.मि. मा (जस्तै 170)' : 'In cm (e.g. 170)';
  String get religion => _ne ? 'धर्म' : 'Religion';
  String get education => _ne ? 'शिक्षा' : 'Education';
  String get diet => _ne ? 'खानपान' : 'Diet';
  String get veg => _ne ? 'शाकाहारी' : 'Veg';
  String get nonVeg => _ne ? 'मांसाहारी' : 'Non-veg';
  String get smoking => _ne ? 'धुम्रपान' : 'Smoking';
  String get smoker => _ne ? 'गर्नुहुन्छ' : 'Smoker';
  String get nonSmoker => _ne ? 'गर्नुहुन्न' : 'Non-smoker';

  /// Localised label for a lifestyle option value.
  String lifestyleLabel(String value) {
    if (!_ne) {
      switch (value) {
        case 'hindu':
          return 'Hindu';
        case 'buddhist':
          return 'Buddhist';
        case 'muslim':
          return 'Muslim';
        case 'christian':
          return 'Christian';
        case 'high_school':
          return 'High school';
        case 'bachelor':
          return "Bachelor's";
        case 'master':
          return "Master's";
        case 'phd':
          return 'PhD';
        case 'veg':
          return 'Veg';
        case 'non_veg':
          return 'Non-veg';
        case 'smoker':
          return 'Smoker';
        case 'non_smoker':
          return 'Non-smoker';
        case 'other':
          return 'Other';
        default:
          return value;
      }
    }
    switch (value) {
      case 'hindu':
        return 'हिन्दु';
      case 'buddhist':
        return 'बौद्ध';
      case 'muslim':
        return 'मुस्लिम';
      case 'christian':
        return 'इसाई';
      case 'high_school':
        return 'प्लस टु';
      case 'bachelor':
        return 'स्नातक';
      case 'master':
        return 'स्नातकोत्तर';
      case 'phd':
        return 'पीएचडी';
      case 'veg':
        return 'शाकाहारी';
      case 'non_veg':
        return 'मांसाहारी';
      case 'smoker':
        return 'गर्नुहुन्छ';
      case 'non_smoker':
        return 'गर्नुहुन्न';
      case 'other':
        return 'अन्य';
      default:
        return value;
    }
  }

  // --- Stories --------------------------------------------------------------
  String get stories => _ne ? 'स्टोरी' : 'Stories';
  String get addStory => _ne ? 'स्टोरी थप्नुहोस्' : 'Add story';
  String get photoStory => _ne ? 'फोटो' : 'Photo';
  String get textStory => _ne ? 'लेख्नुहोस्' : 'Write';
  String get writeSomething =>
      _ne ? 'केही लेख्नुहोस्…' : 'Write something…';
  String get share => _ne ? 'सेयर' : 'Share';
  String get yourStory => _ne ? 'तपाईंको स्टोरी' : 'Your story';
  String get noStoriesYet =>
      _ne ? 'अझै स्टोरी छैन — पहिलो हाल्नुहोस्!' : 'No stories yet — post the first one!';
  String get deleteStory => _ne ? 'स्टोरी हटाउने?' : 'Delete story?';
  String get delete => _ne ? 'हटाउनुहोस्' : 'Delete';

  // --- Match / chat ---------------------------------------------------------
  String get itsAMatch => _ne ? 'मिलन भयो!' : "It's a match!";
  String get sendMessage => _ne ? 'सन्देश पठाउनुहोस्' : 'Send a message';
  String get keepSwiping => _ne ? 'स्वाइप जारी' : 'Keep swiping';
  String get typeMessage => _ne ? 'सन्देश लेख्नुहोस्…' : 'Type a message…';
  String get noMatches => _ne ? 'अझै मिलन छैन' : 'No matches yet';
  String get newMatchSayHi =>
      _ne ? 'नयाँ मिलन — नमस्ते भन्नु!' : 'New match — say hi!';
  String get photo => _ne ? 'फोटो' : 'Photo';
  String get noNewMatchesTitle => _ne ? 'नयाँ मिलन छैन' : 'No new matches yet';
  String get noNewMatchesBody => _ne
      ? 'डिस्कभरमा स्वाइप गर्नुहोस्। कोहीले तपाईंलाई लाइक गर्दा यहाँ देखिनेछ।'
      : 'Start swiping in Discover. When someone likes you back, they will '
          'appear here.';
  String get noMessagesTitle => _ne ? 'सन्देश छैन' : 'No messages yet';
  String get noMessagesBody => _ne
      ? 'मिलनबाट कुराकानी सुरु गर्नुहोस् — तपाईंका च्याट यहाँ देखिनेछन्।'
      : 'Start a conversation from your matches and your chats will appear '
          'here.';

  // --- Home tab empty states ------------------------------------------------
  String get noLikedTitle => _ne ? 'कसैंले लाइक गरेको छैन' : 'No likes yet';
  String get noLikedBody => _ne
      ? 'कसैले तपाईंलाई लाइक गर्दा यहाँ देखिनेछ।'
      : 'When someone likes you, they will show up here.';
  String get noRequestsTitle => _ne ? 'अनुरोध छैन' : 'No requests yet';
  String get noRequestsBody => _ne
      ? 'कसैले तपाईंलाई कनेक्सन अनुरोध पठाउँदा यहाँ देखिनेछ।'
      : 'When someone sends you a connection request, it will appear here.';
  String get noSentRequestsTitle =>
      _ne ? 'पठाइएको अनुरोध छैन' : 'No sent requests';
  String get noSentRequestsBody => _ne
      ? 'तपाईंले पठाउनुभएका अनुरोधहरू यहाँ देखिनेछन्।'
      : 'Connection requests you have sent will appear here.';
  String get noNewThisMonthTitle =>
      _ne ? 'यो महिना कसैं आएको छैन' : 'No new members this month';
  String get noNewThisMonthBody => _ne
      ? 'यो महिना सामेल भएका नयाँ सदस्यहरू यहाँ देखिनेछन्।'
      : 'People who joined this month will appear here.';
  String get noNotificationsTitle => _ne ? 'सूचना छैन' : 'No notifications';
  String get noNotificationsBody => _ne
      ? 'कसैले लाइक वा अनुरोध गर्दा यहाँ देखिनेछ।'
      : 'New likes and requests will show up here.';

  /// Notification subtitle shown in the notifications list.
  String notificationBody(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return _ne ? 'तपाईंलाई लाइक गर्यो' : 'liked you';
      case NotificationType.request:
        return _ne ? 'तपाईंलाई अनुरोध पठायो' : 'sent you a request';
      case NotificationType.match:
        return _ne ? 'तपाईंसँग मिलन भयो' : 'matched with you';
    }
  }

  // --- Block / report -------------------------------------------------------
  String get block => _ne ? 'ब्लक' : 'Block';
  String get report => _ne ? 'रिपोर्ट' : 'Report';
  String get unmatch => _ne ? 'अनम्याच' : 'Unmatch';

  // --- Settings -------------------------------------------------------------
  String get languageLabel => _ne ? 'भाषा' : 'Language';
  String get english => _ne ? 'अंग्रेजी' : 'English';
  String get nepali => _ne ? 'नेपाली' : 'Nepali';
  String get settings => _ne ? 'सेटिङ' : 'Settings';
  String get editProfile => _ne ? 'प्रोफाइल सम्पादन' : 'Edit profile';
  String get editProfileSubtitle =>
      _ne ? 'तपाईंका फोटो र विवरण अद्यावधिक गर्नुहोस्'
          : 'Update your photos and details';
  String get privacySafety => _ne ? 'गोपनीयता र सुरक्षा' : 'Privacy & safety';
  String get privacySafetySubtitle => _ne
      ? 'प्रोफाइल कार्डबाट कसैलाई ब्लक वा रिपोर्ट गर्नुहोस्'
      : 'Block or report anyone from their profile card';
  String get about => _ne ? 'बिहे एन्ड डेट बारेमा' : 'About Bihe & Date';
  String get version => _ne ? 'संस्करण १.०.०' : 'Version 1.0.0';
  String get aboutBody => _ne
      ? 'Bihe & Date मा तपाईंलाई स्वागत छ! Bihe & Date एउटा आधुनिक नेपाली '
          'म्याचमेकिङ र डेटिङ प्लेटफर्म हो, जसले मानिसहरूलाई अर्थपूर्ण र '
          'वास्तविक सम्बन्धहरू जोड्न मद्दत गर्दछ। हाम्रो उद्देश्य सुरक्षित, '
          'प्रिमियम र भरपर्दो वातावरणमा तपाईंको लागि उपयुक्त जीवनसाथी वा साथी '
          'खोज्ने प्रक्रियालाई सहज र रोमान्चक बनाउनु हो। हाम्रो एप प्रयोग '
          'गरिदिनुभएकोमा धन्यवाद!'
      : 'Welcome to Bihe & Date! Bihe & Date is a modern Nepali matchmaking '
          'and dating platform designed to help people build meaningful and '
          'authentic connections. Our mission is to simplify the process of '
          'finding your ideal life partner or companion in a secure, premium, '
          'and trusted environment. Thank you for being a part of our journey!';

  // --- Feedback -------------------------------------------------------------
  String get sendFeedback =>
      _ne ? 'प्रतिक्रिया पठाउनुहोस्' : 'Send Feedback';
  String get sendFeedbackSubtitle => _ne
      ? 'एपलाई अझ उत्कृष्ट बनाउन आफ्नो सुझाव दिनुहोस्'
      : 'Help us improve your experience';
  String get feedbackHint => _ne
      ? 'तपाईंको सुझाव, विचार वा समस्या यहाँ लेख्नुहोस्…'
      : 'Share your thoughts, ideas or report an issue…';
  String get feedbackSubmit => _ne ? 'पठाउनुहोस्' : 'Submit';
  String get feedbackEmpty =>
      _ne ? 'कृपया पहिले केही लेख्नुहोस्।' : 'Please write something first.';
  String get feedbackSent => _ne
      ? 'तपाईंको प्रतिक्रियाका लागि धन्यवाद!'
      : 'Thanks for your feedback!';
  String get feedbackFailed => _ne
      ? 'प्रतिक्रिया पठाउन सकिएन। कृपया पुनः प्रयास गर्नुहोस्।'
      : "Couldn't send feedback. Please try again.";
  String get footer => _ne ? 'बिहे एन्ड डेट। कसैंलाई नमस्ते भन्नुहोस्!'
      : 'Bihe & Date. Say hi to someone new!';
  String get signOutConfirmBody => _ne
      ? 'फर्कनका लागि तपाईंलाई इमेल र पासवर्ड चाहिन्छ।'
      : 'You will need your email and password to return.';

  /// Localised label for a gender / "interested in" value.
  String genderLabel(String value) {
    if (!_ne) {
      switch (value) {
        case 'male':
          return 'Men';
        case 'female':
          return 'Women';
        case 'other':
          return 'Non-binary';
        default:
          return 'Everyone';
      }
    }
    switch (value) {
      case 'male':
        return 'पुरुष';
      case 'female':
        return 'महिला';
      case 'other':
        return 'अन्य';
      default:
        return 'सबै';
    }
  }
}
