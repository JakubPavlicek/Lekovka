# Lekovka

SwiftUI application for pill reminder with ESP32 integration.

## Main pages/views:

1. Timer page - timer for setting HH:mm and triggering notification at that time (with reminder notifications every 3 minutes)
2. BLE page - scanning for ESP32 device and receiving JSON data that the pills were taken (this will disable the timer and notification)
3. API page - calling external API that the pills were taken
4. Notification page - push notifications of other people that took their pills (with their name and time)
