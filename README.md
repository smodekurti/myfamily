# MyFamily - Family Hub

A playful, cross-platform family management app that makes day-to-day coordination effortless—tasks, calendar, groceries, finances, and habits—gamified to reduce friction.

## 🎯 Features

### ✅ Implemented (v1.0)
- **Authentication & Family Setup**
  - Firebase Authentication with Google Sign-In
  - Apple Sign-In support (iOS)
  - Create or join family with invite codes
  - User profile management

- **Responsive UI Framework**
  - Material 3 design system
  - Light/Dark/System theme modes
  - Responsive breakpoints (mobile/tablet/desktop)
  - Text scaling clamp (0.9-1.3)
  - No hardcoded values - all responsive

- **Navigation & Routing**
  - Bottom navigation with 5 main tabs
  - Go Router for deep linking
  - Protected routes with authentication guards

### 🚧 In Development
- **Tasks & Chores Management**
- **Family Calendar & Events**
- **Grocery Master Lists & Trip Flow**
- **Gamification & Leaderboards**
- **Family Chat & Notifications**

## 🏗️ Architecture

### Tech Stack
- **Flutter** (latest stable)
- **State Management:** Riverpod with hooks_riverpod
- **Routing:** go_router
- **Backend:** Firebase (Auth, Firestore, Functions, Storage)
- **UI Framework:** Material 3 with flutter_screenutil
- **Responsive:** responsive_framework with custom breakpoints
- **Data Models:** Freezed with JSON serialization

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

3. **Firebase Setup**
   ```bash
   # Follow the detailed setup guide
   cat scripts/firebase_bootstrap.md
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Configuration

The Firebase project is pre-configured with:
- **Project ID:** `myfamily-e897d`
- **Storage Bucket:** `myfamily-e897d.firebasestorage.app`

Configuration files are already included:
- `ios/Runner/GoogleService-Info.plist`
- `android/app/google-services.json`

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

### Golden Tests
```bash
# Run golden tests at key breakpoints
flutter test test/golden/
```

### Unit Tests
```bash
flutter test test/unit/
```

### Widget Tests
```bash
flutter test test/widget/
```

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

## 📋 Roadmap

### Phase 1 (Current)
- [x] Authentication & Family Setup
- [x] Basic UI Framework
- [x] Navigation Structure
- [x] Home Dashboard

### Phase 2 (Next)
- [ ] Tasks & Chores Management
- [ ] Calendar & Events
- [ ] Grocery Master Lists
- [ ] Basic Gamification

### Phase 3 (Future)
- [ ] Advanced Grocery Trip Flow
- [ ] Family Chat & Notifications
- [ ] Financial Tracking
- [ ] Advanced Gamification & Leaderboards

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in this repository
- Check the [Firebase Bootstrap Guide](scripts/firebase_bootstrap.md)
- Review the [Architecture Documentation](architecture.mdc)
- Read the [Product Requirements](prd.mdc)

---

Built with ❤️ using Flutter and Firebase
# myfamily
