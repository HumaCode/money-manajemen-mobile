# 💰 Money Management Mobile 2.0 (Premium Financial Platform)

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture%20%2B%20BLoC-42A5F5?style=for-the-badge)
![Database](https://img.shields.io/badge/Offline%20First-SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![AI](https://img.shields.io/badge/AI%20Engine-Gemini%20%2B%20Receipt%20OCR-8E44AD?style=for-the-badge)

A cutting-edge, futuristic, and feature-packed personal finance tracking application built with Flutter & Dart. Features modern Dark Mode glassmorphism, offline-first synchronization, AI Receipt Scanner, Multi-Currency support, 2FA Security, Savings Goals, Smart Budgeting, and interactive visual charts.

---

## 📱 Screenshots Showcase

<div align="center">

| Splash Screen & Animations | Financial Dashboard | Analytics & Charts |
| :---: | :---: | :---: |
|<img src="https://github.com/user-attachments/assets/df63a6e5-e10f-4984-8339-2d39f1f82fae" width="240" /> | <img src="https://github.com/user-attachments/assets/1f8d71ee-b3f3-4f19-801b-c9a1e62be838" width="240" /> | <img src="https://github.com/user-attachments/assets/50fe8ff7-38bf-4c82-936b-78e072dd3f7d" width="240" /> |

| Smart Budgets | Savings Goals & Targets |
| :---: | :---: |
|  <img src="https://github.com/user-attachments/assets/8be9d276-2a4a-4b8c-9151-ef3a5563b75f" width="240" /> | <img src="https://github.com/user-attachments/assets/ce7f4c2b-9d21-41c4-a63f-f2bfb28272ee" width="240" /> |

</div>

---

## ✨ Key Features & Capability Matrix

### 🔐 1. Authentication & Security (2FA)
- **Email & Password Authentication**: Complete login, register, and token management.
- **Two-Factor Authentication (2FA)**: OTP verification for high-level account security.
- **Biometrics / Pin Lock**: Protection against unauthorized app access.

### 📊 2. Dashboard & Financial Overview
- **Dynamic Balance & Net Worth Display**: Real-time summary of total income, total expenses, and cash flow.
- **Dynamic Floating Particle Animation**: Modern background with interactive elements.
- **Recent Transactions List**: Quick peek into recent expenses with categories and accounts used.

### 💳 3. Multi-Account Management
- **Multiple Wallet Types**: Support for Cash, Bank Accounts (BCA, Mandiri, BRI, etc.), and E-Wallets (GoPay, OVO, Dana).
- **Inter-Account Transfer**: Seamlessly move money between accounts with transaction fee tracking.
- **Multi-Currency**: Convert and view values across IDR, USD, EUR, JPY, SGD, etc.

### 📈 4. Advanced Analytics & Smart Reports
- **Interactive Visual Charts**: Pie charts, line graphs, and category breakdowns.
- **Income vs Expense Analysis**: Weekly, monthly, and yearly breakdown.
- **Category Spending Details**: Track top spending areas automatically.

### 🎯 5. Savings Goals (Tabungan & Impian)
- **Target Tracking**: Set targets for buying gadgets, emergency funds, or vacations.
- **Progress Progress Bars**: Real-time progress percentage calculation with projected finish dates.
- **Contribution History**: Deposit and track savings milestones easily.

### 💡 6. Smart Budgeting System
- **Category Limit Alerts**: Set monthly spending limits per category (e.g. Food, Entertainment).
- **Over-budget Warning System**: Dynamic color indicators (Green -> Yellow -> Red) when nearing limits.

### 🤖 7. AI Receipt Scanner & Automation
- **OCR Receipt Reader**: Scan shopping bills/receipts using camera or gallery to auto-fill transaction forms.
- **Smart Auto-Categorization**: Machine learning auto-detects merchant names and categories.

---

## 🏗️ Architecture & Technology Stack

- **Framework**: Flutter 3.x (Dart 3.x)
- **State Management**: `flutter_bloc` (BLoC Pattern)
- **Local Database**: SQLite (`sqflite`) for Offline-First Data Persistence
- **Networking**: `http` / REST API Backend Synchronization
- **UI Design System**: Dark Glassmorphism, Custom Painters, Canvas Animations, Google Fonts (`Outfit`)

---

## 🔄 System Architecture & Flowchart (Mermaid)

### 1. High-Level System Data Flow

```mermaid
graph TD
    User([👤 User]) --> UI[📱 Flutter Presentation Layer / BLoC]
    UI --> Auth[🔐 Auth & Security Service]
    UI --> TxEngine[💸 Transaction & Budget Manager]
    UI --> OCR[🤖 AI Receipt Scanner]

    Auth --> LocalDB[(💾 Local SQLite DB)]
    TxEngine --> LocalDB
    OCR --> TxEngine

    LocalDB <--> SyncEngine[🔄 Offline-First Sync Engine]
    SyncEngine <--> API[🌐 Remote Laravel REST API]
```

### 2. User Authentication & 2FA Flow

```mermaid
flowchart TD
    Start([🚀 Launch App]) --> Splash[Splash Screen with Animated Floating Icons]
    Splash --> CheckToken{Check Saved Token?}
    CheckToken -- Token Valid --> Dashboard[📊 Dashboard Screen]
    CheckToken -- Token Invalid / Expired --> Login[🔐 Login Screen]
    
    Login --> EnterCredentials[User Inputs Email & Password]
    EnterCredentials --> Validate{Is Credentials Correct?}
    Validate -- No --> ErrorMsg[Display Error Toast] --> Login
    Validate -- Yes --> Check2FA{2FA Enabled?}
    
    Check2FA -- Yes --> OTPModal[📱 Open 2FA OTP BottomSheet]
    OTPModal --> VerifyOTP{Valid OTP Code?}
    VerifyOTP -- No --> OTPError[Invalid Code] --> OTPModal
    VerifyOTP -- Yes --> SaveSession[Save Token & User State] --> Dashboard
    
    Check2FA -- No --> SaveSession --> Dashboard
```

### 3. Transaction Creation & Smart Budgeting Flow

```mermaid
flowchart TD
    A([➕ User Tap Add Transaction]) --> B[Open Add Transaction Sheet]
    B --> C{Choose Input Method}
    C -- Manual Input --> D[Select Type: Expense / Income / Transfer]
    C -- Scan Receipt --> E[📷 Take Photo of Receipt]
    E --> F[🤖 AI OCR Extract Merchant, Date & Amount] --> D
    
    D --> G[Select Account & Category]
    G --> H[Input Amount & Note]
    H --> I[Tap Save]
    
    I --> J[(💾 Save to SQLite Local DB)]
    J --> K[⚡ Check Category Budget Limit]
    K -- Near/Over Limit --> L[🚨 Trigger Budget Warning Banner]
    K -- Normal --> M[Refresh Dashboard & Accounts Balance]
    L --> M
    M --> N[🔄 Async Background Sync to API]
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.0.0`
- Dart SDK `^3.0.0`
- Android Studio / VS Code with Flutter Extension

### Installation Steps

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/money-manajemen-mobile.git
   cd money-manajemen-mobile
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the Application**
   ```bash
   flutter run
   ```

---

## 📁 Directory Structure

```text
lib/
├── app/                  # Application Theme & Global Constants
├── core/                 # Shared Widgets, Helpers, Database, & Base Utilities
│   ├── database/         # SQLite Helper & Migrations
│   └── widgets/          # Buttons, Cards, Animations, Toasts
├── data/                 # Shared Data Models & Remote/Local Data Sources
└── features/             # Feature Modules (Clean Architecture)
    ├── accounts/         # Wallets & Account Management
    ├── analytics/        # Financial Analytics & Charts
    ├── auth/             # Authentication & 2FA
    ├── budgets/          # Category Budgeting
    ├── dashboard/        # Main Overview & Floating Particle Layout
    ├── profile/          # User Settings & Security
    ├── savings/          # Savings Goals & Milestones
    └── transactions/     # Add, Edit & Filter Transactions
```

---

## 📄 License
This project is licensed under the MIT License - see the `LICENSE` file for details.
