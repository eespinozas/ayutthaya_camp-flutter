# Ayutthaya Camp

A Flutter-based gym and fitness class scheduler application that allows users to book classes, manage their schedule, track payments, and manage their gym membership.

## Features

### Core Functionality
- **User Authentication** - Firebase Auth integration with custom backend
- **Class Scheduling** - Book and manage fitness classes
- **Class Management** - View your booked classes and upcoming sessions
- **Payment Tracking** - Monitor payment history and transactions
- **Profile Management** - Update and manage user profile information
- **Multi-location Support** - Support for multiple gym locations (escuelas)

### User Interface
- Bottom navigation bar with 5 main sections:
  - **Inicio** (Home) - Dashboard with KPIs and overview
  - **Agendar** - Schedule new classes
  - **Mis Clases** - View your booked classes
  - **Pagos** - Payment history
  - **Mi Perfil** - User profile
- Light and dark theme support
- Custom branded UI with orange accent colors

## Tech Stack

### Frontend
- **Flutter** ^3.9.2 - Cross-platform mobile framework
- **Provider** ^6.1.5 - State management
- **Cupertino Icons** ^1.0.8 - iOS-style icons

### Backend Integration
- **Firebase Core** ^3.5.0
- **Firebase Auth** ^5.3.1 - Authentication
- **Cloud Firestore** ^5.4.4 - Database
- **HTTP** ^1.5.0 - REST API communication

### Development Tools
- **Flutter Lints** ^5.0.0 - Code analysis
- **Flutter DotEnv** ^5.1.0 - Environment configuration
- **Rename** ^3.1.0 - App renaming utility

## Architecture

The project follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── app/                    # App initialization and configuration
│   ├── app.dart           # Main app widget with providers
│   └── theme.dart         # Theme configuration
├── core/                   # Core utilities and shared code
│   ├── api_client.dart    # HTTP client
│   ├── config.dart        # App configuration
│   └── widgets/           # Shared widgets
├── features/              # Feature modules
│   ├── auth/             # Authentication feature
│   │   ├── data/         # Data layer (API, repositories)
│   │   ├── domain/       # Domain layer (entities, repositories)
│   │   └── presentation/ # UI layer (pages, viewmodels)
│   ├── dashboard/        # Dashboard/home feature
│   ├── escuelas/         # Gym locations feature
│   └── shell/            # App shell/navigation
└── main.dart             # App entry point
```

### Layers
- **Data Layer** - API clients, DTOs, repository implementations
- **Domain Layer** - Business logic, entities, repository interfaces
- **Presentation Layer** - UI pages, widgets, ViewModels (using Provider)

## Getting Started

### Prerequisites
- Flutter SDK ^3.9.2
- Dart SDK ^3.9.2
- Firebase project configured
- Backend API server

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd ayutthaya_camp
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure environment variables

Create a `.env` file in the project root:
```env
API_BASE_URL=http://your-backend-url:3000
```

4. Configure Firebase

Make sure `firebase_options.dart` is properly configured with your Firebase project settings.

5. Run the app
```bash
flutter run
```

## Configuration

### Environment Variables
- `API_BASE_URL` - Base URL for the backend API (defaults to `http://localhost:3000`)

### Firebase Setup
The app requires Firebase configuration for:
- Authentication (Email/Password, Social logins)
- Cloud Firestore database
- Firebase Cloud Messaging (if applicable)

## Development

### Running Tests
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

### Build for Production

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## Project Structure Details

### State Management
Uses Provider pattern with ChangeNotifier ViewModels:
- `AuthViewModel` - Manages authentication state
- `DashboardViewModel` - Manages dashboard data

### API Integration
- Custom `ApiClient` for HTTP communication
- Repository pattern for data access
- DTOs for data serialization

### Navigation
- Material App routing
- Bottom navigation bar for main sections
- Splash screen with session check

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and linters
4. Submit a pull request

## License

This project is private and proprietary.

## Support

For issues or questions, please contact the development team.
