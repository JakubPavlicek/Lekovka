# Lekovka

SwiftUI application for pill reminder with ESP32 integration.

## Main pages/views:

1. Login screen (if the user has not logged yet). It will use POST /users REST API (URL will be configurable) with email as request body. The API will return user ID which will be persisted on the device. And if this user ID is already present on the device, it will skip the login screen.

2. Timer page - 2 timers (one for day, one for night) for setting HH:mm and triggering notification at that time (with reminder notifications every 5 minutes until the pill is taken). This will also send a configuration to the ESP32 using the 'post-configuration-schedule' ESP32 endpoint (see the request body below in point 3.) and it will also call the REST API /schedules that takes { "time1": "string", "time2": "string" } as request body and X-User-Id header. The response body will be "[
  {
    "id": 0,
    "scheduled_time": "string",
    "user_id": 0
  }
]" where i need to save the schedule ids (id in the response body) for both morning and evening time. Because i then need to use the ID to DELETE /schedules/{id} REST API endpoint that takes the ID of the schedule.

3. BLE page - scanning for ESP32 device and receiving JSON data that the pills were taken, the 'medicaments-taken-confirmation' ESP32 -> iPhone app endpoint will be called when the pills are taken from the ESP32 side (the user will press the button on the ESP32 to confirm that the pills were taken) (this can be handled in the background as well - no need to visualize it). This will make the closest-time timer to be marked as taken. When i receive the 'medicaments-taken-confirmation' i need to make the REST API call to POST /intake-logs which takes only X-User-Id header. After successfull login and bluetooth connection to the ESP32, i need to send the UNIX timestamp using the 'post-ntc-time' to the ESP32 (this can be handled in the background as well - no need to visualize it). When i receive 'heartbeat' over the Bluetooth from the ESP32, i need to send the info to the REST API POST /intake-logs which also takes only X-User-Id header. And finally whenever i set the pill timers i need to send the info to the ESP32 using the 'post-configuration-schedule' where the 'interval_alert_trigger_minutes' property is 'notify_after_minutes' which i have saved in the persistent storage, the 'alert' property is the time in UNIX.
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
    - post-ntc-time
        ```
        {
            action: "post-ntc-time",
            current_timestamp: unixtimestamp
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
    - heartbeat
        ```
        {
            action: "heartbeat"
        }
        ```
    
4. Email/Contact form - pretty form for emails that will be send via REST API /caregivers that takes { "emails": ["string"] } as a request body and X-User-Id header (on the backend, the emails will receive an email when the person forgets to take the pills X times - meaning the notifications on the phone will cross the X notification count threshold)
