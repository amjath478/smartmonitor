#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <time.h>

/* ================= WIFI ================= */
#define WIFI_SSID     "Parava"
#define WIFI_PASSWORD "12345678"

/* ================= FIREBASE ================= */
#define API_KEY       "AIzaSyAmWWmgtmzsrMNXKcVbeQp6Q5gaVrnI6ck"
#define DATABASE_URL  "https://smart-onitor-default-rtdb.asia-southeast1.firebasedatabase.app/"

/* ================= USER AUTH ================= */
#define USER_EMAIL    "amjathps153@gmail.com"
#define USER_PASSWORD "parava123@"

/* ================= DEVICE ================= */
#define ESP_ID "esp2"

/* ================= MODE ================= */
#define TEST_MODE true

/* ================= NTP ================= */
#define NTP_SERVER      "pool.ntp.org"
#define GMT_OFFSET_SEC  19800
#define DST_OFFSET_SEC  0

/* ================= SCT-013 CONFIG ================= */
#define ADC_REF             3.3
#define ADC_RESOLUTION      4095
#define SCT_CALIBRATION     50.0
#define NO_SIGNAL_THRESHOLD 0.02
#define SCT_SAMPLES         2000

// ── Three separate FirebaseData objects — no cross-contamination ──
FirebaseData fbdo;       // main read/write for live+stats
FirebaseData fbdoList;   // shallow listing of appliances
FirebaseData fbdoReset;  // exclusively for reset history writes
// ─────────────────────────────────────────────────────────────────

FirebaseAuth auth;
FirebaseConfig config;

String UID;
String basePath;
unsigned long lastUpdate = 0;
const int interval = 5000;

/* ================= SANITIZE KEY ================= */
String sanitizeKey(String key) {
  String result = "";
  for (int i = 0; i < key.length(); i++) {
    char c = key[i];
    if (c == ' ' || c == '.' || c == '#' ||
        c == '$' || c == '[' || c == ']') {
      result += '_';
    } else {
      result += c;
    }
  }
  return result;
}

/* ================= WIFI ================= */
void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting WiFi");
  while (WiFi.status() != WL_CONNECTED) { delay(500); Serial.print("."); }
  Serial.println("\nWiFi Connected");
}

/* ================= NTP EPOCH TIME ================= */
unsigned long getEpochTime() {
  time_t now;
  struct tm timeInfo;
  if (!getLocalTime(&timeInfo)) {
    Serial.println("⚠ NTP time not available");
    return 0;
  }
  time(&now);
  return (unsigned long)now;
}

/* ================= GET TIME STRUCT ================= */
bool getTimeStruct(struct tm &timeInfo) {
  if (!getLocalTime(&timeInfo)) {
    Serial.println("⚠ Failed to get local time");
    return false;
  }
  return true;
}

/* ================= FORMAT DATE YYYY-MM-DD ================= */
String formatDate(struct tm &t) {
  char buf[12];
  snprintf(buf, sizeof(buf), "%04d-%02d-%02d",
           t.tm_year + 1900, t.tm_mon + 1, t.tm_mday);
  return String(buf);
}

/* ================= FORMAT MONTH YYYY-MM ================= */
String formatMonth(struct tm &t) {
  char buf[8];
  snprintf(buf, sizeof(buf), "%04d-%02d",
           t.tm_year + 1900, t.tm_mon + 1);
  return String(buf);
}

/* ================= CURRENT MEASUREMENT ================= */
float getCurrent(int gpioPin, float calibration) {
  if (TEST_MODE) {
    if (random(0, 10) > 7) return random(50, 120) / 10.0;
    else                    return random(10, 40)  / 10.0;
  } else {
    analogReadResolution(12);
    analogSetAttenuation(ADC_11db);

    float sum = 0;
    for (int i = 0; i < SCT_SAMPLES; i++) sum += analogRead(gpioPin);
    float offsetADC = sum / SCT_SAMPLES;

    float sumSq = 0;
    for (int i = 0; i < SCT_SAMPLES; i++) {
      int   adc     = analogRead(gpioPin);
      float voltage = ((adc - offsetADC) * ADC_REF) / ADC_RESOLUTION;
      sumSq += voltage * voltage;
    }
    float vrms = sqrt(sumSq / SCT_SAMPLES);

    if (vrms < NO_SIGNAL_THRESHOLD) {
      Serial.println("  ⚠ No AC signal on GPIO " + String(gpioPin));
      return 0.0;
    }
    float cal = (calibration > 0.0) ? calibration : SCT_CALIBRATION;
    return vrms * cal;
  }
}

/* ================= ENERGY CALC ================= */
float calculateEnergy(float power, float seconds) {
  return (power * seconds) / 3600000.0;
}

/* ================================================================
   HANDLE RESETS
   - All history writes use direct setFloat() to exact paths
     via fbdoReset — completely isolated from fbdo
   - Guard values returned via reference so main updateNode()
     always includes them — they can never disappear
   ================================================================ */
void handleResets(
  String  appliancePath,
  String  currentDate,
  String  currentMonth,
  float   todayEnergy,
  float   monthEnergy,
  String  lastResetDay,
  String  lastResetMonth,
  float  &todayOut,
  float  &monthOut,
  String &lastResetDayOut,
  String &lastResetMonthOut,
  bool   &dailyReset,
  bool   &monthlyReset
) {
  todayOut          = todayEnergy;
  monthOut          = monthEnergy;
  lastResetDayOut   = lastResetDay;
  lastResetMonthOut = lastResetMonth;
  dailyReset        = false;
  monthlyReset      = false;

  // ── Daily reset ───────────────────────────────────────────
  if (lastResetDay != currentDate) {
    Serial.println("  ★ Daily reset  | was:" + lastResetDay +
                   " now:" + currentDate);

    if (lastResetDay != "") {
      // ✅ Direct path write — no nesting, no overwrite risk
      String histPath = appliancePath + "/history/daily/" + lastResetDay;
      if (Firebase.RTDB.setFloat(&fbdoReset, histPath, todayEnergy)) {
        Serial.println("    → Archived daily " + lastResetDay +
                       " = " + String(todayEnergy, 5) + " kWh");
      } else {
        Serial.println("    ⚠ Daily archive failed: " + fbdoReset.errorReason());
      }
    } else {
      Serial.println("    → First boot: skipping daily archive");
    }

    todayOut        = 0.0;
    lastResetDayOut = currentDate;
    dailyReset      = true;
  }

  // ── Monthly reset ─────────────────────────────────────────
  if (lastResetMonth != currentMonth) {
    Serial.println("  ★ Monthly reset | was:" + lastResetMonth +
                   " now:" + currentMonth);

    if (lastResetMonth != "") {
      // ✅ Direct path write — no nesting, no overwrite risk
      String histPath = appliancePath + "/history/monthly/" + lastResetMonth;
      if (Firebase.RTDB.setFloat(&fbdoReset, histPath, monthEnergy)) {
        Serial.println("    → Archived monthly " + lastResetMonth +
                       " = " + String(monthEnergy, 5) + " kWh");
      } else {
        Serial.println("    ⚠ Monthly archive failed: " + fbdoReset.errorReason());
      }
    } else {
      Serial.println("    → First boot: skipping monthly archive");
    }

    monthOut          = 0.0;
    lastResetMonthOut = currentMonth;
    monthlyReset      = true;
  }
}

/* ================= PROCESS SINGLE APPLIANCE ================= */
void processAppliance(String applianceKey,
                      String currentDate,
                      String currentMonth) {
  String safeKey       = sanitizeKey(applianceKey);
  String appliancePath = basePath + "/" + safeKey;

  // ── SINGLE READ: entire appliance node ────────────────────
  float  voltage        = 230.0;
  float  calibration    = SCT_CALIBRATION;
  float  peakCurrent    = 5.0;
  int    gpioPin        = 34;
  bool   enabled        = true;
  float  todayEnergy    = 0.0;
  float  monthEnergy    = 0.0;
  String lastResetDay   = "";
  String lastResetMonth = "";

  if (Firebase.RTDB.getJSON(&fbdo, appliancePath)) {
    FirebaseJson    &json = fbdo.jsonObject();
    FirebaseJsonData result;

    if (json.get(result, "config/voltage"))       voltage        = result.floatValue;
    if (json.get(result, "config/calibration"))   calibration    = result.floatValue;
    if (json.get(result, "config/gpioPin"))        gpioPin        = result.intValue;
    if (json.get(result, "config/peakCurrent"))   peakCurrent    = result.floatValue;
    if (json.get(result, "config/enabled"))        enabled        = result.boolValue;
    if (json.get(result, "stats/todayEnergy"))     todayEnergy    = result.floatValue;
    if (json.get(result, "stats/monthEnergy"))     monthEnergy    = result.floatValue;
    if (json.get(result, "stats/lastResetDay"))    lastResetDay   = result.stringValue;
    if (json.get(result, "stats/lastResetMonth"))  lastResetMonth = result.stringValue;
  } else {
    Serial.println("  ⚠ Failed to read: " + applianceKey +
                   " | " + fbdo.errorReason());
    return;
  }
  // ──────────────────────────────────────────────────────────

  if (!enabled) {
    Serial.println("Skipping (disabled): " + applianceKey);
    return;
  }

  // ── RESET CHECK — before energy increment ─────────────────
  float  todayAfterReset, monthAfterReset;
  String lastDayOut,      lastMonthOut;
  bool   dailyReset,      monthlyReset;

  handleResets(
    appliancePath,
    currentDate,     currentMonth,
    todayEnergy,     monthEnergy,
    lastResetDay,    lastResetMonth,
    todayAfterReset, monthAfterReset,
    lastDayOut,      lastMonthOut,
    dailyReset,      monthlyReset
  );
  // ──────────────────────────────────────────────────────────

  pinMode(gpioPin, INPUT);

  float current  = getCurrent(gpioPin, calibration);
  float power    = voltage * current;
  bool  peak     = current >= peakCurrent;
  unsigned long epochNow = getEpochTime();

  float energyIncrement = calculateEnergy(power, interval / 1000.0);
  todayAfterReset += energyIncrement;
  monthAfterReset += energyIncrement;

  // ── SINGLE WRITE: live + stats ─────────────────────────────
  // lastResetDay and lastResetMonth ALWAYS included → can never disappear
  FirebaseJson updateJson;
  updateJson.set("live/current",         current);
  updateJson.set("live/power",           power);

  updateJson.set("live/peak",            peak);
  updateJson.set("live/timestamp",       (int)epochNow);
  updateJson.set("stats/todayEnergy",    todayAfterReset);
  updateJson.set("stats/monthEnergy",    monthAfterReset);
  updateJson.set("stats/lastCalcTime",   (int)epochNow);
  updateJson.set("stats/lastResetDay",   lastDayOut);   // ← always written
  updateJson.set("stats/lastResetMonth", lastMonthOut); // ← always written

  if (Firebase.RTDB.updateNode(&fbdo, appliancePath, &updateJson)) {
    Serial.println("Updated : " + applianceKey                           +
                   " | I: "     + String(current, 3)         + "A"      +
                   " | P: "     + String(power, 1)           + "W"      +
                   " | Day: "   + String(todayAfterReset, 5) + " kWh"   +
                   " | Mon: "   + String(monthAfterReset, 5) + " kWh"   +
                   (dailyReset   ? " [DAY RESET]"   : "")               +
                   (monthlyReset ? " [MONTH RESET]" : ""));
  } else {
    Serial.println("  ⚠ Write failed: " + applianceKey +
                   " | " + fbdo.errorReason());
  }
  // ──────────────────────────────────────────────────────────
}

/* ================= PROCESS ALL APPLIANCES ================= */
void processAllAppliances() {
  Serial.println("\n===== SCANNING APPLIANCES =====");

  struct tm timeInfo;
  if (!getTimeStruct(timeInfo)) {
    Serial.println("⚠ Skipping cycle — time unavailable");
    return;
  }
  String currentDate  = formatDate(timeInfo);
  String currentMonth = formatMonth(timeInfo);
  Serial.println("Date: " + currentDate + " | Month: " + currentMonth);

  if (Firebase.RTDB.getShallowData(&fbdoList, basePath)) {
    FirebaseJson &json = fbdoList.jsonObject();
    size_t len = json.iteratorBegin();
    Serial.println("Total keys found: " + String(len));

    for (size_t i = 0; i < len; i++) {
      FirebaseJson::IteratorValue item = json.valueAt(i);
      String key = item.key;
      if (key == "live" || key == "stats" || key == "config") continue;
      Serial.println("APPLIANCE FOUND: " + key);
      processAppliance(key, currentDate, currentMonth);
    }

    json.iteratorEnd();
  } else {
    Serial.println("Failed to read appliances: " + fbdoList.errorReason());
  }
}

/* ================= SETUP ================= */
void setup() {
  Serial.begin(115200);

  connectWiFi();

  configTime(GMT_OFFSET_SEC, DST_OFFSET_SEC, NTP_SERVER);
  Serial.print("Syncing NTP");
  struct tm timeInfo;
  while (!getLocalTime(&timeInfo)) { delay(500); Serial.print("."); }
  Serial.println("\nNTP Synced | " + String(asctime(&timeInfo)));

  config.api_key      = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email     = USER_EMAIL;
  auth.user.password  = USER_PASSWORD;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Serial.print("Authenticating Firebase");
  while (auth.token.uid == "") { delay(500); Serial.print("."); }

  UID      = auth.token.uid.c_str();
  basePath = "/users/" + UID + "/devices/" + ESP_ID + "/appliances";

  Serial.println("\nFirebase Ready | Path: " + basePath);
  randomSeed(analogRead(0));
}

/* ================= LOOP ================= */
void loop() {
  connectWiFi();
  if (millis() - lastUpdate < interval) return;
  lastUpdate = millis();
  processAllAppliances();
}
