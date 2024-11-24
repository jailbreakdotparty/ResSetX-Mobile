//
//  SettingsView.swift
//  ResSetX
//
//  Created by Skadz on 11/23/24.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("showLogs") private var showLogs: Bool = true
    @AppStorage("allowCustomResolution") private var allowCustomResolution: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    HStack {
                        Spacer()
                        VStack {
                            Text("ResSetX")
                                .font(.system(size: 50, weight: .medium))
                                .lineLimit(1)
                            Text("Made by the jailbreak.party team")
                                .font(.system(size: 20, weight: .regular))
                                .lineLimit(1)
                            Text("\nSpecial thanks to:\nleminlimez    Duy Tran    Lrdsnow\nlunginspector  Little_34306")
                                .font(.system(size: 12.5, weight: .light))
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    }
                    //                .listRowBackground(Color.clear)
                    
                    Section(header: Text("Resolution"), footer: Text("Attempting to set a custom resolution can very easily cause damage to your device. This is intended for advanced users only."), content: {
                        Toggle("Use custom resolution", isOn: $allowCustomResolution)
                    })
                    
                    Section(header: Text("Debug"), footer: Text("Disabling verbose logs may improve performance on older devices."), content: {
                        Toggle("Show verbose logs", isOn: $showLogs)
                    })
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
