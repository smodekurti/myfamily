# ⚡ Quick Key Rotation Checklist

Use this as a quick reference while rotating keys.

## 🔥 Firebase Keys

### Current Keys (to be rotated):
- Web: `AIzaSyBUZxnDR77kIrrqeBkX1hJI0l8DN5TmoAM`
- Android: `AIzaSyACO267gaBdgFAcXAXCaHN_MHSNSxkktjU`
- iOS: `AIzaSyDdhk0ZL-oZDvqOsLjTqNR2mpNiPEP5J1s`
- macOS: `AIzaSyDdhk0ZL-oZDvqOsLjTqNR2mpNiPEP5J1s`

### Steps:
1. [ ] Go to Firebase Console → Project Settings → General
2. [ ] For each platform, either:
   - Restrict keys in Google Cloud Console, OR
   - Generate new keys and update apps
3. [ ] Run `flutterfire configure` OR manually update `lib/firebase_options.dart`
4. [ ] Download and place config files:
   - [ ] `android/app/google-services.json`
   - [ ] `ios/Runner/GoogleService-Info.plist`
   - [ ] `macos/Runner/GoogleService-Info.plist`
5. [ ] Test: `flutter run`

## 🗄️ Supabase Keys

### Current Keys (to be rotated):
- URL: `https://vovfhxnmiximhzdjadvu.supabase.co`
- Anon Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvdmZoeG5taXhpbWh6ZGphZHZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA0MTMxMDUsImV4cCI6MjA3NTk4OTEwNX0.-iUAJjbjlzpyEF961n4bmvznFXtkx2S4WftDNNy2Vvg`

### Steps:
1. [ ] Go to Supabase Dashboard → Settings → API
2. [ ] Decide: Rotate anon key? (Usually not needed, but recommended if exposed)
3. [ ] If rotating: Click "Reset" on anon key, copy new key
4. [ ] Update `lib/app/core/config/supabase_config.dart`:
   ```dart
   defaultValue: 'YOUR_NEW_ANON_KEY_HERE'
   ```
5. [ ] Test: `flutter run`

## ✅ Final Verification

- [ ] All config files exist locally (not in git)
- [ ] `git status` shows no sensitive files
- [ ] App builds: `flutter build`
- [ ] App runs: `flutter run`
- [ ] Authentication works
- [ ] Database/API calls work
- [ ] Push notifications work (if applicable)

## 📤 Share with Team

- [ ] Keys stored in password manager
- [ ] Team notified via secure channel
- [ ] Instructions shared (link to ROTATE_KEYS_GUIDE.md)


