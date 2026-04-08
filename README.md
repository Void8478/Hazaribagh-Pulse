<div align="center">
  <img src="assets/images/banner.png" alt="Hazaribagh Pulse Banner" width="100%" style="border-radius: 12px; margin-bottom: 24px;">

  # 🌟 Hazaribagh Pulse
  ### *The Digital Heartbeat of Your City*

  [![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
  [![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
  [![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
  [![License](https://img.shields.io/badge/License-MIT-gold?style=for-the-badge)](LICENSE)

  **Hazaribagh Pulse** is a premium, beautifully crafted local discovery and community application designed to digitally connect the residents of Hazaribagh. From exploring hidden gems and local businesses to engaging in community conversations and staying updated on upcoming events—Pulse is your ultimate city guide.
</div>

---

## 🚀 Overview

Built entirely entirely on a modern stack featuring **Flutter** and **Supabase**, Hazaribagh Pulse delivers a lightning-fast, highly responsive, and premium mobile-first experience. Deeply integrated with Supabase, it forms a robust backend network that powers real-time interactions, smooth loading states, and a beautifully optimized UI.

**Core Integrations:**
- 🔐 **Authentication** (Secure sign-ons & profiles)
- 🏢 **Listings & Categories** (Extensive business directories)
- 📝 **Posts & Events** (Dynamic community boards)
- ⭐ **Reviews & Comments** (Interactive user feedback)
- 🖼️ **Media Storage** (Supabase Storage for fast content delivery)
- ❤️ **Social Engagement** (Optimistic local Likes and Bookmarks)

---

## ✨ Features

### 👤 Identity & Profiles
*   **Seamless Onboarding**: Intuitive Supabase Auth flow with email signup and verification.
*   **Synchronized Profiles**: Automated secure matching between `auth.users` and the `profiles` table.
*   **Rich Customization**: Users can edit and upload their `avatar_url`, `bio`, `location`, and `full_name`.

### 🌍 Explore & Home Experience
*   **Trending & Top Rated**: Supabase-driven discovery matching you with the best places in town.
*   **Hidden Gems & Upcoming Events**: Curated feeds to keep the community constantly engaged.
*   **Dynamic Categories**: Fluid navigation through customized neighborhood pillars.
*   **Premium UX**: Elegant Skeleton loaders, polished empty states, and graceful error boundary handling.

### ✍️ Content Creation Engine
*   **Community Posts**: Share updates, alerts, and stories instantly.
*   **Local Event Publishing**: Keep the community aware of upcoming dates and gatherings.
*   **Place Listings**: Easily contribute new shops, cafes, or landmarks.
*   **Media Gallery**: Upload high-quality cover images securely via Supabase Storage.

### 💬 Social & Community Engine
*   **Engagement Tracking**: Real-time Like and Save (Bookmark) features dynamically updated optimistically.
*   **Discussion Spaces**: Nested comment sections attached to both Posts and Events.
*   **Authentic Reviews**: 5-Star rating system with text reviews for Places/Listings.
*   **Safe Handling**: Smart scaling ensuring ID integrity (`uuid` vs `bigint`) and guarded authenticated routes.

---

## 🛠️ Architecture & Tech Stack

Following a strict **Feature-First Architecture**, the project codebase is highly modular, maintainable, and scalable.

| Technology | Purpose |
| :--- | :--- |
| **Flutter** | Cross-platform mobile UI rendering engine |
| **Riverpod (v2)** | Reactive state management, async caching, and dependency injection |
| **Go Router** | Robust, deep-linked application navigation |
| **Supabase Client** | Real-time backend-as-a-service (BaaS) connection |
| **Supabase Auth** | JWT-based session handling |
| **Supabase Storage** | Fast object caching and image hosting |

### 📂 Directory Structure

```text
lib/
├── core/              # Foundational routing, global themes, shared widgets, config
├── features/          # Feature-first modular design
│   ├── auth/          # Auth screens and Supabase auth logic
│   ├── bookmarks/     # Saved items & user bookmarks
│   ├── comments/      # Discussion threads for Posts/Events
│   ├── content/       # Modular creation flows (Post, Place, Event)
│   ├── events/        # Event indices and detail screens
│   ├── explore/       # Search logic & Category listings
│   ├── home/          # Dynamic dashboard feeds
│   ├── interactions/  # Like & Save controllers, Optimistic UI caching
│   ├── listings/      # Directory details and business logic
│   ├── posts/         # Social timeline feeds
│   ├── profile/       # User identity & configuration
│   └── reviews/       # 5-star rating mechanisms
├── models/            # Dart data models for Supabase serialization
└── main.dart          # Application bootstrap & ProviderScope
```

---

## 🗄️ Database Schema & SQL Notes

Hazaribagh Pulse relies on a heavily relational, optimized PostgreSQL database on Supabase.

*   `profiles.id` -> `uuid` (Foreign key to `auth.users.id` with `ON DELETE CASCADE`)
*   `categories.id` -> `int8 / bigint`
*   `listings.id` -> `int8 / bigint` (Matches `reviews.listing_id`)
*   `user_likes` / `user_bookmarks` -> Maps exactly using `content_id` (TEXT) and `content_type` ('post', 'place', 'event') for ultimate flexibility.

**Migration Map:**
All required SQL injections are located under `supabase/migrations/`:
- `20260408_create_profiles.sql`
- `20260408_create_content_tables.sql`
- `20260409_add_comments_and_reviews.sql`

---

## 🚦 Getting Started

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (Ensure `flutter doctor` is clear)
*   [Dart SDK](https://dart.dev/get-dart)
*   A configured [Supabase Project](https://supabase.com/)

### 🔧 Installation Guide

**1. Clone the Repository**
```bash
git clone https://github.com/Void8478/Hazaribagh-Pulse.git
cd Hazaribagh-Pulse
```

**2. Install Dependencies**
```bash
flutter pub get
```

**3. Configure Supabase Environment**
Add your Supabase URL and Anon Key to your configuration safely (often inside `lib/core/network/supabase_client.dart` or via a `.env` depending on your environment setup).
*Never commit your internal `.env` files to source control.*

**4. Execute SQL Migrations**
Open your Supabase SQL Editor and sequentially run the `.sql` files found within the `supabase/migrations` folder to build out the application schema, enable Row Level Security (RLS), and attach the proper policies.

**5. Launch The App**
```bash
flutter run
```

---

## 📜 Development Notes

*   **Optimistic UI:** Engagement buttons (like and save) instantly reflect state to the user before the database resolves, rolling back automatically on network errors.
*   **Protective Navigation:** Attempting to interact with content while unauthenticated securely routes the user back to `/login` via GoRouter.
*   **Asynchronous Context:** We strictly observe the `if (!context.mounted) return;` pattern preventing memory leaks and widget tree crashes when navigating across async gaps.

---

## 🤝 Contributing

We welcome contributions to make Hazaribagh Pulse even better!
1. **Fork** the project.
2. Create your **Feature Branch** (`git checkout -b feature/AmazingFeature`).
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`).
4. **Run** local analysis (`flutter analyze`).
5. **Push** to the Branch (`git push origin feature/AmazingFeature`).
6. Open a **Pull Request**.

---

<div align="center">
  <p>Distributed under the <b>MIT License</b>. See <a href="LICENSE">LICENSE</a> for more information.</p>
  <sub>Handcrafted for the people of Hazaribagh with 💙 using Flutter & Supabase.</sub>
</div>
