# Duwitku 💰

Duwitku is a comprehensive personal finance management application built with **Flutter**. It is designed to help users effortlessly track expenses, manage budgets, and gain valuable insights into their financial habits through a modern and intuitive interface.

## ✨ Key Features

- **📊 Smart Dashboard**: Get a quick overview of your balance, recent transactions, and budget status with smooth loading animations (Skeletonizer).
- **💸 Transaction Management**: Record income and expenses with detailed categories.
- **🧾 Receipt Scanning**: Scan physical receipts using the camera, automatically processing images for attachment and verification.
- **💰 Budget Planning**: Set monthly budgets for different categories to keep your spending in check.
- **📈 Visual Analytics**: Visualize your spending patterns with interactive charts using `fl_chart`.
- **🤖 AI Assistant**: Integrated Chat Prompt feature to assist with financial queries.
- **☁️ Cloud Sync**: Real-time data synchronization and secure storage using **Supabase**.
- **🔐 Secure Authentication**: Support for Email/Password login and Google Sign-In.
- **📤 Data Export**: Export your financial reports to **CSV** and **PDF** formats for external analysis.
- **🎨 Modern UI**: Beautiful design with **Flex Color Scheme**, supporting adaptive light and dark modes.

## 🛠 Tech Stack

This project utilizes a robust and modern tech stack:

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Backend & Auth**: [Supabase](https://supabase.com/)
- **State Management**: [Riverpod](https://riverpod.dev/) (with code generation)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)
- **HTTP Client**: [Dio](https://pub.dev/packages/dio)
- **UI Libraries**:
  - `flex_color_scheme` for theming
  - `google_nav_bar` for navigation
  - `flutter_slidable` for list actions
  - `skeletonizer` for loading states
- **Utils**: `flutter_image_compress`, `image_cropper`, `intl`, `logger`

## 📂 Project Structure

The codebase follows a maintainable and scalable layered architecture:

```text
lib/
├── controllers/    # Business logic and state management
├── models/         # Data models and entities
├── presenters/     # UI Logic and ViewModels
├── providers/      # Riverpod providers for dependency injection
├── repositories/   # Data access layer (Supabase integration)
├── services/       # External services (e.g., Receipt Service, Camera)
├── utils/          # Helper functions and constants
├── views/          # UI Screens (Home, Transaction, Budget, Auth, etc.)
└── widgets/        # Reusable UI components
```

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.9.2 or higher)
- Supabase Project (for backend)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/FadhilAlif/duwitku.git
   cd duwitku
   ```

2. **Install Dependencies**

   ```bash
   flutter pub get
   ```

3. **Configuration**

   Create a `.env` file in the root directory and add your Supabase configuration:

   ```env
   SUPABASE_URL=YOUR_SUPABASE_URL
   SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
   ```

4. **Run the App**

   ```bash
   flutter run
   ```

## 🤝 Contributing

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request.

## 📄 License

[MIT License](LICENSE)