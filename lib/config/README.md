# Configuration Guide

This directory contains the application configuration for API endpoints and other settings.

## Setup Instructions

### 1. Initial Setup

Copy the template file to create your actual config:

```bash
cp lib/config/config.example.dart lib/config/app_config.dart
```

### 2. Update Your Configuration

Edit `lib/config/app_config.dart` and replace placeholder values with your actual API endpoints and credentials.

**Example:**
```dart
static const String aiAgentBaseUrl = 'https://your-actual-url.ngrok-free.dev';
```

### 3. Keep It Safe

The `app_config.dart` file is **automatically ignored by git** (see `.gitignore`). This prevents accidental commit of sensitive API keys and URLs.

## Configuration Files

### `app_config.dart` (Do not commit to Git)
Your actual configuration with real API keys and endpoints. This file is **gitignored** for security.

### `config.example.dart` (Commit to Git)
A template showing the structure and available configuration options. Share this with your team.

## Usage in Your Code

Import the config in your service files:

```dart
import '../config/app_config.dart';

// Use the configuration
final url = AppConfig.aiAgentBaseUrl;
final timeout = AppConfig.aiAgentTimeoutSeconds;
```

## Adding New Configuration

1. Add new constants to `config.example.dart` with placeholder values
2. Update `app_config.dart` with actual values
3. Use them throughout your app via `AppConfig.yourConstant`

## Best Practices

✅ **Do:**
- Use `AppConfig` for centralized configuration
- Keep sensitive data (API keys, URLs) out of version control
- Use `.gitignore` to protect `app_config.dart`
- Provide `config.example.dart` as a template for contributors

❌ **Don't:**
- Commit `app_config.dart` with real secrets
- Hardcode API keys in service files
- Share sensitive configuration in pull requests
