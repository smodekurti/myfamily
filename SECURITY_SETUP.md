# Local service configuration

Firebase client configuration is generated locally and is not stored in Git.

1. Install the Firebase CLI and FlutterFire CLI.
2. Sign in with `firebase login`.
3. Run `flutterfire configure` from this repository.
4. For web push, copy `web/firebase-messaging-sw.example.js` to `web/firebase-messaging-sw.js` and insert the web-app configuration from Firebase Console.
5. In Google Cloud Console, restrict every generated key to the matching Android package, iOS bundle ID, or web origin and allow only the APIs the app needs.

Never enable paid Google APIs on an unrestricted Firebase-generated key. Store server credentials in the deployment platform's secret manager.

Supply Supabase client configuration when building:

```sh
flutter build ios --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

The anon key is a client identifier, so enforce Row Level Security on every exposed table and storage bucket.
