//
//  ContentView.swift
//  ResSetX
//
//  Created by Skadz on 11/22/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct DeviceResolution: Hashable {
    var name: String
    var width: Int
    var height: Int
}

struct ContentView: View {
    @AppStorage("allowCustomResolution") private var allowCustomResolution: Bool = false
    @AppStorage("showLogs") private var showLogs: Bool = true
    @AppStorage("pairingFile") var pairingFile: String?
    @State var selectedPresetIndex = 0
    @State var width: Double = UIScreen.main.nativeBounds.width
    @State var height: Double = UIScreen.main.nativeBounds.height
    @State var showPairingFileImporter = false
    
    private let presets = [
        DeviceResolution(name: "iPhone 16 Pro Max", width: 1320, height: 2868),
        DeviceResolution(name: "iPhone 16 Pro", width: 1206, height: 2622),
        DeviceResolution(name: "iPhone 16 Plus/15 & 14 Pro Max", width: 1290, height: 2796),
        DeviceResolution(name: "iPhone 16/15 & 14 Pro", width: 1179, height: 2556)
    ]
    
    private var currentWidth: Int {
        allowCustomResolution ? Int(width) : presets[selectedPresetIndex].width
    }

    private var currentHeight: Int {
        allowCustomResolution ? Int(height) : presets[selectedPresetIndex].height
    }
    
    func getCurrentDevicePreset() -> Int {
        return presets.firstIndex { preset in
            preset.width == Int(width) && preset.height == Int(height)
        } ?? 0
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section(header: Text("Resolution"), content: {
                        if !allowCustomResolution {
                            Picker("Select Preset", selection: $selectedPresetIndex) {
                                ForEach(presets.indices, id: \.self) { index in
                                    Text(presets[index].name)
                                }
                            }
                            .pickerStyle(.automatic)
                        } else {
                            TextField("Width", value: $width, format: .number.grouping(.never))
                                .keyboardType(.decimalPad)
                                .modifier(fancyInputViewModifier())
                                .padding()
                                .multilineTextAlignment(.center)
                            HStack {
                                Spacer()
                                Text("x")
                                    .font(.system(size: 30, design: .monospaced))
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                            TextField("Height", value: $height, format: .number.grouping(.never))
                                .keyboardType(.decimalPad)
                                .modifier(fancyInputViewModifier())
                                .padding()
                                .multilineTextAlignment(.center)
                        }
                    })
                    
                    Section {
                        HStack {
                            Spacer()
                            Button(action: {
                                if pairingFile == nil {
                                    showPairingFileImporter.toggle()
                                } else {
                                    pairingFile = nil
                                    let pairingFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("pairingfile")
                                    do {
                                        try FileManager.default.removeItem(at: pairingFilePath!)
                                    } catch {
                                        print("[!] Failed to remove pairing file! Please manually delete it in the Files app.")
                                        return
                                    }
                                }
                            }) {
                                Text(pairingFile == nil ? "Select Pairing File" : "Reset Pairing File")
                            }
                            Spacer()
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                let fileManager = FileManager.default
                                let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
                                let targetPath = documentsDirectory?.appendingPathComponent("ressetX.plist")
                                let backupPath = documentsDirectory?.appendingPathComponent("backup/")
                                let backupPathWithUDID = backupPath?.appendingPathComponent("\(UDIDinator())/")
                                do {
                                    if fileManager.fileExists(atPath: targetPath!.path) {
                                        try fileManager.removeItem(at: targetPath!)
                                    }
                                    try createPlist(at: targetPath!)
                                    let data = try Data(contentsOf: targetPath!)
                                    if fileManager.fileExists(atPath: backupPath!.path) {
                                        try fileManager.removeItem(at: backupPath!)
                                    }
                                    try fileManager.createDirectory(at: backupPathWithUDID!, withIntermediateDirectories: true)
                                    let back = Backup(files: [
                                        Directory(path: "", domain: "ManagedPreferencesDomain"),
                                        Directory(path: "mobile", domain: "ManagedPreferencesDomain"),
                                        ConcreteFile(path: "mobile/com.apple.iokit.IOMobileGraphicsFamily.plist", domain: "ManagedPreferencesDomain", contents: data)
                                    ])
                                    try back.writeTo(directory: backupPathWithUDID!)
                                } catch {
                                    print("failed to create backup: \(error.localizedDescription)")
                                    return
                                }
                                DispatchQueue.global(qos: .background).async {
                                    restoreBackup(directory: backupPath!)
                                }
                            }) {
                                Text("Set Resolution to \(String(currentWidth))x\(String(currentHeight))")
                            }
                            .disabled(pairingFile == nil)
                            Spacer()
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: {
                                MobileDevice.rebootDevice(udid: UDIDinator())
                            }) {
                                Text("Reboot Device")
                            }
                            .disabled(pairingFile == nil)
                            Spacer()
                        }
                    }
                    
                    if showLogs {
                        Section(header: Text("Logs"), content: {
                            HStack {
                                Spacer()
                                LogView(udid: UDIDinator())
                                    .padding(0.25)
                                    .frame(width: 340, height: 340)
                                Spacer()
                            }
                        })
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .onAppear(perform: {
                selectedPresetIndex = getCurrentDevicePreset()
                _ = start_emotional_damage("127.0.0.1:51820")
                startMinimuxer()
            })
            .navigationTitle("ResSetX")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: SettingsView(), label: {
                        Image(systemName: "gear")
                    })
                }
            }
            .fileImporter(isPresented: $showPairingFileImporter, allowedContentTypes: [UTType(filenameExtension: "mobiledevicepairing", conformingTo: .data)!, UTType(filenameExtension: "mobiledevicepair", conformingTo: .data)!], onCompletion: { result in
                switch result {
                case .success(let url):
                    pairingFile = try! String(contentsOf: url)
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                    
                    let fileManager = FileManager.default
                    let pairingFilePath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("pairingfile")
                    do {
                        if fileManager.fileExists(atPath: pairingFilePath!.absoluteString) {
                            try fileManager.removeItem(at: pairingFilePath!)
                        }
                        try fileManager.copyItem(at: url, to: pairingFilePath!)
                    } catch {
                        return
                    }
                    
                    startMinimuxer()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            })
        }
    }
    
    func UDIDinator() -> String {
        if !MobileDevice.deviceList().isEmpty && ready() {
            print("[*] Got UDID! \(MobileDevice.deviceList()[0])")
            return MobileDevice.deviceList()[0]
        } else {
            return "00000420-0069696969696969"
        }
    }
    
    func startMinimuxer() {
        guard pairingFile != nil else {
            return
        }
        
        target_minimuxer_address()
        
        do {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.absoluteString
            try start(pairingFile!, documentsDirectory!)
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    func createPlist(at url: URL) throws {
        let 💀 : [String: Any] = [
            "canvas_height": currentHeight,
            "canvas_width": currentWidth,
        ]
        let data = NSDictionary(dictionary: 💀)
        data.write(to: url, atomically: true)
    }
    
    func restoreBackup(directory: URL) {
        let restoreArgs = [
            "idevicebackup2",
            "-n", "restore", "--no-reboot", "--system",
            directory.path(percentEncoded: false)
        ]
        print("Executing args: \(restoreArgs)")
        var argv = restoreArgs.map{ strdup($0) }
        let result = idevicebackup2_main(Int32(restoreArgs.count), &argv)
        print("idevicebackup2 exited with code \(result)")
    }
}

#Preview {
    ContentView()
}
