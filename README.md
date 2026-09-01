# Weatherly 🌤️

A simple and modern weather application built with Flutter that provides current weather information and hourly forecasts using the OpenWeather API.

## 📱 Screenshots

<p align="center">
  <img src="screenshots/weatherly-main.png" width="300" alt="Weatherly Main Screen">
</p>

## ✨ Features

- 🌡️ Current temperature
- 🌤️ Current weather condition
- 📍 Location-based weather information
- 🕐 Hourly weather forecast
- 💧 Humidity information
- 💨 Wind speed information
- 🌡️ Atmospheric pressure
- 🔄 Refresh weather data
- ⏳ Loading state
- ⚠️ Error handling
- 📱 Responsive Flutter UI

## 🛠️ Tech Stack

- **Flutter**
- **Dart**
- **OpenWeather API**
- **HTTP / REST API**
- **Material Design**

## 📂 Project Structure

```text
lib/
├── main.dart
├── weather_screen.dart
├── addinfo.dart
└── hourinfo.dart

screenshots/
└── weatherly-main.png
```

## 🚀 Getting Started

### Prerequisites

Make sure you have the following installed:

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Android device or emulator
- OpenWeather API key

### 1. Clone the Repository

```bash
git clone https://github.com/Pranay-Pandurang-Patil/Weatherly.git
```

### 2. Navigate to the Project

```bash
cd Weatherly
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Configure the API Key

Weatherly requires an OpenWeather API key to retrieve weather data.

1. Create an account on OpenWeather.
2. Generate your API key.
3. Create the following file:

```text
lib/secrets.dart
```

4. Add your API key to `secrets.dart` according to the configuration expected by the project.
5. Make sure `secrets.dart` is included in `.gitignore`.

> **Important:** Do not commit your API key or `secrets.dart` to a public repository.

### 5. Run the Application

```bash
flutter run
```

## 🔐 API

Weatherly uses the **OpenWeather API** to retrieve current weather and forecast information.

You can get an API key from the OpenWeather website.

### Why is the API key not included?

The API key is not included in this repository because it is a private credential and should not be publicly shared.

Each user should use their own OpenWeather API key when running the project.

## 📦 Build APK

To generate a release APK:

```bash
flutter build apk --release
```

The generated APK will be available at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 🎯 Purpose

Weatherly was created as a Flutter learning project to practice:

- Flutter UI development
- Dart programming
- REST API integration
- JSON data handling
- Asynchronous programming
- Loading and error state management
- Mobile application development

## 📸 Project Preview

Weatherly provides weather information through a clean and simple interface designed for quick access to important weather details.

## 👨‍💻 Author

**Pranay Pandurang Patil**

GitHub: **Pranay-Pandurang-Patil**

## 🙏 Acknowledgements

- Flutter
- Dart
- OpenWeather API

---

If you find this project useful, consider giving the repository a ⭐ on GitHub.
