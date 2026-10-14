# Milan — Flutter + Supabase डेटिङ/म्याचिङ एप

एउटै कोडबाट **Android, iOS र Web** तीनवटै प्लेटफर्ममा चल्ने म्याचिङ एपको MVP।

```
milan_app/
├── lib/
│   ├── main.dart                  # entry point (Supabase init)
│   ├── app/                       # root widget + go_router routes
│   ├── core/                      # theme, shared widgets, constants
│   ├── data/
│   │   ├── models.dart            # Profile, Match, Message, SwipeDirection
│   │   ├── *_repository.dart      # auth / profile / discover / match / storage
│   │   └── providers.dart         # Riverpod providers
│   └── features/                  # feature-first UI
│       ├── auth/   splash/  onboarding/
│       ├── discover/  matches/  chat/  profile/  shell/
├── supabase/
│   └── schema.sql                 # tables + RLS + RPC + storage
├── test/                          # unit tests
└── env.example.json               # copy to env.json
```

## १. Supabase सेटअप

1. [supabase.com](https://supabase.com) मा नयाँ प्रोजेक्ट बनाउनुहोस्।
2. Dashboard → **SQL Editor** → `supabase/schema.sql` को पूरा सामग्री paste गरेर **Run** गर्नुहोस्।
   यसले बनाउँछ:
   - `profiles`, `swipes`, `matches`, `messages` टेबल
   - Row Level Security नीति (हरेक प्रयोगकर्ता आफ्नै डाटा मात्र)
   - `discover_profiles()` र `record_swipe()` फङ्सन
   - `matches_with_details` view (च्याट लिस्टको लागि)
   - `profile-photos` स्टोरेज बकेट + नीति
3. Dashboard → **Authentication → Providers** मा Email provider सक्रिय छ भनी निश्चित गर्नुहोस्।
   (सुरुमा "Confirm email" बन्द राख्नुहोस् भने तुरन्तै लगइन हुन्छ।)
4. Project Settings → **API** बाट `URL` र `anon/publishable key` लिनुहोस्।

## २. एप चलाउने तरिका

```bash
# १) क्रेडेन्सियल फाइल बनाउनुहोस्
cp env.example.json env.json
#    त्यसपछि env.json मा आफ्नो URL र key राख्नुहोस् (Git मा जाँदैन)

# २) प्याकेज इन्स्टल
flutter pub get

# ३.१) Chrome मा (web)
flutter run -d chrome --dart-define-from-file=env.json

# ३.२) Android / iOS
flutter run --dart-define-from-file=env.json

# ३.३) रिलिज APK
flutter build apk --release --dart-define-from-file=env.json
```

> **नोट:** `--dart-define-from-file` नदिएमा एप खुल्दा "Connect Supabase" सन्देश देखाउँछ —
> कुनै पनि key कोडभित्र हार्डकोड गरिएको छैन।

## ३. परीक्षण

```bash
flutter analyze     # स्थिर विश्लेषण — "No issues found"
flutter test        # १९ unit test
```

## ४. हालका फिचरहरू (MVP)

| फिचर | विवरण |
|---|---|
| Authentication | Email + password, sign up, password reset |
| Onboarding | ४ चरण: नाम/लिङ्ग → जन्म मिति (१८+) → फोटो → बायो/रुचि |
| Discover | Tinder-जस्तै स्वाइप, उमेर/लिङ्ग/सहर/रुचि फिल्टर, undo |
| Matching | दुईतर्फी like मिलेपछि स्वतः match + सेलिब्रेसन डायलग |
| Chat | Realtime सन्देश, unread ब्याज, unmatch |
| Profile | आफ्नो प्रोफाइल हेर्ने, सम्पादन, logout |

## ५. सुरक्षा

- सबै टेबलमा **Row Level Security** सक्रिय; हरेक नीति `auth.uid()` मा आधारित।
- फोटो `<userId>/…` फोल्डरमा मात्र अपलोड सकिन्छ (`storage.foldername` जाँच)।
- `record_swipe()` `security definer` — म्याच निर्णय DB मै हुन्छ, क्लायन्टमा होइन।
- कुनै पनि key `env.json` (Git ignore) मा रहन्छ।

## ६. अघि बढाउने क्रम

- [ ] ब्लक / रिपोर्ट
- [ ] Push notification (Firebase)
- [ ] Super like (स्वाइप मा अहिले UI मात्र छ)
- [ ] फोटो verification
- [ ] Multi-photo gallery in chat
- [ ] नेपाली/अंग्रेजी भाषा टगल
