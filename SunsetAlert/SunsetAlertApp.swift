//
//  MenuBarPopoverApp.swift
//  MenuBarPopover
//
//  Created by Zafer Arıcan on 8.07.2020.
//  Modified by John Dudmesh 7/2/2022
//
// Icons from here: https://www.flaticon.com/free-icon/sunrise_1852515?term=sunset&page=1&position=3&page=1&position=3&related_id=1852515&origin=tag#
// and here https://www.flaticon.com/free-icon/location-pin_3179068?related_id=3179068&origin=search#
// Sounds from here https://freesound.org/people/InspectorJ/sounds/439472/

import SwiftUI
import AVFoundation
import UserNotifications

@main
struct SunsetAlertApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init() {
      AppDelegate.shared = self.appDelegate
    }
    /*  For #2 I followed the solution in https://stackoverflow.com/a/65789202/827681 */
    var body: some Scene {
        Settings{
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared : AppDelegate!
    
    var popover = NSPopover.init()
    var statusBarItem: NSStatusItem?
    var timer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        let contentView = ContentView()
        contentView.fetchSunsetTime()

        // Set the SwiftUI's ContentView to the Popover's ContentViewController
        popover.behavior = .transient
        popover.animates = false
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = NSHostingView(rootView: contentView)
        popover.contentViewController?.view.window?.makeKey()
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBarItem?.button?.image = #imageLiteral(resourceName: "sunrise16x16.png")
        statusBarItem?.button?.action = #selector(AppDelegate.togglePopover(_:))
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                debugPrint("All set!")
            } else if let error = error {
                debugPrint(error.localizedDescription)
            }
        }
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { t in
            contentView.fetchSunsetTime()
            // get the next sunset if not already set
            if contentView.nextSunset.time == nil {
                contentView.fetchSunsetTime()
                return
            }
            
            // sunset is in the past so show an alert and refresh
            if contentView.nextSunset.time!.timeIntervalSinceNow < 0 {
                self.showPopover(nil)
                self.playAlarm()
                contentView.fetchSunsetTime()
            }
        }
        
    }
    
    func playAlarm() {
        
        NSSound(named: "cock-a-doodle-do")?.play()
        
        let content = UNMutableNotificationContent()
        content.title = "Sunset Alert"
        content.subtitle = "It's sunset!"
        content.sound = UNNotificationSound.default

        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if timer != nil {
            timer?.invalidate()
        }
    }
    
    @objc func showPopover(_ sender: AnyObject?) {
        if let button = statusBarItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    @objc func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
}
