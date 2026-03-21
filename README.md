# Lekovka

SwiftUI application for pill reminder with ESP32 integration.

## Main pages/views:

1. Login screen (if the user has not logged yet). It will use POST /users REST API (URL will be configurable) with email as request body. The API will return user ID which will be persisted on the device. And if this user ID is already present on the device, it will skip the login screen.
1. Timer page - 2 timers (day, night) for setting HH:mm and triggering notification at that time (with reminder notifications every 2 minutes until the pill is taken). This will also send a configuration using the 'post-configuration-schedule' ESP32 endpoint and it will also call the API
2. BLE page - scanning for ESP32 device and receiving JSON data that the pills were taken (this will disable the timer and notification)
  - **The Phone -> ESP32 API**
    - post-configuration-schedule
        ```
        {
            action: "post-configuration-schedule",
            body: {
                morning: {
                    interval_alert_trigger_minutes: int
                    alert: time
                },
                evening: {
                    interval_alert_trigger_minutes: int
                    alert: time
                }
            }
        }
        ```
  - **ESP32 -> Phone**
    - medicaments-taken-confirmation
        ```
        {
            action: "medicaments-taken-confirmation"
            body: {
                taken_at: datetime
            }
        }
        ```
    - heartbreak
        ```
        {
            action: "heartbreak"
        }
        ```
    
3. Email/Contact form - pretty form for emails that will be send via REST API /caregivers that takes { "emails": ["string"] } as a request body and X-User-Id header (on the backend, the emails will receive an email when the person forgets to take the pills X times - meaning the notifications on the phone will cross the X notification count threshold)
