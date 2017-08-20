//
//  AppDelegate.swift
//  GameBoy
//
//  Created by Cole van Krieken on 7/14/17.
//  Copyright (c) 2017 Cole van Krieken. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    weak var windowController: WindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {

    }

    func applicationWillTerminate(_ aNotification: Notification) {

    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        if let gameViewController = windowController?.contentViewController as? GameViewController {
            return gameViewController.openFile(filename)
        }
        return false
    }
}

