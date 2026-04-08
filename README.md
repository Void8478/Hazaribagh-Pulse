<div align="center">
  <img src="assets/images/banner.png" alt="Hazaribagh Pulse Banner" width="100%">

  # 🏙️ Hazaribagh Pulse
  ### *The Heartbeat of Your City*
  
  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
  [![License](https://img.shields.io/badge/License-MIT-gold?style=for-the-badge)](LICENSE)
  [![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-black?style=for-the-badge)](https://github.com/Void8478/Hazaribagh-Pulse/graphs/commit-activity)

  **Hazaribagh Pulse** is a premium, all-in-one local discovery and community platform built for the vibrant city of Hazaribagh. From discovering the best local businesses to staying updated with real-time events, it's designed to keep you connected.
</div>

---

## ✨ Premium Features

### 🏢 **Local Business Directory**
Discover top-rated services, shops, and businesses with a sleek, categorized interface. Filter by ratings, location, and popularity.

### 📅 **Real-time City Events**
Never miss a beat! Stay updated with local festivals, workshops, and community meetups happening around you.

### ⭐ **Community-Driven Reviews**
Share your experiences and read authentic feedback from the local community to make informed decisions.

### 🏆 **Dynamic Rankings**
See who's leading the city! Dynamic leaderboards for the "Best Cafes," "Top Schools," and more, updated based on user interactions.

### 🔖 **Smart Bookmarks & Favorites**
Save your favorite spots and upcoming events with one tap. Access them even when you're on the go.

### 🔍 **Advanced Explore & Search**
A powerful search engine coupled with a premium "Explore" page to find exactly what you need in seconds.

---

## 🎨 Design Philosophy: *Black & Gold*

The app features a **Premium Design System** built on a sophisticated Black & Gold palette, offering:
- 🖋️ **Elegant Typography** using Google Fonts (Outfit & Inter).
- ✨ **Glassmorphism Effects** for a modern, depth-focused UI.
- 🌊 **Smooth Micro-animations** and Shimmer loading effects.
- 🌓 **Native Dark & Light Mode** support for maximum comfort.

---

## 🛠️ Tech Stack & Architecture

| Technology | Purpose |
| :--- | :--- |
| **Flutter** | High-performance, cross-platform UI framework. |
| **Riverpod** | Enterprise-grade state management & dependency injection. |
| **Go Router** | Robust, type-safe declarative routing. |
| **Firebase Auth** | Secure authentication (Google, Email/Password). |
| **Firestore** | Real-time NoSQL database for city data. |
| **Firebase Storage** | Scalable asset and image hosting. |
| **Firebase App Check** | Integrated security and fraud prevention. |

### 📁 Project Structure
```text
lib/
├── core/           # Dependency injection, routing, theme, and constants.
├── features/       # Feature-first architecture (Auth, Home, Explore, etc.)
│   ├── auth/       # Authentication logic and UI
│   ├── listings/   # Business & service directory
│   ├── events/     # Real-time event tracking
│   └── ...         # Bookmarks, Profile, Reviews, Rankings
├── models/         # Global data models and schemas
└── main.dart       # App entry point and initialization
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.11.4 or higher)
- [Firebase CLI](https://firebase.google.com/docs/cli) installed and logged in.
- An Android/iOS emulator or physical device.

### 1. Clone the Repository
```bash
git clone https://github.com/Void8478/Hazaribagh-Pulse.git
cd Hazaribagh-Pulse
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Configuration
Ensure your `firebase_options.dart` is correctly generated. If starting fresh:
```bash
flutterfire configure
```

### 4. Run the Application
```bash
flutter run
```

---

## 🤝 Contributing

We welcome contributions to make **Hazaribagh Pulse** even better! 🚀
1. **Fork** the project.
2. **Create** your Feature Branch (`git checkout -b feature/AmazingFeature`).
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`).
4. **Push** to the branch (`git push origin feature/AmazingFeature`).
5. **Open** a Pull Request.

---

## 📄 License
Distributed under the **MIT License**. See `LICENSE` for more information.

<div align="center">
  <sub>Built with ❤️ for Hazaribagh.</sub>
</div>
