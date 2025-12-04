# MyFamily - Family Hub

A playful, cross-platform family management app that makes day-to-day coordination effortless—tasks, calendar, groceries, finances, and habits—gamified to reduce friction.

## 🎯 Features

### ✅ Fully Implemented (v1.0)

- **Authentication & Onboarding**
  - Google Sign-In (iOS & Android)
  - Apple Sign-In (iOS)
  - Email/Password authentication
  - Consent screen with version tracking
  - User profile creation and management

- **Family Management**
  - Create family with invite codes
  - Join family with adult/child invite codes
  - Family selection and switching
  - Family settings and member management
  - Role-based access control (Parent, Caretaker, Guardian, Member, Child)

- **Tasks & Chores**
  - Create, edit, and assign tasks
  - Task categories (Chore, Grocery)
  - Due dates and priorities
  - Task completion with points
  - Real-time task updates
  - Task filtering (All, My Chores, Due Today, Completed)

- **Grocery Management**
  - Create shopping lists (standalone & task-linked)
  - Shopping templates
  - Import items from templates
  - Categorize items
  - Check/uncheck items
  - List and category views

- **Calendar & Events**
  - Monthly, week, day, and list views
  - Create, edit, and delete events
  - Event participants
  - Event colors
  - Filter events by member

- **Gamification**
  - Points system (awarded on task completion)
  - Weekly and all-time leaderboards
  - Points history tracking
  - Achievements system

- **Notifications**
  - Push notifications (FCM)
  - Local notifications (fallback)
  - Real-time data refresh
  - Notification preferences

- **Settings & Support**
  - Theme selection (Light/Dark/System)
  - Notification preferences
  - Account settings
  - Help & Support page with FAQ
  - App version information

- **Responsive UI**
  - Material 3 design system
  - Light/Dark/System theme modes
  - Responsive breakpoints (mobile/tablet/desktop)
  - Text scaling clamp (0.9-1.3)
  - No hardcoded values - fully responsive

## 🏗️ Architecture

### Tech Stack
- **Flutter** (3.9.2+)
- **State Management:** Riverpod (flutter_riverpod)
- **Routing:** go_router
- **Backend:** Supabase (Database, Auth, Storage, Realtime)
- **Push Notifications:** Firebase Cloud Messaging (FCM)
- **UI Framework:** Material 3 with flutter_screenutil
- **Responsive:** Custom ResponsiveHelper with breakpoints
- **Data Models:** Freezed with JSON serialization
- **Biometric Auth:** local_auth (Face ID, Touch ID, Fingerprint)

### Project Structure
```
lib/
├── app/
│   ├── core/
│   │   ├── providers/     # Riverpod providers
│   │   ├── router/        # App routing configuration
│   │   └── theme/         # Material 3 theming
│   ├── features/
│   │   ├── auth/          # Authentication flow
│   │   ├── family/        # Family setup & management
│   │   ├── home/          # Dashboard & summary
│   │   ├── tasks/         # Task management
│   │   ├── groceries/     # Grocery lists & trips
│   │   ├── calendar/      # Events & scheduling
│   │   ├── gamification/  # Points & leaderboards
│   │   └── profile/       # User profile & settings
│   ├── common/
│   │   ├── widgets/       # Reusable UI components
│   │   ├── utils/         # Helper functions
│   │   └── responsive/    # Responsive design helpers
│   └── data/
│       ├── models/        # Freezed data models
│       ├── repositories/  # Data layer abstraction
│       └── sources/       # Firebase & local data sources
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Firebase CLI
- iOS Simulator or Android Emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd myfamily
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a Supabase project at https://supabase.com
   - Get your project URL and anon key from Settings > API
   - Update `lib/app/core/config/supabase_config.dart` with your credentials
   - OR use environment variables:
     ```bash
     flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=...
     ```

4. **Set up Database**
   - Run SQL migration scripts in order (see `DATABASE_MIGRATIONS.md`)
   - Enable Realtime for tables that need live updates
   - Set up RLS policies (see `PRODUCTION_RLS_POLICIES.sql`)

5. **Configure Firebase (for Push Notifications)**
   - Create a Firebase project
   - Add iOS and Android apps
   - Download and place configuration files:
     - `ios/Runner/GoogleService-Info.plist`
     - `android/app/google-services.json`
   - Set up FCM server key (see `PUSH_NOTIFICATIONS_SETUP.md`)

6. **Run the app**
   ```bash
   flutter run
   ```

For detailed setup instructions, see `DEVELOPER_GUIDE.md`.

## 🎨 Design System

### Responsive Breakpoints
- **Mobile:** ≤450dp
- **Large Phone:** 401-599dp  
- **Tablet:** ≥600dp
- **Desktop:** ≥801dp

### Color Palette
- **Primary:** Red (#E53E3E)
- **Secondary:** Blue (#3182CE)
- **Surface:** Light Gray (#F7FAFC)
- **Error:** Red (#E53E3E)

### Typography
- **Font Family:** Inter
- **Text Scaling:** Clamped between 0.9-1.3
- **Responsive Sizing:** Using flutter_screenutil (.w/.h/.sp)

## 📱 Screenshots

The app UI follows the provided screenshots with:
- Clean, modern Material 3 design
- Consistent spacing and typography
- Responsive layouts for all screen sizes
- Light/Dark theme support
- Bottom navigation with 5 main sections

## 🧪 Testing

See `test/README.md` for comprehensive testing guide.

### Run All Tests
```bash
flutter test
```

### Run Specific Test Types
```bash
# Unit tests
flutter test test/unit/

# Widget tests
flutter test test/widget/

# Golden tests (visual regression)
flutter test test/golden/
```

### Test Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Test Structure
- **Unit Tests** (`test/unit/`) - Business logic, repositories, services
- **Widget Tests** (`test/widget/`) - UI components, pages, user interactions
- **Golden Tests** (`test/golden/`) - Visual regression at breakpoints (320, 390, 480, 600, 840)

## 🔧 Development

### Code Generation
```bash
# Generate Freezed models and JSON serialization
flutter packages pub run build_runner build

# Watch for changes during development
flutter packages pub run build_runner watch
```

### Firebase Emulators
```bash
# Start Firebase emulators for local development
firebase emulators:start

# Run tests with emulators
flutter test --dart-define=USE_FIREBASE_EMULATOR=true
```

### Deployment
```bash
# Deploy to Firebase App Distribution
firebase appdistribution:distribute \
  --app YOUR_APP_ID \
  --groups "testers" \
  --file build/app/outputs/flutter-apk/app-release.apk
```

## 📋 Current Status

### ✅ Completed (v1.0)
- [x] Authentication & Family Setup
- [x] Tasks & Chores Management
- [x] Calendar & Events
- [x] Grocery Lists & Templates
- [x] Gamification & Leaderboards
- [x] Push Notifications
- [x] Settings & Help Pages
- [x] Role-Based Access Control
- [x] Real-time Data Sync
- [x] Responsive UI Framework

### 🚀 Future Enhancements (v1.1+)
- [ ] Family Chat
- [ ] Recurring Tasks
- [ ] Advanced Grocery Trip Flow
- [ ] Financial Tracking
- [ ] Weather Widget on Home
- [ ] Offline Support
- [ ] Map Picker for Addresses

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📚 Documentation

- **[Developer Guide](DEVELOPER_GUIDE.md)** - Complete setup and development guide
- **[Testing Guide](test/README.md)** - How to write and run tests
- **[Database Migrations](DATABASE_MIGRATIONS.md)** - SQL migration scripts
- **[Release Checklist](RELEASE_1.0_CHECKLIST.md)** - Feature completion status
- **[Architecture](architecture.mdc)** - System architecture overview
- **[Product Requirements](prd.mdc)** - Product specification

## 🆘 Support

For support and questions:
- Check the [Developer Guide](DEVELOPER_GUIDE.md) for setup help
- Review [Troubleshooting](#troubleshooting) section
- Create an issue in this repository
- Check existing documentation files in the project root

---

Built with ❤️ using Flutter and Firebase
# myfamily
