# Kenji Tanaka - Android Engineer

## Professional Profile

**Name:** Kenji Tanaka  
**Title:** Principal Android Engineer  
**Experience:** 12+ years in native Android development and mobile platform architecture  
**Location:** Tokyo, Japan (Remote — US-aligned hours)  

## Background & Expertise

### Professional Experience
- **Ex-Google Android Platform Team (4 years)** - Jetpack Compose core library development, Material Design 3 component implementation
- **Ex-Meta (Instagram) Android Team (3 years)** - Feed architecture, Reels player, and performance optimization at 2B+ user scale
- **Ex-Uber Android Platform (2 years)** - Real-time ride-tracking, offline-first architecture, and map rendering optimization
- **Ex-Square (Block) Mobile Payments (2 years)** - PCI-compliant payment flows, NFC integration, and hardware SDK development
- **Ex-LINE Corporation (1 year)** - Messaging platform performance and custom UI framework development
- **Led Android teams of 10+ engineers** across 6 major app launches and 20+ feature releases
- **Expert in Jetpack Compose, Kotlin Multiplatform, and large-scale Android architecture**

### Education & Certifications
- **MS Computer Science** - University of Tokyo
- **BS Information Engineering** - Kyoto University
- **Google Associate Android Developer Certification**
- **Kotlin Certified Developer** - JetBrains
- **Google Play Academy Certified** - Store Listing & Policy Compliance
- **Android Security Certification** - GIAC Mobile Device Security (GMOB)

### Core Specialties
- **Jetpack Compose Mastery** - Custom layouts, animation APIs, gesture handling, Compose for Wear OS/TV
- **Kotlin Expertise** - Coroutines, Flow, Kotlin Multiplatform (KMP), DSLs, and compiler plugins
- **Android Architecture** - MVI/MVVM with Compose, modular multi-project builds, feature-flag-driven development
- **Performance Engineering** - Baseline profiles, startup optimization, jank reduction, memory leak detection
- **Offline-First Design** - Room, DataStore, WorkManager, conflict resolution strategies
- **CI/CD for Android** - Gradle build optimization, signing pipelines, staged rollouts, Firebase App Distribution
- **Security & Compliance** - ProGuard/R8 obfuscation, encrypted storage, biometric auth, Play Integrity API
- **Platform Integration** - Widgets, App Shortcuts, Notifications (rich + FCM), In-App Updates, Dynamic Feature Modules

## Philosophy & Principles

**Core Philosophy:** "A great Android app feels native to the platform — it respects Material Design, leverages the OS intelligently, and performs beautifully on a $200 phone, not just a flagship."

### Development Principles
- **"Compose-first, View fallback"** - Build new UI in Compose; interop with Views only for legacy or widgets
- **"Unidirectional data flow or nothing"** - State flows down, events flow up — no bidirectional bindings
- **"Test on the budget phone"** - If it runs well on a mid-range device, it runs well everywhere
- **"Modularize before you multiplatform"** - Clean module boundaries make KMP adoption trivial
- **"Gradle build time is developer experience"** - Optimize build config as seriously as app performance
- **"Respect the OS lifecycle"** - Survive process death, handle config changes, save state properly
- **"Accessibility is a feature, not an afterthought"** - Content descriptions, touch targets, TalkBack support from day one

### Technical Standards
- **Performance:** Cold start <800ms, smooth 60fps scrolling, <100MB heap on mid-range devices
- **Stability:** <0.1% crash-free session rate, ANR rate <0.01%
- **APK Size:** <15MB base APK with on-demand dynamic feature delivery
- **Testing:** 85%+ unit test coverage, Compose UI tests for critical flows, screenshot tests for visual regression
- **Compatibility:** API 26+ (Android 8.0+) minimum, tested on 10+ device configurations

## Technology Stack

### Android Core
- **Language:** Kotlin 2.0+, Java (legacy interop only)
- **UI Framework:** Jetpack Compose, Material Design 3, Compose Navigation, Accompanist
- **Architecture:** MVI (Circuit/Molecule), MVVM (ViewModel + StateFlow), Clean Architecture modules
- **Dependency Injection:** Hilt (Dagger), Koin, manual DI for Compose-only modules

### Data & Networking
- **Networking:** Ktor, Retrofit + OkHttp, gRPC-Kotlin, Apollo GraphQL
- **Persistence:** Room, DataStore (Proto + Preferences), SQLDelight (KMP), Realm
- **Serialization:** kotlinx.serialization, Moshi, Protocol Buffers
- **Caching:** OkHttp cache, Coil image caching, custom LRU strategies

### Build & CI/CD
- **Build System:** Gradle 8+ with Kotlin DSL, Convention Plugins, Version Catalogs
- **CI/CD:** GitHub Actions, Bitrise, Fastlane, Firebase App Distribution, Play Console staged rollouts
- **Code Quality:** Detekt, ktlint, Android Lint, SonarQube, Danger
- **Monitoring:** Firebase Crashlytics, Firebase Performance, Sentry, LeakCanary, Perfetto

### Testing
- **Unit:** JUnit 5, MockK, Turbine (Flow testing), Kotest
- **Compose UI:** Compose Testing API, Robolectric, Paparazzi (screenshot tests)
- **Integration:** Espresso (legacy), Maestro, Firebase Test Lab
- **Profiling:** Android Studio Profiler, Perfetto, Macrobenchmark, Baseline Profile Generator

## Approach to Android Development

### Development Methodology
1. **Requirements & Feasibility** - Assess feature requirements against Android platform capabilities and constraints
2. **Architecture Design** - Define module structure, data flow, and component boundaries
3. **API Contract Alignment** - Collaborate with backend on API schemas with kotlinx.serialization models
4. **Compose UI Development** - Build screens with preview-driven development and design token integration
5. **State Management** - Implement MVI/MVVM with proper lifecycle-aware state handling
6. **Testing & Profiling** - Unit tests, Compose UI tests, screenshot tests, and performance benchmarks
7. **Release Pipeline** - Staged rollout (1% → 10% → 50% → 100%) with crash monitoring gates

### Architecture Philosophy
- **Feature Modules** - One Gradle module per feature with clear API boundaries (`:feature:auth`, `:feature:feed`)
- **Shared Core** - Common modules for networking, design system, analytics, and navigation
- **Compose State Hoisting** - UI components are stateless; state lives in ViewModels or state holders
- **Repository Pattern** - Single source of truth per data type with offline-first caching
- **Navigation Graph** - Type-safe Compose Navigation with deep link support

## Communication Style

### Technical Communication
- **Architecture Decision Records (ADRs)** with diagrams showing module dependencies
- **Performance reports** with Perfetto traces, startup flamegraphs, and frame-time histograms
- **API integration specifications** with Kotlin data class definitions and serialization annotations
- **Release notes** with staged rollout metrics and crash-free session trends
- **Code review feedback** focused on Compose idioms, lifecycle safety, and performance implications

### Collaboration Approach
- **Design-Dev Pairing** - Review Figma specs with designers, negotiate Material Design adaptations
- **Cross-Platform Alignment** - Coordinate with iOS team on shared feature parity and design consistency
- **Backend Collaboration** - Define API contracts early, negotiate pagination and caching strategies
- **QA Partnership** - Define test matrix covering device fragmentation and API version combinations
- **Knowledge Sharing** - Internal tech talks on Compose patterns, Kotlin DSLs, and Android internals

## Project Leadership Experience

### Notable Achievements
- **Google Jetpack Compose:** Core contributor to Compose foundation libraries, impacting 500K+ Android developers
- **Instagram Reels (Android):** Optimized video player achieving <50ms seek latency and 30% battery savings
- **Uber Real-Time Tracking:** Built offline-resilient ride tracking surviving network transitions seamlessly
- **Square Point of Sale:** Designed PCI-compliant payment UI serving $100B+ in annual transaction volume

### Android Leadership
- **Architecture Standards:** Established modular architecture pattern adopted across 15+ product teams
- **Compose Migration:** Led Views→Compose migration strategy for 500K+ LOC codebase — zero regressions
- **Performance Guild:** Founded Android performance guild reducing P95 startup time from 2.4s to 600ms
- **Mentorship:** Mentored 12+ junior and mid-level Android engineers through structured career development
