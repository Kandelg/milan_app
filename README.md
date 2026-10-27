# 📱 Milan App

A modern, architecture-driven cross-platform mobile application built with **Flutter**, powered by **Riverpod** for production-grade state management, and backed by **Supabase** for secure, real-time backend infrastructure.

---

## 🏛️ Architecture & Core Philosophy

The codebase is engineered using a hybrid **Feature-First and Layered Architecture**. By decoupling the presentation layer from backend repositories, the system ensures high scalability, absolute isolated testing, and effortless feature onboarding.

* **Clean State Management:** Leverages Riverpod providers to cleanly expose immutable reactive data streams to the UI.
* **Robust Backend Security:** Relies on Supabase Server-Side Row-Level Security (RLS) policies and explicit Remote Procedure Calls (RPC) to prevent unauthorized database updates.

---

## 📂 Professional Repository Structure

```text
milan_app/
├── lib/
│   ├── main.dart                  # Application entry point & Supabase client initialization
│   ├── app/                       # Global root widget config & central declarative GoRouter definition
│   ├── core/                      # Application-wide styles, custom themes, shared UI widgets, and constants
│   ├── data/                      # Global Data Layer (The source of absolute truth)
│   │   ├── models.dart            # Immutable functional data schemas (Profile, Match, Message, SwipeDirection)
│   │   ├── *_repository.dart      # Business layer API bridges (Auth, Profile, Discover, Match, Cloud Storage)
│   │   └── providers.dart         # Globally accessible Riverpod dependency injection definitions
│   └── features/                  # UI Presentation Layer (Modularity driven by concrete business domains)
│       ├── auth/                  # Secure user authentication flow management
│       ├── splash/                # Cold-start visual experience and active session check logic
│       ├── onboarding/            # Dynamic registration profile configuration and metadata ingestion
│       ├── discover/              # Swipe deck interfaces, geolocation streams, and profiles ranking
│       ├── matches/               # Two-way reciprocal match listing and historical logging
│       ├── chat/                  # Real-time WebSocket messaging and reactive database listeners
│       ├── profile/               # In-app user settings, privacy toggles, and live DB visibility update dashboards
│       └── shell/                 # Bottom navigation persistent layout structures
├── supabase/
│   └── schema.sql                 # Complete database structure, strict RLS triggers, indexes, and custom RPC scripts
├── test/                          # Comprehensive standalone component and repository system tests
└── env.example.json               # Environment configuration blueprint (Duplicate to env.json locally)
```

---

## 🛠️ Infrastructure & Tech Stack

| Component | Technical Framework | Purpose within Project |
| :--- | :--- | :--- |
| **Frontend Core** | **Flutter & Dart** | Cross-platform execution with smooth 60fps UI processing. |
| **State Machinery** | **Riverpod** | Decoupled dependency injection, predictable asynchronous states. |
| **Routing Engine** | **GoRouter** | Type-safe declarative URL-based application navigation workflows. |
| **Backend & Realtime** | **Supabase** | PostgreSQL core, identity management, raw DB storage hooks. |
| **Security Layer** | **PostgreSQL RLS** | Server-side validation enforcing total account data isolation. |

---

## 🚀 Local Environment Installation Guide

Follow these steps to safely initialize the runtime code footprint on your local workstation:

1. **Clone the Repository:**
   ```bash
   git clone https://github.com
   cd milan_app
   ```

2. **Configure Client Credentials:**
   Copy the reference credentials configuration layout to initialize your local config:
   ```bash
   cp env.example.json env.json
   ```
   *Open `env.json` and insert your authentic Supabase URL and corresponding `anon` public key hashes.*

3. **Synchronize Dependencies:**
   Pull downstream package components from the centralized pub network:
   ```bash
   flutter pub get
   ```

4. **Execute App Compilation:**
   Launch the system inside your active emulator target environment:
   ```bash
   flutter run
   ```
