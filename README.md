# Harmony EyesNote 👁️📝

> An integrated "Notes + Health + AI" workspace for **HarmonyOS NEXT**, organizing, analyzing, and backing up your daily info in the blink of an eye.

## 📖 Project Overview

**Harmony EyesNote** evolves from a quick note-taking app into a comprehensive productivity hub. It introduces **AI-powered organization**, a **Health Data Cockpit**, **Statistical Dashboards**, and **System-level Backup Extensions**. This allows you to complete the full loop of **Record → Analyze → Insight → Backup** within a single app.

*   **Target Environment**: DevEco Studio 4.1+
*   **Support**: Real devices & NEXT Emulators

## 📸 Screenshots
<img width="300" height="645" alt="Screenshot_2025-11-20T174335" src="https://github.com/user-attachments/assets/407cba6d-65ce-4594-97db-78a966324e02" />
<img width="300" height="645" alt="Screenshot_2025-11-20T174342" src="https://github.com/user-attachments/assets/9f2f6de0-f29d-469f-b776-cdb4043c8e2a" />
<img width="300" height="645" alt="Screenshot_2025-11-20T174427" src="https://github.com/user-attachments/assets/4cc40b0e-0e0f-4c8f-acf3-07dfd7136941" />
<img width="300" height="645" alt="Screenshot_2025-11-20T174358" src="https://github.com/user-attachments/assets/5c0b8630-aea1-4418-b474-ee2cee7a93eb" />
<img width="300" height="645" alt="Screenshot_2025-11-20T174349" src="https://github.com/user-attachments/assets/5626a02b-9e88-4e3b-981c-1edffaf51e99" />

## ✨ Key Features

### 🧠 Multimodal Note Workspace
- **Dual-Panel View**: Instant notes vs. History with real-time word count.
- **Smart Templates**: One-click insertion of predefined templates (Meeting, Study, Shopping, Health).
- **Quick Tools**: Date/Time, To-do lists, Dividers, etc.
- **Customization**: Save custom templates permanently for recurring scenarios.

### 🤖 DeepSeek AI Organizer
- **Integrated API**: Built-in `DeepSeek Chat` interface within `NoteEditor.ets`.
- **Auto-Classification**: Automatically detects note types and outputs structured text.
- **Nutritionist Mode**: Detects diet/health keywords to generate meal plans, nutritional estimates, and storage advice.

### ❤️ Health Center & Tracking
- **Core Metrics**: Track Water Intake, Sleep, Steps, and Mood directly in `Index.ets`.
- **Data Persistence**: Writes data to `@ohos.data.preferences`.
- **Smart Analysis**: `HealthCalculator.ets` computes daily scores, trends, and improvement suggestions with visual cards.

### 📊 Statistical Cockpit
- **Comprehensive Views**: Overview of notes, health averages, today's score, and trend insights (`Statistics.ets`).
- **Export**: Export raw data as JSON for manual backup or cloud sync.
- **Multi-dimensional**: Weekly comparisons, mood frequency analysis, and recent records.

### 🎨 Themes & Personalization
- **Dynamic Theming**: Multiple preset themes + custom color palettes (`Theme.ets`).
- **Real-time Sync**: All pages update instantly when theme changes.
- **Native Feel**: Animated theme selectors and icon-based settings aligned with HarmonyOS design language.

### 🔒 Security & Backup
- **System Integration**: `EntryBackupAbility.ets` implements `onBackup/onRestore` hooks for HarmonyOS Backup Kit.
- **Manual Export**: Data export/clear functions in Settings for easy migration.

### 🚀 HarmonyOS Capabilities (Prepared)
- **Health Kit Skeleton**: `HealthKitSync.ets` provides the framework for syncing steps/sleep via `@ohos.health` (requires permission handling).

## 🏗️ System Structure

```text
entry/
├── src/main/ets
│   ├── entryability/EntryAbility.ets          # UIAbility Entry Point
│   ├── entrybackupability/EntryBackupAbility  # System Backup Extension
│   ├── pages/
│   │   ├── Index.ets                          # Main Workbench (Notes + Health + AI)
│   │   ├── NoteEditor.ets                     # Editor & DeepSeek AI Integration
│   │   ├── NoteDetail.ets                     # Historical Note Details
│   │   ├── Settings.ets                       # Settings, Data Mgmt, Themes
│   │   └── Statistics.ets                     # Stats & Health Insights
│   └── utils/
│       ├── Storage.ets                        # Preferences Wrapper (Singleton)
│       ├── Theme.ets                          # Theme Presets & Cloning
│       ├── HealthCalculator.ets               # Health Scoring Algorithm
│       ├── HealthKitSync.ets                  # Health Kit Interface Skeleton
│       └── Types.ets                          # Shared Type Definitions
├── src/main/resources                         # Assets (Themes, Media, Profile)
└── hvigorfile.ts / oh-package.json5           # Build & Dependency Config
```

## 🛠️ Environment Requirements
- **OS**: HarmonyOS NEXT
- **IDE**: DevEco Studio 5.0+

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/TsangHaotian/Harmony_EyesNote.git
cd Harmony_EyesNote
```

## 💾 Data & Backup Strategy
- **Local Storage**: All business data (notes, templates, health logs, preferences) is stored locally via `@ohos.data.preferences` using a unified `storage` singleton.
- **JSON Export**: `Statistics.ets` and `Settings.ets` can export all data as structured JSON for manual backup.
- **System Backup**: The `EntryBackupAbility.ets` skeleton is ready to integrate with the system backup channel for seamless migration.
- **Health Sync**: `HealthKitSync.ets` contains example code for permissions and data fetching; enabling `@ohos.health` will activate automatic sync.

## 🧪 Testing & Quality
- **UI Tests**: Hypium samples located at `entry/src/main/ohosTest/ets`.
- **Unit Tests**: Local unit tests at `entry/src/main/test/ets`.
- **Run Command**: `hvigorw test` or use the Test Panel in DevEco Studio.
- *Recommendation*: Add specific test files (e.g., `Storage.test.ets`) when introducing new data structures or algorithms.

## 🗺️ Roadmap
- [x] DeepSeek AI Organization & Template System
- [x] Visual Health Center & Stats Cockpit
- [x] Theme Editor & Custom Palette
- [x] Data Export & System Backup Skeleton
- [ ] HarmonyOS Health Kit Real-device Sync
- [ ] Cloud Backup & Multi-device Collaboration
- [ ] Advanced Charts & Achievement System

## 📬 Feedback & Support
- **Developer**: TsangHaotian
- **Email**: TsangHaotian@hotmail.com
- **GitHub**: 
