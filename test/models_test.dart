import 'package:flutter_test/flutter_test.dart';
import 'package:milan_app/data/models.dart';

void main() {
  group('Profile.fromJson', () {
    test('parses every field including Postgres text[] arrays', () {
      final Profile profile = Profile.fromJson(<String, dynamic>{
        'id': 'u-1',
        'full_name': '  Aayush  ',
        'birth_date': '1998-04-05',
        'gender': 'male',
        'marital_status': 'Unmarried',
        'zodiac_sign': 'Aries (मेष)',
        'interested_in': 'female',
        'bio': 'Hello',
        'permanent_address': 'Home in Kathmandu',
        'current_location': 'Pokhara, Nepal',
        'occupation': 'Engineer',
        'interests': <dynamic>['Trekking', 'Music'],
        'photo_urls': <dynamic>['https://cdn/1.jpg', 'https://cdn/2.jpg'],
        'created_at': '2026-01-02T03:04:05Z',
      });

      expect(profile.id, 'u-1');
      expect(profile.fullName, 'Aayush'); // trimmed
      expect(profile.gender, 'male');
      expect(profile.maritalStatus, 'Unmarried');
      expect(profile.zodiacSign, 'Aries (मेष)');
      expect(profile.permanentAddress, 'Home in Kathmandu');
      expect(profile.currentLocation, 'Pokhara, Nepal');
      expect(profile.interestedIn, 'female');
      expect(profile.interests, <String>['Trekking', 'Music']);
      expect(profile.photoUrls.length, 2);
      expect(profile.primaryPhoto, 'https://cdn/1.jpg');
      // A date-only string parses as local midnight, not UTC.
      expect(profile.birthDate, DateTime(1998, 4, 5));
    });

    test('falls back to safe defaults for missing keys', () {
      final Profile profile = Profile.fromJson(<String, dynamic>{'id': 'u-2'});

      expect(profile.fullName, '');
      expect(profile.birthDate, isNull);
      expect(profile.gender, isNull);
      expect(profile.interestedIn, 'everyone');
      expect(profile.interests, isEmpty);
      expect(profile.photoUrls, isEmpty);
      expect(profile.age, isNull);
    });

    test('ignores empty strings inside text[] columns', () {
      final Profile profile = Profile.fromJson(<String, dynamic>{
        'id': 'u-3',
        'interests': <dynamic>['Music', '', null],
        'photo_urls': <dynamic>['a.jpg'],
      });

      expect(profile.interests, <String>['Music']);
    });
  });

  group('Profile.age', () {
    test('does not count a birthday that has not happened yet', () {
      final DateTime now = DateTime.now();
      // Yesterday, last year: the birthday has already passed this year.
      final Profile past = Profile(
        id: 'u-1',
        fullName: 'A',
        birthDate: DateTime(now.year - 30, 1, 1),
      );
      expect(past.age, greaterThanOrEqualTo(30));

      final Profile future = Profile(
        id: 'u-2',
        fullName: 'B',
        birthDate: DateTime(now.year - 20, 12, 31),
      );
      expect(future.age, lessThanOrEqualTo(20));
    });

    test('returns a non-negative age for a same-day birth date', () {
      final Profile profile = Profile(
        id: 'u-3',
        fullName: 'C',
        birthDate: DateTime.now(),
      );

      expect(profile.age, greaterThanOrEqualTo(0));
    });
  });

  group('Profile.isComplete', () {
    test('is false while any required piece is missing', () {
      expect(
        Profile(
          id: '1',
          fullName: '',
          birthDate: DateTime(1990),
          gender: 'male',
          photoUrls: const <String>['a.jpg'],
        ).isComplete,
        isFalse,
        reason: 'missing name',
      );
      expect(
        Profile(
          id: '1',
          fullName: 'A',
          birthDate: DateTime(1990),
          gender: null,
          photoUrls: const <String>['a.jpg'],
        ).isComplete,
        isFalse,
        reason: 'missing gender',
      );
      expect(
        Profile(
          id: '1',
          fullName: 'A',
          birthDate: null,
          gender: 'male',
          photoUrls: const <String>['a.jpg'],
        ).isComplete,
        isFalse,
        reason: 'missing birth date',
      );
      expect(
        Profile(
          id: '1',
          fullName: 'A',
          birthDate: DateTime(1990),
          gender: 'male',
        ).isComplete,
        isFalse,
        reason: 'missing photo',
      );
    });

    test('is true when name, birth date, gender and a photo are present', () {
      expect(
        Profile(
          id: '1',
          fullName: 'A',
          birthDate: DateTime(1990),
          gender: 'male',
          photoUrls: const <String>['a.jpg'],
        ).isComplete,
        isTrue,
      );
    });
  });

  group('Profile.toUpsertJson', () {
    test('emits snake_case keys and a yyyy-MM-dd birth date', () {
      final Profile profile = Profile(
        id: 'u-9',
        fullName: ' A ',
        birthDate: DateTime(1999, 3, 7),
        gender: 'female',
        bio: ' hi ',
        interests: const <String>['Music'],
        photoUrls: const <String>['a.jpg'],
      );

      final Map<String, dynamic> json = profile.toUpsertJson();

      expect(json['id'], 'u-9');
      expect(json['full_name'], 'A');
      expect(json['bio'], 'hi');
      expect(json['birth_date'], '1999-03-07');
      expect(json['gender'], 'female');
      expect(json['marital_status'], isNull);
      expect(json['zodiac_sign'], isNull);
      expect(json['permanent_address'], '');
      expect(json['current_location'], '');
      expect(json['interests'], <String>['Music']);
      expect(json['photo_urls'], <String>['a.jpg']);
      expect(json.containsKey('updated_at'), isTrue);
    });
  });

  group('SwipeDirection', () {
    test('maps database values back to the enum', () {
      expect(SwipeDirection.fromValue('like'), SwipeDirection.like);
      expect(SwipeDirection.fromValue('super_like'), SwipeDirection.superLike);
      expect(SwipeDirection.fromValue('pass'), SwipeDirection.pass);
      expect(SwipeDirection.fromValue(null), SwipeDirection.pass);
    });

    test('knows which directions count as positive', () {
      expect(SwipeDirection.like.isPositive, isTrue);
      expect(SwipeDirection.superLike.isPositive, isTrue);
      expect(SwipeDirection.pass.isPositive, isFalse);
    });
  });

  group('Message.fromJson', () {
    test('reads nested snake_case columns and converts to local time', () {
      final Message message = Message.fromJson(<String, dynamic>{
        'id': 'm-1',
        'match_id': 'match-1',
        'sender_id': 'u-1',
        'body': 'Hi there',
        'created_at': '2026-02-03T10:00:00Z',
        'read_at': null,
      });

      expect(message.matchId, 'match-1');
      expect(message.senderId, 'u-1');
      expect(message.body, 'Hi there');
      expect(message.isRead, isFalse);
      expect(message.createdAt.isUtc, isFalse);
    });

    test('treats a null body as an empty string', () {
      final Message message = Message.fromJson(<String, dynamic>{
        'id': 'm-2',
        'match_id': 'match-1',
        'sender_id': 'u-1',
        'body': null,
        'created_at': '2026-02-03T10:00:00Z',
      });

      expect(message.body, '');
    });
  });

  group('Match.fromJson', () {
    test('picks the other participant for either ordering', () {
      final Map<String, dynamic> row = <String, dynamic>{
        'id': 'match-1',
        'created_at': '2026-02-03T10:00:00Z',
        'user_a': <String, dynamic>{'id': 'me', 'full_name': 'Me'},
        'user_b': <String, dynamic>{'id': 'them', 'full_name': 'Them'},
      };

      final Match match = Match.fromJson(row, currentUserId: 'me');

      expect(match.other.id, 'them');
      expect(match.other.fullName, 'Them');
      expect(match.lastMessage, isNull);
      expect(match.unreadCount, 0);
    });

    test('unwraps an embedded one-element last_message array', () {
      final Map<String, dynamic> row = <String, dynamic>{
        'id': 'match-2',
        'created_at': '2026-02-03T10:00:00Z',
        'user_a': <String, dynamic>{'id': 'me', 'full_name': 'Me'},
        'user_b': <String, dynamic>{'id': 'them', 'full_name': 'Them'},
        'last_message': <dynamic>[
          <String, dynamic>{
            'id': 'm-9',
            'match_id': 'match-2',
            'sender_id': 'them',
            'body': 'Hello!',
            'created_at': '2026-02-04T10:00:00Z',
          },
        ],
        'unread_count': 3,
      };

      final Match match = Match.fromJson(row, currentUserId: 'me');

      expect(match.lastMessage?.body, 'Hello!');
      expect(match.unreadCount, 3);
    });
  });

  group('Story.fromJson', () {
    test('parses a photo story with author details', () {
      final Story story = Story.fromJson(<String, dynamic>{
        'id': 's-1',
        'user_id': 'u-1',
        'kind': 'photo',
        'media_url': 'https://cdn/story.jpg',
        'body': '',
        'background': '#E8437E',
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 23))
            .toIso8601String(),
        'author_name': 'Aayush',
        'author_photo': 'https://cdn/1.jpg',
      });

      expect(story.kind, StoryKind.photo);
      expect(story.isText, isFalse);
      expect(story.mediaUrl, 'https://cdn/story.jpg');
      expect(story.authorName, 'Aayush');
      expect(story.isFresh, isTrue);
    });

    test('an old story is not fresh', () {
      final Story story = Story.fromJson(<String, dynamic>{
        'id': 's-2',
        'user_id': 'u-2',
        'kind': 'text',
        'body': 'Hello world',
        'created_at': DateTime.now()
            .toUtc()
            .subtract(const Duration(hours: 25))
            .toIso8601String(),
        'expires_at': DateTime.now()
            .toUtc()
            .subtract(const Duration(hours: 1))
            .toIso8601String(),
      });

      expect(story.kind, StoryKind.text);
      expect(story.isText, isTrue);
      expect(story.isFresh, isFalse);
      expect(story.remainingLabel, 'expired');
    });

    test('remaining label shortens hours and minutes', () {
      final Story hours = Story(
        id: 's-3',
        userId: 'u-1',
        kind: StoryKind.text,
        body: 'hi',
        createdAt: DateTime.now().subtract(const Duration(hours: 21)),
        expiresAt: DateTime.now().add(const Duration(hours: 3)),
      );
      expect(hours.remainingLabel, '3h');

      final Story minutes = Story(
        id: 's-4',
        userId: 'u-1',
        kind: StoryKind.text,
        body: 'hi',
        createdAt: DateTime.now().subtract(
          const Duration(hours: 23, minutes: 40),
        ),
        expiresAt: DateTime.now().add(const Duration(minutes: 20)),
      );
      expect(minutes.remainingLabel, '20m');
    });
  });

  group('StoryKind', () {
    test('maps database values back to the enum', () {
      expect(StoryKind.fromValue('text'), StoryKind.text);
      expect(StoryKind.fromValue('photo'), StoryKind.photo);
      expect(StoryKind.fromValue(null), StoryKind.photo);
    });
  });
}
