//
//  NotificationScheduler.swift
//  Blocklist
//
//  Created by Darcy Liu on 15/09/2023.
//

import Foundation
import UserNotifications

class NotificationScheduler {
    static func scheduleNotification(title: String, body: String, delay: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(delay, 1), repeats: false)
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
           if error != nil {
               // Handle any errors.
               print(error ?? "")
           }
        }
    }
}

