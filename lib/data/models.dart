import 'package:milan_app/core/constants.dart';

/// A row of the `profiles` table (1:1 with `auth.users`).
class Profile {
  const Profile({
    required this.id,
    required this.fullName,
    this.birthDate,
    this.gender,
    this.interestedIn = kGenderEveryone,
    this.bio = '',
    this.permanentAddress = '',
    this.currentLocation = '',
    this.occupation = '',
    this.phone = '',
    this.birthDateVisibility = 'public',
    this.phoneVisibility = 'only_me',
    this.interests = const <String>[],
    this.photoUrls = const <String>[],
    this.heightCm,
    this.religion,
    this.education,
    this.diet,
    this.smoking,
    this.maritalStatus,
    this.zodiacSign,
    this.createdAt,
    this.updatedAt,
  });

  /// Maps to `profiles.id` (= `auth.users.id`).
  final String id;

  /// Maps to `profiles.full_name`.
  final String fullName;

  /// Maps to `profiles.birth_date` (date only).
  final DateTime? birthDate;

  /// One of [kGenders], or `null` while onboarding is unfinished.
  final String? gender;

  /// One of [kGenders] or `everyone`.
  final String interestedIn;

  final String bio;
  final String permanentAddress;
  final String currentLocation;

  /// Compatibility alias for older widgets and cached RPC payloads.
  String get city => currentLocation;
  final String occupation;

  /// Mobile number stored as plain profile data (no verification).
  final String phone;

  /// Who may see the exact date of birth / phone number.
  /// Values: `public`, `friends`, `only_me`.
  final String birthDateVisibility;
  final String phoneVisibility;

  /// Free-form tags chosen from [kInterests].
  final List<String> interests;

  /// Public URLs of uploaded photos; `photoUrls.first` is the main photo.
  final List<String> photoUrls;

  /// Height in centimetres (optional).
  final int? heightCm;

  /// One of [kReligions], or `null` when not set.
  final String? religion;

  /// One of [kEducations], or `null` when not set.
  final String? education;

  /// One of [kDiets] ('veg' / non-veg'), or `null` when not set.
  final String? diet;

  /// One of [kSmokings] ('smoker' / 'non_smoker'), or `null` when not set.
  final String? smoking;

  /// Marital status selected during onboarding.
  final String? maritalStatus;

  /// Zodiac sign label selected during onboarding.
  final String? zodiacSign;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Main photo used by cards, lists and avatars.
  String? get primaryPhoto => photoUrls.isEmpty ? null : photoUrls.first;

  /// Age in whole years, computed from [birthDate].
  int? get age {
    final DateTime? dob = birthDate;
    if (dob == null) return null;
    final DateTime now = DateTime.now();
    int years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years < 0 ? null : years;
  }

  /// Whether the user filled in everything needed to be discoverable.
  bool get isComplete =>
      fullName.trim().isNotEmpty &&
      birthDate != null &&
      gender != null &&
      age != null &&
      age! >= kMinAge &&
      photoUrls.isNotEmpty &&
      permanentAddress.trim().isNotEmpty &&
      currentLocation.trim().isNotEmpty &&
      occupation.trim().isNotEmpty &&
      maritalStatus != null &&
      zodiacSign != null &&
      bio.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      interests.isNotEmpty &&
      heightCm != null &&
      heightCm! >= 122 &&
      heightCm! <= 213 &&
      religion != null &&
      education != null &&
      diet != null &&
      smoking != null;

  /// Height shown as '5x7"' · 170 cm. Null when not set.
  String? get heightLabel {
    final int? cm = heightCm;
    if (cm == null) return null;
    final double totalInches = cm / 2.54;
    final int feet = totalInches ~/ 12;
    final int inches = (totalInches - feet * 12).round();
    return "'$feet'$inches · $cm cm";
  }

  /// Creates a copy with selected fields replaced.
  Profile copyWith({
    String? id,
    String? fullName,
    DateTime? birthDate,
    String? gender,
    String? interestedIn,
    String? bio,
    String? permanentAddress,
    String? currentLocation,
    String? city,
    String? occupation,
    String? phone,
    String? birthDateVisibility,
    String? phoneVisibility,
    List<String>? interests,
    List<String>? photoUrls,
    int? heightCm,
    String? religion,
    String? education,
    String? diet,
    String? smoking,
    String? maritalStatus,
    String? zodiacSign,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      interestedIn: interestedIn ?? this.interestedIn,
      bio: bio ?? this.bio,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      currentLocation: currentLocation ?? city ?? this.currentLocation,
      occupation: occupation ?? this.occupation,
      phone: phone ?? this.phone,
      birthDateVisibility: birthDateVisibility ?? this.birthDateVisibility,
      phoneVisibility: phoneVisibility ?? this.phoneVisibility,
      interests: interests ?? this.interests,
      photoUrls: photoUrls ?? this.photoUrls,
      heightCm: heightCm ?? this.heightCm,
      religion: religion ?? this.religion,
      education: education ?? this.education,
      diet: diet ?? this.diet,
      smoking: smoking ?? this.smoking,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Payload for an upsert; `id` must be the current user id.
  Map<String, dynamic> toUpsertJson() {
    return <String, dynamic>{
      'id': id,
      'full_name': fullName.trim(),
      'birth_date': birthDate == null ? null : _formatDate(birthDate!),
      'gender': gender,
      'interested_in': interestedIn,
      'bio': bio.trim(),
      'permanent_address': permanentAddress.trim(),
      'current_location': currentLocation.trim(),
      'occupation': occupation.trim(),
      'phone': phone.trim(),
      'birth_date_visibility': birthDateVisibility,
      'phone_visibility': phoneVisibility,
      'interests': interests,
      'photo_urls': photoUrls,
      'height_cm': heightCm,
      'religion': religion,
      'education': education,
      'diet': diet,
      'smoking': smoking,
      'marital_status': maritalStatus,
      'zodiac_sign': zodiacSign,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: (json['full_name'] as String?)?.trim() ?? '',
      birthDate: _parseDate(json['birth_date']),
      gender: json['gender'] as String?,
      interestedIn: (json['interested_in'] as String?) ?? kGenderEveryone,
      bio: (json['bio'] as String?) ?? '',
      permanentAddress: (json['permanent_address'] as String?) ?? '',
      currentLocation:
          (json['current_location'] as String?) ??
          (json['city'] as String?) ??
          '',
      occupation: (json['occupation'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      birthDateVisibility: _visibilityValue(json['birth_date_visibility']),
      phoneVisibility: _visibilityValue(json['phone_visibility']),
      interests: _parseStringList(json['interests']),
      photoUrls: _parseStringList(json['photo_urls']),
      heightCm: (json['height_cm'] as num?)?.toInt(),
      religion: json['religion'] as String?,
      education: json['education'] as String?,
      diet: json['diet'] as String?,
      smoking: json['smoking'] as String?,
      maritalStatus: json['marital_status'] as String?,
      zodiacSign: json['zodiac_sign'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  /// Format a DateTime to a string for the `updated_at` field.
  static String _formatDate(DateTime date) =>
      date.toIso8601String().split('T')[0];

  /// Parse a date-time string to a local DateTime (ignoring UTC Z suffix).
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is! String) return null;
    return DateTime.parse(value).toLocal();
  }

  /// Parse a list of strings from a JSON value; ignores nulls and empties.
  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return <String>[];
    return value
        .whereType<String>()
        .where((String s) => s.trim().isNotEmpty)
        .toList(growable: false);
  }

  static String _visibilityValue(dynamic value) =>
      const <String>{'public', 'friends', 'only_me'}.contains(value)
      ? value as String
      : 'public';
}

/// Kind of a story: a photo or a short written status.
enum StoryKind {
  photo('photo'),
  text('text');

  const StoryKind(this.value);

  /// Value persisted in Postgres.
  final String value;

  static StoryKind fromValue(String? value) {
    return value == 'text' ? StoryKind.text : StoryKind.photo;
  }
}

/// A row of the `stories` table (joined with the author's profile).
///
/// A story is fresh for 24 hours after [createdAt]; the backend view and RLS
/// only expose fresh rows, so expired stories simply disappear.
class Story {
  const Story({
    required this.id,
    required this.userId,
    required this.kind,
    this.mediaUrl,
    this.body = '',
    this.background = '#E8437E',
    required this.createdAt,
    this.expiresAt,
    this.authorName = '',
    this.authorPhoto,
  });

  /// Maps to `stories.id`.
  final String id;

  /// Maps to `stories.user_id`.
  final String userId;

  final StoryKind kind;

  /// Public URL of the photo; only set when [kind] is [StoryKind.photo].
  final String? mediaUrl;

  /// Written status; only set when [kind] is [StoryKind.text].
  final String body;

  /// Hex background colour for text stories (e.g. `#E8437E`).
  final String background;

  final DateTime createdAt;

  /// When the story disappears; defaults to 24h after [createdAt].
  final DateTime? expiresAt;

  /// Display name of the author (from the `stories_feed` view).
  final String authorName;

  /// Main photo of the author, if any.
  final String? authorPhoto;

  bool get isText => kind == StoryKind.text;

  /// Time left before the story disappears.
  Duration get remaining {
    final DateTime end = expiresAt ?? createdAt.add(const Duration(hours: 24));
    final Duration left = end.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  /// `true` while the story should still be shown.
  bool get isFresh => remaining > Duration.zero;

  /// Short label like `3h` or `20m` for the tray / viewer.
  String get remainingLabel {
    final Duration left = remaining;
    if (left <= Duration.zero) return 'expired';
    if (left.inHours >= 1) return '${left.inHours}h';
    if (left.inMinutes >= 1) return '${left.inMinutes}m';
    return 'now';
  }

  /// Create a [Story] from a row of the `stories_feed` view.
  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      kind: StoryKind.fromValue(json['kind'] as String?),
      mediaUrl: json['media_url'] as String?,
      body: (json['body'] as String?)?.trim() ?? '',
      background: (json['background'] as String?) ?? '#E8437E',
      createdAt: _parseDate(json['created_at']),
      expiresAt: json['expires_at'] != null
          ? _parseDateTime(json['expires_at'] as String)
          : null,
      authorName: (json['author_name'] as String?)?.trim() ?? '',
      authorPhoto: json['author_photo'] as String?,
    );
  }

  /// Parse a date-time string to a local DateTime.
  static DateTime _parseDateTime(String value) {
    return DateTime.parse(value).toLocal();
  }

  /// Parse a date-time string to a local DateTime.
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is! String) return DateTime.now();
    return DateTime.parse(value).toLocal();
  }
}

/// A single chat message.
class Message {
  const Message({
    required this.id,
    required this.matchId,
    required this.senderId,
    this.body = '',
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String matchId;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final bool isRead;

  /// Create a [Message] from a row of the `messages` table.
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      senderId: json['sender_id'] as String,
      body: (json['body'] as String?)?.trim() ?? '',
      createdAt: _parseDate(json['created_at']),
      isRead: json['read_at'] != null,
    );
  }

  /// Parse a date-time string to a local DateTime.
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is! String) return DateTime.now();
    return DateTime.parse(value).toLocal();
  }
}

/// A match between two users.
class Match {
  const Match({
    required this.id,
    required this.createdAt,
    required this.userA,
    required this.userB,
    this.lastMessage,
    this.unreadCount = 0,
    required this._currentUserId,
  });

  /// Maps to `matches.id`.
  final String id;

  /// Maps to `matches.created_at`.
  final DateTime createdAt;

  /// The participant with the lower id.
  final Profile userA;

  /// The participant with the higher id.
  final Profile userB;

  /// The most recent message, if any.
  final Message? lastMessage;

  /// Number of unread messages (from the `matches_with_details` view).
  final int unreadCount;

  /// User id of the current user (must be set before calling [other]).
  final String? _currentUserId;

  /// The other participant (not the given user).
  Profile get other {
    if (_currentUserId == null) return userA;
    if (userA.id == _currentUserId) return userB;
    return userA;
  }

  /// Parse a date-time string to a local DateTime.
  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is! String) return DateTime.now();
    return DateTime.parse(value).toLocal();
  }

  /// Create a [Match] from a row of the `matches_with_details` view.
  factory Match.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    return Match(
      id: json['id'] as String,
      createdAt: _parseDate(json['created_at']),
      userA: Profile.fromJson(json['user_a'] as Map<String, dynamic>),
      userB: Profile.fromJson(json['user_b'] as Map<String, dynamic>),
      lastMessage: json['last_message'] != null
          ? _unwrapLastMessage(json['last_message'])
          : null,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      currentUserId: currentUserId,
    );
  }

  /// Unwrap a last_message that may be an embedded array.
  static Message? _unwrapLastMessage(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      final first = value.firstOrNull;
      if (first is Map<String, dynamic>) {
        return Message.fromJson(first);
      }
    } else if (value is Map<String, dynamic>) {
      return Message.fromJson(value);
    }
    return null;
  }
}

/// Kind of a swipe: pass, like, super-like, or a connection request.
enum SwipeDirection {
  pass('pass'),
  like('like'),
  superLike('super_like'),
  request('request');

  const SwipeDirection(this.value);

  /// Value persisted in Postgres.
  final String value;

  static SwipeDirection fromValue(String? value) {
    switch (value) {
      case 'like':
        return SwipeDirection.like;
      case 'super_like':
        return SwipeDirection.superLike;
      case 'request':
        return SwipeDirection.request;
      default:
        return SwipeDirection.pass;
    }
  }

  bool get isPositive =>
      this == SwipeDirection.like || this == SwipeDirection.superLike;

  bool get isRequest => this == SwipeDirection.request;
}

/// Result returned when recording a swipe.
class SwipeResult {
  const SwipeResult({required this.matched, this.matchId});
  final bool matched;
  final String? matchId;
}

/// Type of an actionable notification.
enum NotificationType {
  like('like'),
  request('request'),
  match('match');

  const NotificationType(this.value);

  final String value;

  static NotificationType fromValue(String? value) {
    switch (value) {
      case 'request':
        return NotificationType.request;
      case 'match':
        return NotificationType.match;
      default:
        return NotificationType.like;
    }
  }
}

/// A row of the `notifications` table.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.actor,
  });

  final String id;
  final String userId;

  /// The user who caused this notification (liked / requested / matched).
  final String actorId;

  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  /// The actor's profile, joined in when available.
  final Profile? actor;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final dynamic actorJson = json['actor'];
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      actorId: json['actor_id'] as String,
      type: NotificationType.fromValue(json['type'] as String?),
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: _parseDate(json['created_at']),
      actor: actorJson is Map<String, dynamic>
          ? Profile.fromJson(actorJson)
          : null,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is! String) return DateTime.now();
    return DateTime.parse(value).toLocal();
  }
}
