SoundSync
Predictive transit app for Bellevue College students.
Search routes, view stops, and see them on a map — built with Flutter + Golang + MongoDB.

"Transit data is broken — and nobody seems to care. Riders are left guessing, waiting, and hoping. We're fixing the data so riders finally feel seen."


Overview
SoundSync addresses public transit reliability challenges in the Seattle–Bellevue corridor by:

Providing real-time bus tracking with reliability scores
Offering AI-enhanced arrival predictions using historical data
Helping users plan routes based on actual transit performance
Giving riders confidence scores so they know when to leave

We're not competing with Google Maps on features. We're solving something Google doesn't care about: making riders feel seen.

Team
NameRoleFocusAbshiraFrontend (Flutter)Dart models, API parsing, UI screensWayneBackend (Golang + MongoDB)REST endpoints, JSON contractsNolanLLM Integration/llm/explain endpoint, AI predictionsTonyIntegration LeadJSON schemas, naming conventions, API docs
Course: CS 455 — Capstone, Bellevue College

Architecture
┌─────────────────────────────────────────────────────────────┐
│                      FRONTEND (Flutter)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Home Screen  │  │ Route Detail │  │ Search Screen │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │Trip Assistant │  │  Connection  │  │  Crowd Intel  │      │
│  │              │  │   Checker    │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                          │                                   │
└──────────────────────────│───────────────────────────────────┘
                           │ HTTPS (REST)
┌──────────────────────────│───────────────────────────────────┐
│                    BACKEND (Golang)                           │
│  ┌─────────────────────────────────────────────────┐        │
│  │              Gin / HTTP Router                    │        │
│  └────────┬──────────────┬──────────────┬──────────┘        │
│           │              │              │                     │
│  ┌────────▼──────┐ ┌─────▼──────┐ ┌────▼──────────┐        │
│  │ GET /routes   │ │GET /route/ │ │POST /llm/     │        │
│  │   ?query=     │ │   :id      │ │   explain     │        │
│  └────────┬──────┘ └─────┬──────┘ └────┬──────────┘        │
│           │              │              │                     │
│  ┌────────▼──────────────▼──────────────▼──────────┐        │
│  │                  MongoDB                         │        │
│  └──────────────────────────────────────────────────┘        │
└──────────────────────────│───────────────────────────────────┘
                           │ API Calls
┌──────────────────────────│───────────────────────────────────┐
│                  EXTERNAL SERVICES                            │
│  ┌──────────┐  ┌─────────▼───┐  ┌────────────┐              │
│  │ Google   │  │ King County │  │  LLM API   │              │
│  │ Maps SDK │  │ Metro GTFS  │  │ (Claude /  │              │
│  │          │  │ Static + RT │  │  OpenAI)   │              │
│  └──────────┘  └─────────────┘  └────────────┘              │
└──────────────────────────────────────────────────────────────┘

Tech Stack
LayerTechnologyPurposeFrontendFlutter (Dart)Cross-platform mobile + web appState ManagementRiverpodReactive state with providersNavigationGoRouterDeclarative routingMapsGoogle Maps SDKRoute visualization, stop markersBackendGolang (Gin)REST API serverDatabaseMongoDBRoute, stop, and schedule dataLLMClaude / OpenAI APIAI-powered transit predictionsTransit DataKing County Metro GTFSStatic schedules + real-time feeds

Screens
ScreenStatusDescriptionHome✅ BuiltRoute list with search, reliability scoresSearch✅ BuiltFilter routes by name or numberRoute Detail✅ BuiltMap view with stops, arrival times, confidenceTrip Assistant🔲 PlannedAI chatbot — "Will I make my 2pm class?"Connection Checker🔲 PlannedTransfer success rates between routesCrowd Intel🔲 PlannedCommunity-reported delays and conditionsAlternative Routes🔲 PlannedDelay alerts with backup route optionsAI Route Finder🔲 PlannedSmart trip planning with AI reasoning

API Endpoints
MethodEndpointOwnerDescriptionGET/routes?query=WayneSearch routes, returns listGET/route/:idWayneRoute detail with stops and schedulePOST/llm/explainNolanAI-powered route explanation
All endpoints return standardized JSON with consistent field naming, date formats (ISO 8601), and coordinate formats ({ lat, lng }). See Tony's API documentation for full schemas.

Quick Start
1. Install Flutter
macOS:
bashbrew install flutter
Windows:
Download from https://docs.flutter.dev/get-started/install/windows
Linux:
bashsudo snap install flutter --classic
Verify:
bashflutter doctor
2. Clone and Run
bashgit clone <repo-url>
cd soundsync
flutter pub get
flutter run
Run on specific device:
bashflutter run -d chrome        # Web browser
flutter run -d android       # Android emulator
flutter run -d ios           # iOS simulator (macOS only)
3. Google Maps Setup

Get an API key from Google Cloud Console
Enable Maps SDK for Android, Maps SDK for iOS, and Maps JavaScript API
Add your key:

Android — android/app/src/main/AndroidManifest.xml:
xml<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_API_KEY"/>
iOS — ios/Runner/AppDelegate.swift:
swiftGMSServices.provideAPIKey("YOUR_API_KEY")
Web — web/index.html:
html<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY"></script>
4. Backend (Wayne)
bashcd backend/
go run main.go
Backend runs on http://localhost:8080 by default.
5. Environment Config
The app uses mock data by default. To connect to the live backend, update lib/config/api_config.dart:
dartstatic const bool useMockData = false;  // flip to true for mock
static const String baseUrl = 'http://10.0.2.2:8080';  // Android emulator
// static const String baseUrl = 'http://localhost:8080';  // iOS / Web

Project Structure
soundsync/
├── lib/
│   ├── config/
│   │   ├── api_config.dart       # Base URL, mock toggle
│   │   ├── router.dart           # GoRouter routes
│   │   └── theme.dart            # App colors and styles
│   ├── data/
│   │   ├── models/
│   │   │   ├── route.dart        # Route data model
│   │   │   ├── stop.dart         # Stop data model
│   │   │   └── arrival.dart      # Arrival prediction model
│   │   ├── services/
│   │   │   └── api_service.dart  # HTTP client (Dio)
│   │   └── mock/
│   │       └── mock_data.dart    # Hardcoded test data
│   ├── screens/
│   │   ├── home/                 # Home screen ✅
│   │   ├── search/               # Search screen ✅
│   │   ├── route_detail/         # Route detail + map ✅
│   │   ├── trip_assistant/       # AI chatbot 🔲
│   │   ├── connection_checker/   # Transfer checker 🔲
│   │   └── crowd_intel/          # Community reports 🔲
│   └── main.dart
├── android/
├── ios/
├── web/
├── pubspec.yaml
└── README.md

Sprint Progress
SprintPeriodFocusStatusSprint 1Jan 7–20Design — UI screens, SRS, presentation CompleteSprint 2Jan 23 – Feb 7Setup — Flutter project, map, bus stops CompleteSprint 3Feb 8–21Core — Routes, arrivals, navigation🔄 In ProgressSprint 4Feb 22 – Mar 7Live Data — GTFS-RT integration🔲 UpcomingSprint 5Mar 8–21Polish — Presentation-ready prototype🔲 Upcoming
What's Done

Flutter project scaffolded with Riverpod + GoRouter
3 core screens built (Home, Search, Route Detail)
Dart models matching API JSON contract
Google Maps integration with stop markers
Mock data layer for development without backend
Standardized API contract defined across team

What's Next

Connect to live Golang backend API
Integrate LLM endpoint for Trip Assistant
Build remaining screens (Trip Assistant, Connection Checker, Crowd Intel)
King County Metro GTFS-RT real-time feed integration
Push notifications for departure alerts
UI polish, animations, and error handling


Key Features (Planned)
FeatureDescriptionReliability ScoresConfidence percentages on arrival times based on historical dataTransit CopilotAI chatbot — ask "Will I make my 2pm class?" and get a real answerGhost Bus DetectionVisual overlay showing predicted bus position in 1/3/5 minutesConnection CheckerTransfer success rates — "94% based on 347 trips"Predictive AlertsLearns your routine, warns you before you're lateCrowd IntelCommunity-reported conditions and delays

Data Sources
SourceTypeUsageKing County Metro GTFSStatic + Real-timeRoutes, stops, schedules, live positionsGoogle Maps SDKMapsRoute visualization, stop markersLLM APIAINatural language predictions and explanations

