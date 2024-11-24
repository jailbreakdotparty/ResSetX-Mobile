//
//  ResSetXApp.swift
//  ResSetX
//
//  Created by Skadz on 11/22/24.
//

import SwiftUI

@main
struct ResSetXApp: App {
    // Fix file picker (brought to you by Nugget-Mobile)
    init() {
        if let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, Selector(("fix_initForOpeningContentTypes:asCopy:"))), let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:))) {
            method_exchangeImplementations(origMethod, fixMethod)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
