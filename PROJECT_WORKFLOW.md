# Project Workflow Documentation

## Overview
This project is a complete IoT-based energy monitoring and management system. It consists of three main components:

1. **ESP32 Firmware** (C++/Arduino): For real-time energy data acquisition and cloud sync.
2. **Flutter Mobile App**: For user interaction, visualization, and device management.
3. **Cloud Backend**: Firebase Realtime Database for device/app sync, and Supabase Edge Function for budget monitoring and notifications.

---

## 1. ESP32 Firmware (espcode/sketch_mar01a/sketch_mar01a.ino)

- **Connects to WiFi and NTP server** for time synchronization.
- **Authenticates with Firebase** using user credentials.
- **Main Loop (every 5 seconds):**
  - For each appliance registered in Firebase:
    - Reads configuration (voltage, calibration, GPIO, etc.) and stats (today/month energy, last reset).
    - Measures current using SCT-013 sensor (or generates test data if in test mode).
    - Calculates power and energy increment.
    - Handles daily/monthly resets, archiving stats to history nodes in Firebase.
    - Updates live readings and stats in Firebase under `/users/{uid}/devices/{esp_id}/appliances/{appliance_id}/`.

---

## 2. Firebase Realtime Database

- **Stores all user, device, and appliance data** in a structured, real-time accessible format.
- **Data Structure Example:**
  ```
  /users/{uid}/devices/{esp_id}/appliances/{appliance_id}/
    config/
    live/
    stats/
    history/
  ```
- **Acts as the central hub** for data exchange between ESP32 devices and the mobile app.

---

## 3. Flutter Mobile App

- **User Authentication** via Firebase Auth.
- **Device & Appliance Management:**
  - Users can view and manage their registered devices and appliances.
- **Real-Time Data Display:**
  - Subscribes to Firebase streams for live current, power, and energy stats.
- **Historical Data Visualization:**
  - Fetches daily/monthly energy history from Firebase.
  - Displays interactive charts and lists.
- **Forecasting:**
  - Performs linear regression on historical data to predict next day/month energy usage.
  - Shows trend and confidence.
- **Environmental Impact:**
  - Calculates and displays the carbon impact of energy usage.
- **User Actions:**
  - Configuration changes and commands are written back to Firebase.

---

## 4. Supabase Edge Function (Budget Monitoring & Notification)

- **Runs every 1 minute** (scheduled job).
- **For each user:**
  - **Aggregates overall monthly energy usage** by querying the relevant data (can be from Firebase or mirrored in Supabase).
  - **Checks if usage >= 80% of the user's monthly budget.**
  - **If threshold is reached/exceeded:**
    - Sends an email notification to the user (using Supabase's email service or integration).
- **Purpose:**
  - Provides proactive alerts to help users avoid exceeding their energy budget.
  - Ensures users are aware of their consumption trends in near real-time.

---

## 5. AI Assistant Workflow (Natural Language Control & Advice)

- **AI Assistant Server** (Node.js/Express, see server.js):
  - Receives user requests from the mobile app via HTTP POST (`/ask-ai`).
  - Maintains per-user conversation memory (context window, persistence, cleanup).
  - Parses user messages for intent:
    - If a command (add/update/delete appliance/device), executes the action by interacting with Firebase Realtime Database.
    - If a general query or advice request, generates a context-aware prompt and sends it to a local LLM (Ollama/llama3) for a natural language response.
  - Stores all exchanges and actions in Firestore for logging and analytics.
  - Supports endpoints for memory stats, clearing history, and health checks.

- **Mobile App Integration:**
  - User can interact with the AI assistant via chat interface in the app.
  - Sends userId and message to the server's `/ask-ai` endpoint.
  - Receives either a natural language reply or confirmation of a command (e.g., "Appliance added").
  - App displays the assistant's response and updates UI as needed.

- **Server Logic Highlights:**
  - Context-aware: Remembers recent conversation for each user.
  - Can execute device/appliance management commands (add, update, delete) via natural language.
  - Provides advice, summaries, and explanations using LLM.
  - Persists conversation history to disk and cleans up idle users.
  - Logs all interactions for traceability.

---

## 6. End-to-End Workflow (updated)

1. **Device Setup:**
   - User registers device and appliances via the app.
   - ESP32 device connects to WiFi and authenticates with Firebase.
2. **Data Acquisition:**
   - ESP32 measures current, calculates power/energy, and updates Firebase every 5 seconds.
3. **Data Visualization:**
   - Mobile app subscribes to Firebase streams for live and historical data.
   - Users view charts, stats, and environmental impact.
4. **AI Assistant Interaction:**
   - User sends a message or command via the app's chat interface.
   - The app sends the message and userId to the AI server (`/ask-ai`).
   - The server parses the message, executes commands if needed, or generates a natural language reply using the LLM.
   - The response is sent back to the app and displayed to the user.
   - All interactions are logged in Firestore.
5. **Budget Monitoring:**
   - Supabase Edge Function runs every minute, aggregates monthly usage, and checks against budget.
   - If usage >= 80% of budget, an email alert is sent to the user.
6. **User Notification:**
   - User receives email if approaching/exceeding budget.
   - User can adjust usage or settings as needed.

---

## 7. System Architecture (for diagramming, updated)

- **ESP32 Device(s):**
  - WiFi, NTP, Firebase client
  - Measures and uploads appliance data
- **Firebase Realtime Database:**
  - Central data store for all user/device/appliance data
  - Real-time sync for devices and app
- **Flutter Mobile App:**
  - Auth, data visualization, device management
  - Subscribes to Firebase data streams
  - Sends chat/command requests to AI assistant server
- **Supabase Edge Function:**
  - Scheduled job for budget monitoring
  - Aggregates usage, sends notifications
- **AI Assistant Server:**
  - Receives chat/command requests from the app
  - Maintains conversation memory per user
  - Executes device/appliance commands via Firebase
  - Generates natural language responses using LLM
  - Logs all interactions

---

## 8. Sequence of Operations (for UML sequence diagram, updated)

1. **ESP32 → Firebase:** Uploads live and historical data.
2. **App → Firebase:** Reads data, displays to user, writes config changes.
3. **Supabase Edge Function:**
   - Reads monthly usage per user.
   - If >= 80% budget, sends email.
4. **App → AI Assistant Server:** Sends user message, receives reply or command result, displays to user.
5. **AI Assistant Server:**
   - Parses message, executes command (if any) via Firebase, or generates advice using LLM.
   - Logs interaction in Firestore.
6. **User:** Receives notification, takes action if needed.

---

This document provides a comprehensive, self-contained explanation of the project workflow, suitable for generating architecture and sequence diagrams using external tools or models.
