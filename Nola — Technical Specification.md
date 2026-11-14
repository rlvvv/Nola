# Nola — Technical Specification

**Version:** 0.3  
**Status:** Product direction approved; implementation pending  
**Platform:** Native iOS  
**Minimum deployment target:** iOS 15.0  
**Language:** Swift  
**UI framework:** SwiftUI  
**Database:** Core Data  
**Development:** Windows + Cline, MacinCloud + Xcode  
**Repository:** https://github.com/rlvvv/Nola

---

# 1. Product Identity

## 1.1 Name

Nola.

The application icon has already been created. Preserve the existing icon and inspect the project's asset catalog before changing anything related to branding.

## 1.2 Purpose

Nola is a private, personal journaling and self-reflection application.

It is being developed exclusively for personal use, enjoyment, and long-term value.

It is not a commercial product.

There are no business requirements, monetization targets, subscriptions, advertisements, customer acquisition goals, or multi-user requirements.

The application should help its user:

- Record thoughts, experiences, and emotions.
- Understand themselves better.
- Recognize patterns in their behavior.
- Reflect on decisions and problems.
- Track meaningful personal development.
- Preserve important memories.
- Eventually use a personalized AI thinking partner that understands their history.

The application should be useful even without AI.

## 1.3 Product philosophy

Nola should make personal reflection easier, not turn life into another productivity project.

Principles:

- No pressure to journal every day.
- No guilt-based streaks.
- No forced self-improvement.
- No artificial progress scores.
- No unnecessary notifications.
- No engagement manipulation.
- No assumption that every problem needs solving.
- No requirement to use AI.

The application should help the user understand and enjoy life, not constantly optimize it.

---

# 2. Technical Architecture

## 2.1 Technical requirements

1. Build a fully native iOS application.
2. Use Swift and SwiftUI.
3. Support iOS 15.0 and newer.
4. Keep the application local-first.
5. Make core functionality available offline.
6. Keep personal data under the user's control.
7. Use modular, maintainable architecture.
8. Avoid unnecessary dependencies and abstractions.
9. Design for future local AI integration.
10. Implement features incrementally.

Do not use React Native, Expo, WebViews, or hybrid frameworks.

## 2.2 Technology stack

| Component | Technology |
|---|---|
| Language | Swift |
| UI | SwiftUI |
| Persistence | Core Data |
| Architecture | Feature-based MVVM |
| State management | ObservableObject, Published, StateObject |
| Async operations | Swift Concurrency |
| Networking | URLSession |
| Secure credentials | Keychain, when required |
| Source control | Git + GitHub |
| Testing | XCTest |
| Minimum OS | iOS 15.0 |

### Compatibility restrictions

The application must compile with an iOS 15 deployment target.

Do not use APIs that require newer iOS versions without providing an appropriate fallback.

In particular:

- Do not use SwiftData.
- Do not use NavigationStack as the only navigation implementation.
- Do not use the iOS 17 Observation framework as the primary state-management system.
- Do not assume Swift Charts is available.
- Do not use newer presentation APIs without compatibility handling.

Prefer APIs available on iOS 15.

Use NavigationView or another iOS 15-compatible navigation approach.

Use ObservableObject and @StateObject for view-model ownership.

Use #available checks only when a newer API genuinely provides additional functionality.

## 2.3 Application architecture

Use a feature-based MVVM structure.

Suggested project organization:

    Nola/
    |
    |-- App/
    |   |-- NolaApp.swift
    |   |-- AppState.swift
    |   |-- AppNavigation.swift
    |
    |-- Core/
    |   |-- Database/
    |   |-- Persistence/
    |   |-- Networking/
    |   |-- Security/
    |   |-- Utilities/
    |   |-- Components/
    |
    |-- Features/
    |   |-- Today/
    |   |-- Journal/
    |   |-- Mood/
    |   |-- Habits/
    |   |-- Moments/
    |   |-- AI/
    |   |-- Insights/
    |   |-- Settings/
    |
    |-- Resources/
    |
    |-- Nola.xcdatamodeld
    |
    |-- Tests/

This is a logical organization, not a requirement to create empty folders or files for features that have not been implemented.

Adapt the structure to the existing repository instead of blindly recreating it.

Each feature should contain its own views, view models, and supporting logic where appropriate.

Shared components and services should live in Core.

## 2.4 Persistence

Use Core Data with an appropriate persistent container.

Requirements:

- Persistent local storage.
- Reliable create, read, update, and delete operations.
- Appropriate relationships between entities.
- Safe handling of failed saves.
- Sensible context management.
- Data model versioning and migration planning.
- No unnecessary duplication of journal content.

Keep persistence logic separate from SwiftUI views.

The application must not lose saved entries when it closes or restarts.

## 2.5 Data entities

Initial proposed entities:

### JournalEntry

- id: UUID
- title: String, optional
- content: String
- createdAt: Date
- updatedAt: Date
- entryType: String or enum representation
- tags: optional collection or relationship

Entry types:

- Daily journal
- Brain dump
- Topic-based entry

### MoodEntry

- id: UUID
- moodValue: Int
- emotions: optional collection
- note: optional String
- createdAt: Date

### Habit

- id: UUID
- name: String
- description: optional String
- createdAt: Date
- isArchived: Bool

### HabitLog

- id: UUID
- date: Date
- completed: Bool
- relationship to Habit

### MemorableMoment

- id: UUID
- title: optional String
- content: String
- createdAt: Date
- tags: optional collection or relationship

The final Core Data schema should use appropriate relationships and constraints.

Avoid prematurely implementing every entity. Add models when their corresponding feature is developed.

---

# 3. Privacy and Data Ownership

Nola is a personal application containing potentially sensitive journal entries.

Requirements:

- No account required.
- No external analytics collecting journal content.
- No advertising SDKs.
- No unnecessary telemetry.
- No automatic transmission of journal entries.
- Local storage for core functionality.
- Appropriate iOS data protection.
- User-controlled deletion.
- Future data export and backup support.
- No hardcoded credentials or API keys.

Cloud synchronization is not part of the initial implementation.

Do not use real personal journal entries as development test data.

---

# 4. AI Architecture

Nola uses Venice’s OpenAI-compatible chat-completions API for its first AI provider. The app sends only the conversation and local context needed for each request. The user’s API key is stored in the iOS Keychain and never hardcoded.

## 4.1 AI execution modes

### Venice API

- Endpoint: `https://api.venice.ai/api/v1/chat/completions`.
- Authentication: a user-provided Venice API key stored in Keychain.
- The app sends current conversation messages for chat.
- A requested opening question may include only the smallest useful selection of journal entries, moods, and memorable moments needed to ground that question.
- Model selection should be configurable or discovered at runtime as provider capabilities evolve.
- On-device and PC-hosted providers remain possible future implementations behind the provider interface.

## 4.2 Provider abstraction

Future AI functionality should be accessed through a provider-independent interface.

For example:

    protocol AIProvider {
        func generateResponse(
            messages: [AIMessage],
            context: AIContext
        ) async throws -> AIResponse
    }

Possible implementations:

- OnDeviceAIProvider
- LocalNetworkAIProvider

This is a future architectural direction, not code that needs to be implemented during the foundation stage.

## 4.3 AI behavior

The AI should eventually:

- Remember relevant information.
- Understand personal history.
- Ask thoughtful and challenging questions.
- Recognize recurring patterns.
- Identify contradictions.
- Offer personalized recommendations.
- Distinguish observations from interpretations.
- Admit uncertainty.
- Avoid blindly agreeing with the user.

It should strengthen independent thinking rather than replace it.

---

# 5. Feature Specification

## 5.1 Navigation

Planned main sections:

1. Today
2. Journal
3. AI Companion
4. Insights
5. Profile / Settings

Navigation should be simple and native to iOS.

Do not build fake functionality for features that have not been implemented.

## 5.2 Today

Purpose: A simple overview of the current day.

Planned functionality:

- Quick mood logging.
- Memorable moment capture.
- Habit tracking.
- Recent journal entry.
- Create a journal entry.
- Start a brain dump.

No section should be mandatory.

## 5.3 Journal

Purpose: A flexible space for recording thoughts and experiences.

Requirements:

- Create entries.
- Edit entries.
- Delete entries with confirmation.
- Browse previous entries.
- Search entries.
- Organize by date and type.
- Support long-form writing.
- Preserve unsaved work appropriately.
- Allow entries without titles.
- Support unrestricted brain dumps.

Writing should feel immediate and uninterrupted.

## 5.4 Mood tracking

Purpose: Record emotional state over time.

Requirements:

- Select a mood.
- Optionally select emotions.
- Optionally add a note.
- View historical records.
- Prepare data for future trend analysis.

Do not force explanations.

## 5.5 Habits

Purpose: Track selected behaviors without creating pressure.

Requirements:

- Create habits.
- Edit habits.
- Archive habits.
- Record completion.
- Browse historical records.

Avoid guilt-based streaks and excessive gamification.

## 5.6 Memorable moments

Purpose: Preserve experiences worth remembering.

Examples:

- Achievements.
- Failures.
- Funny moments.
- Conversations.
- Enjoyable experiences.
- Realizations.
- Unexpected events.

Requirements:

- Create and edit moments.
- Browse previous moments.
- Search moments.
- Optionally associate moments with journal entries.

No daily requirement.

## 5.7 AI Companion

The AI is a guided-journaling companion whose purpose is to help the user understand situations and themselves, and reach their own answers.

- Sessions start either when the user writes in a chat-style composer or taps Request question.
- Request question is available once per day and asks an open-ended question grounded in relevant local memory.
- The AI asks one challenging question at a time, typically 4–10 words, and asks no more than seven questions per session.
- The user ends a session when it feels resolved or clarified. After seven AI questions, sending another response in that session is blocked.
- The AI challenges blind spots, excuses, patterns, and limiting beliefs without pretending certainty.
- It avoids generic advice, reflexive agreement or disagreement, long or unclear questions, and lying.
- When the user hands Nola a decision, it returns the decision through a short question about what the user already wants or believes.
- Difficult thoughts receive a normal, calm, direct question. Only clearly stated immediate danger triggers a brief prompt to seek urgent real-world support.

## 5.8 Long-term memory — future

Memory should include useful information about:

- Interests.
- Preferences.
- Goals.
- Projects.
- Experiences.
- Recurring difficulties.
- Previous decisions.
- Helpful strategies.
- Changes in priorities.

Memory must be inspectable, editable, and deletable.

Old information must not automatically be treated as permanently true.

## 5.9 Insights and personal development — future

The app should identify meaningful changes across time.

Potential areas:

- Mood.
- Habits.
- Interests.
- Behavior.
- Decisions.
- Experiences.
- Perspectives.
- Personal goals.

Insights must be supported by actual information.

Separate:

1. Observed information.
2. Possible interpretation.
3. Suggested action.

Never manufacture conclusions from insufficient data.

Do not reduce personal development to a single numerical score.

## 5.10 AI dependency safeguards — future

- Encourage independent reasoning.
- Ask for the user's own perspective.
- Avoid making decisions on the user's behalf.
- Sometimes recommend offline action.
- Keep journaling independent of AI.
- Avoid unnecessary engagement and notifications.

---

# 6. Visual Design

**Status: Undecided.**

Do not invent or finalize the visual identity during the initial architecture phase.

For now:

- Use a clean, consistent SwiftUI structure.
- Create reusable styling components.
- Keep layout and business logic separate.
- Avoid hardcoding colors and typography throughout individual views.
- Preserve the existing application icon.
- Make the interface adaptable to future light and dark themes.

The final visual direction will be developed separately.

---

# 7. Implementation Roadmap

Development should happen incrementally.

Each phase must be functional and testable before moving forward.

## Phase 1 — Foundation

Tasks:

- Inspect the existing repository and project folder.
- Preserve existing assets and useful project configuration.
- Configure the iOS 15 deployment target.
- Establish the application architecture.
- Set up Core Data.
- Implement basic application navigation.
- Create the initial screen structure.
- Establish reusable styling infrastructure.
- Configure Git checkpoints.
- Build and launch the app using Xcode.

Completion criteria:

- Project compiles with iOS 15 deployment target.
- App launches in the simulator.
- Navigation works.
- Core Data initializes successfully.
- No major runtime errors.

## Phase 2 — Journaling

Tasks:

- Implement JournalEntry.
- Create the editor.
- Save entries.
- Edit entries.
- Delete entries.
- Display journal history.
- Implement search and basic filtering.

Completion criteria:

- Entries persist after restarting.
- Editing and deletion work.
- Long entries are supported.
- No accidental loss of saved data.

## Phase 3 — Personal tracking

Tasks:

- Implement mood tracking.
- Implement memorable moments.
- Implement habit management.
- Add historical views.

Completion criteria:

- Records persist correctly.
- Users can edit and delete records.
- Historical information is displayed accurately.

## Phase 4 — AI integration foundation

Tasks:

- Define provider-independent AI interfaces.
- Define AI message and context models.
- Establish provider configuration.
- Implement connection and error handling.

Completion criteria:

- AI can be added without rewriting the journal.
- The application remains functional without AI.

## Phase 5 — Local AI

Tasks:

- Research on-device inference.
- Research PC-hosted inference.
- Compare model quality, speed, memory, and reliability.
- Implement a selected provider.
- Add provider configuration.

Completion criteria:

- AI can receive a request and return a response.
- Data is transmitted only to the explicitly selected local model.
- Connection failures do not affect journaling.

## Phase 6 — Long-term memory

Tasks:

- Memory extraction.
- Memory storage.
- Contextual retrieval.
- Memory updating.
- Memory inspection and deletion.

Completion criteria:

- Relevant memories are retrieved.
- Outdated information can be corrected.
- The user retains control.

## Phase 7 — Insights

Tasks:

- Historical analysis.
- Pattern identification.
- Evidence-based insights.
- Personal development tracking.
- Personalized recommendations.

Completion criteria:

- Insights reference actual data.
- Uncertainty is communicated.
- Insufficient data does not produce fabricated conclusions.

## Phase 8 — Integration and polish

Tasks:

- Finalize visual design.
- Improve animations.
- Test accessibility.
- Optimize performance.
- Test data migrations.
- Test offline behavior.
- Verify privacy and deletion.
- Test all implemented features.

Completion criteria:

- Core functionality works reliably.
- No critical bugs remain.
- Data persists correctly.
- Application works predictably with or without AI.

---

# 8. Development Rules for Cline

1. Inspect the existing project before modifying it.
2. Respect the Nola product specification.
3. Preserve the iOS 15 deployment target.
4. Use only compatible APIs or provide appropriate fallbacks.
5. Follow native SwiftUI conventions.
6. Use Core Data, not SwiftData.
7. Implement only the current development phase.
8. Do not invent features.
9. Do not introduce unnecessary dependencies.
10. Write readable and maintainable code.
11. Handle errors explicitly.
12. Add tests for important logic.
13. Never claim functionality works without verification.
14. Never delete or overwrite existing user data without explicit authorization.
15. Maintain Git checkpoints between major tasks.
16. Document important architectural decisions.
17. Clearly identify tasks requiring Xcode or a Mac.
18. If requirements are unclear, explain the uncertainty before making consequential decisions.

**Primary development principle:**

Build Nola as a reliable, enjoyable personal application. Prioritize actual usefulness, simplicity, privacy, and quality over feature quantity.

Do not rush into AI, advanced analytics, or final visual polish before the foundation works correctly.
---

# 9. Agreed Change List

## Completed

- Simplify note editing around autosave and a back chevron.
- Allow multiple mood check-ins on the same day and allow editing them without deletion.
- Use a dark emerald accent color.

## Planned

- Remove date-carousel animation; the seven-day strip should navigate by horizontal swipe without week arrows.
- Update Today’s date heading, section labels, Add-button alignment, and card styling as specified in Section 5.2.
- Add an Insights screen for suggested actions.
- Add a Progress screen for weekly and monthly reflections, with a top section for possible moments detected in journal entries. Ask the user to confirm before adding a possible moment; hide the section when there are no suggestions. Keep suggestions until the user confirms or dismisses them. Ask why when a suggestion is dismissed and use that feedback to avoid similar suggestions later.

## To define during implementation planning

- Final format and content structure for weekly and monthly Progress reflections.
- How guided-journaling sessions contribute to Insights and Progress.
- AI provider integration, privacy disclosures, and data transmission.

