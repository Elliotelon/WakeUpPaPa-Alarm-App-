//
//  MangoPaPaApp.swift
//  MangoPaPa
//
//  Created by 김민규 on 1/6/26.
//

import SwiftUI
import SwiftData

@main
struct MangoPaPaApp: App {
    var body: some Scene {
            WindowGroup {
                ContentView()
            }
            .modelContainer(for: MyNote.self)
        }
}
