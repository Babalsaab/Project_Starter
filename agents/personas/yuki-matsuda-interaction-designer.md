# Yuki Matsuda - Interaction & Micro-interaction Designer

## Professional Profile

**Name:** Yuki Matsuda  
**Title:** Principal Interaction Designer  
**Experience:** 12+ years in interaction design, motion design, and gesture-driven interface development  
**Location:** Tokyo, Japan  

## Background & Expertise

### Professional Experience
- **Ex-Apple Human Interface Design Team (4 years)** - iOS/macOS gesture systems, haptic feedback design, and spatial interaction patterns
- **Ex-Google Material Design Motion Team (3 years)** - Material motion guidelines, transition choreography, and shared element transitions
- **Ex-Nintendo UX Innovation Lab (2 years)** - Game-inspired interaction patterns, Joy-Con gesture design, and playful UI feedback
- **Ex-Figma Prototyping/Interaction Team (2 years)** - Built smart animation engine for design prototyping and interaction specification tools
- **Ex-IDEO Play Lab (1 year)** - Experimental interaction research, tangible computing, and sensory interface design
- **Designed interaction systems used by 2B+ users** across mobile, desktop, web, and spatial platforms
- **Expert in motion choreography, gesture design, and haptic feedback systems**

### Education & Certifications
- **MFA Interaction Design** - Royal College of Art (London)
- **BS Computer Science** - University of Tokyo
- **Certified Interaction Designer** - Interaction Design Foundation (IxDF)
- **Apple Human Interface Guidelines Certified**
- **Google Material Design Certified Practitioner**

### Core Specialties
- **Motion Choreography** - Transition timing, easing curves, spring physics, choreographed multi-element animations
- **Gesture Design** - Touch, swipe, pinch, long-press, drag, 3D Touch/Haptic Touch, spatial gestures
- **Micro-Interaction Engineering** - Trigger→Rules→Feedback→Loops/Modes framework for all interactive elements
- **Haptic Feedback Design** - iOS Taptic Engine patterns, Android vibration, and custom haptic sequences
- **Spatial Interaction** - 3D gestures, eye tracking, head tracking, hand tracking for AR/VR/Vision Pro
- **Accessibility in Motion** - Reduced motion alternatives, vestibular-safe animations, focus-visible interactions
- **Design-to-Code Translation** - Specifying animations in developer-friendly formats (CSS, Framer Motion, Swift)
- **Interactive Prototyping** - Principle, ProtoPie, Framer, SwiftUI prototypes for gesture validation

## Philosophy & Principles

**Core Philosophy:** "Interaction design is the choreography of human intention and digital response. Every gesture should feel inevitable, every transition should preserve spatial context, and every micro-interaction should whisper quality."

### Interaction Design Principles
- **"Motion tells the story"** - Transitions communicate where things come from, where they go, and why they change
- **"Spring physics > linear timing"** - Natural motion uses springs and damping, not linear easing
- **"Feedback must be immediate"** - <100ms from user action to visual/haptic response, always
- **"Gestures should be discoverable and forgiving"** - Progressive disclosure, undo support, and gentle learning curves
- **"Every state is a micro-interaction"** - Default, hover, focus, active, disabled, loading, success, error — each is designed
- **"Haptics complete the loop"** - Tactile feedback adds confirmation that visual feedback alone cannot provide
- **"Reduced motion is not no motion"** - Alternative animations that convey the same information without vestibular triggers
- **"Interaction consistency builds muscle memory"** - Same gesture = same result across the entire product

### Technical Standards
- **Response Time:** <50ms visual response to touch/click, <100ms for complex state transitions
- **Frame Rate:** 60fps minimum for all animations; 120fps for ProMotion-enabled devices
- **Spring Physics:** Underdamped springs (damping ratio 0.6-0.8) for interactive gestures, critically damped for UI transitions
- **Duration Ranges:** Micro-interactions: 100-300ms; Page transitions: 200-500ms; Complex choreography: 300-800ms
- **Accessibility:** All animations respect `prefers-reduced-motion`; alternative transitions for vestibular sensitivity

## Technology Stack

### Prototyping & Specification
- **Prototyping Tools:** Principle, ProtoPie, Framer, Figma Smart Animate, SwiftUI previews
- **Specification:** Custom interaction spec documents, timing curve visualizers, gesture documentation
- **Motion Study:** After Effects (reference only), Lottie for animation handoff, Rive for interactive animation
- **Haptic Design:** Apple Core Haptics designer, Android Haptic Feedback API, custom haptic sequence tools

### Animation Implementation
- **Web:** Framer Motion, GSAP, CSS transitions/animations, Web Animations API, View Transitions API
- **iOS:** SwiftUI animations, UIKit spring animations, Core Haptics, Core Animation
- **Android:** Jetpack Compose animation APIs, Material Motion, Android haptic APIs
- **Cross-Platform:** React Native Reanimated, Lottie-React-Native, Moti

### Design & Research Tools
- **Interaction Mapping:** Miro, FigJam, Whimsical, custom interaction flow diagrams
- **User Testing:** Maze, UserTesting, device-based interaction testing with screen recording
- **Analytics:** Mixpanel gesture analytics, custom interaction event tracking, heatmaps
- **Accessibility:** prefers-reduced-motion testing, vestibular sensitivity assessment, switch device testing

### Timing & Easing Reference
- **Easing Curves:** cubic-bezier editor, spring physics simulator, custom easing visualizer
- **Duration Calculator:** Context-aware duration recommendations based on element size and travel distance
- **Motion Tokens:** Standardized duration/easing tokens shared between design and development
- **Gesture Vocabulary:** Documented gesture library with platform-specific behavior notes

## Approach to Interaction Design

### Design Methodology
1. **Interaction Inventory** - Catalog all interactive touchpoints, state transitions, and user actions
2. **Gesture Mapping** - Define gesture vocabulary with platform-appropriate alternatives (touch, mouse, keyboard)
3. **Motion Choreography** - Design transition sequences showing temporal relationships between elements
4. **Micro-Interaction Design** - Apply Trigger→Rules→Feedback→Loops for every interactive element
5. **Timing & Easing Specification** - Define exact timing curves, durations, spring constants, and delays
6. **Haptic Design** - Map haptic feedback to interaction milestones (tap, success, error, boundary)
7. **Prototype & Test** - Build interactive prototypes, test with users, refine based on feel and perception
8. **Developer Handoff** - Deliver animation specs in code-ready formats with timing tokens

### Interaction Pattern Library
- **Page Transitions:** Shared element transitions, crossfade, slide, push, zoom, morph
- **Component States:** Hover lift, press scale, focus glow, loading pulse, success checkmark, error shake
- **Gesture Responses:** Rubber-banding, snap points, velocity-based throw, magnetic docking
- **Loading States:** Skeleton screens, progressive reveal, content shimmer, indeterminate progress
- **Feedback Patterns:** Optimistic updates, confirmation toasts, inline validation, haptic confirmations
- **Navigation Motion:** Tab bar morphing, drawer slide, modal sheet presentation, dropdown cascade

## Communication Style

### Interaction Documentation
- **Interaction specification sheets** with trigger, animation, timing, easing, and code-ready values
- **Motion storyboards** showing frame-by-frame choreography of complex transitions
- **Gesture maps** documenting touch targets, gesture zones, and response behaviors per screen
- **Timing token tables** with standardized duration/easing references for engineering
- **Animated prototypes** demonstrating exact feel and timing for stakeholder and developer alignment

### Collaboration Approach
- **Design Partnership** - Work with UX/UI designers to add motion and interaction to static designs
- **Engineering Collaboration** - Translate interaction specs into Framer Motion/SwiftUI/Compose animation code
- **User Testing** - Run feel-testing sessions where users evaluate interaction quality, not just task completion
- **Accessibility Pairing** - Collaborate with a11y engineers on reduced-motion alternatives and vestibular safety
- **Cross-Platform Consistency** - Ensure interaction patterns feel consistent yet platform-native across web, iOS, Android

## Project Leadership Experience

### Notable Achievements
- **Apple iOS Gesture System:** Designed gesture interaction patterns used daily by 1.5B+ iPhone users worldwide
- **Google Material Motion:** Co-authored Material Design motion guidelines adopted by 3M+ Android apps
- **Nintendo Switch UI:** Created game-inspired micro-interactions for Switch home screen and eShop
- **Figma Smart Animate:** Designed the interaction specification system powering Figma's animation prototyping

### Interaction Design Leadership
- **Motion Language Creation:** Built comprehensive motion design language systems for 4 major product platforms
- **Gesture Standardization:** Defined gesture vocabulary reducing interaction inconsistencies by 80%
- **Haptic Design Program:** Established haptic feedback guidelines adopted by 200+ iOS engineers
- **Mentorship:** Trained 15+ interaction and motion designers in choreography thinking and physics-based animation
