import SwiftUI

struct LogView: View {
    let pipe = Pipe()
    let sema = DispatchSemaphore(value: 0)
    @State var log: String = ""
    @State var udid: String
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    Text(log)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .multilineTextAlignment(.leading)
                    Spacer()
                        .id(0)
                }
                .onAppear {
                    pipe.fileHandleForReading.readabilityHandler = { fileHandle in
                        let data = fileHandle.availableData
                        if data.isEmpty  { // end-of-file condition
                            fileHandle.readabilityHandler = nil
                            sema.signal()
                        } else {
                            var logString = String(data: data, encoding: .utf8)!
                            if logString.contains(udid) {
                                logString = logString.replacingOccurrences(of: udid, with: "<redacted>")
                            }
                            log.append(logString)
                            DispatchQueue.main.async {
                                proxy.scrollTo(0)
                            }
                        }
                    }
                    // Redirect
                    // print("Redirecting stdout")
                    setvbuf(stdout, nil, _IONBF, 0)
                    dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
                }
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = log
                    } label: {
                        Label("Copy to clipboard", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }
}
