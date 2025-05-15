import Foundation
import UserNotifications
import CoreData

class NotificationManager {
    // MARK: - Singleton
    static let shared = NotificationManager()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Schedule a wake-up notification with the latest content
    func scheduleWakeUpNotification(at date: Date, enabled: Bool) {
        // First remove any existing scheduled notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["morningRadioWakeUp"])
        
        // If notifications are disabled, we're done
        guard enabled else { return }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Morning Radio"
        content.sound = .default
        
        // Get the latest scrap for the notification content
        fetchLatestScrap { scrapTitle in
            // Update the notification content with the latest scrap
            if let title = scrapTitle {
                content.body = title
            } else {
                content.body = "Your morning update is ready!"
            }
            
            // Create a calendar-based trigger
            let calendar = Calendar.current
            var dateComponents = DateComponents()
            dateComponents.hour = calendar.component(.hour, from: date)
            dateComponents.minute = calendar.component(.minute, from: date)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
            // Create the request
            let request = UNNotificationRequest(
                identifier: "morningRadioWakeUp",
                content: content,
                trigger: trigger
            )
            
            // Schedule the notification
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Update notification content with the latest scrap
    func updateNotificationContent() {
        // Get the pending notification requests
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            // Find our wake-up notification
            guard let wakeUpRequest = requests.first(where: { $0.identifier == "morningRadioWakeUp" }),
                  let trigger = wakeUpRequest.trigger as? UNCalendarNotificationTrigger else {
                return
            }
            
            // Get the latest scrap
            self.fetchLatestScrap { scrapTitle in
                // Create updated content
                let content = wakeUpRequest.content.mutableCopy() as! UNMutableNotificationContent
                
                if let title = scrapTitle {
                    content.body = title
                } else {
                    content.body = "Your morning update is ready!"
                }
                
                // Create a new request with the updated content but same trigger
                let newRequest = UNNotificationRequest(
                    identifier: "morningRadioWakeUp",
                    content: content,
                    trigger: trigger
                )
                
                // Remove the old request and add the new one
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["morningRadioWakeUp"])
                UNUserNotificationCenter.current().add(newRequest) { error in
                    if let error = error {
                        print("Error updating notification: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Fetch the latest scrap from Core Data
    private func fetchLatestScrap(completion: @escaping (String?) -> Void) {
        let context = PersistenceController.shared.container.viewContext
        
        let fetchRequest: NSFetchRequest<Scrap> = Scrap.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Scrap.timestamp, ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            if let latestScrap = results.first {
                completion(latestScrap.title ?? "New content available")
            } else {
                completion(nil)
            }
        } catch {
            print("Error fetching latest scrap: \(error.localizedDescription)")
            completion(nil)
        }
    }
} 