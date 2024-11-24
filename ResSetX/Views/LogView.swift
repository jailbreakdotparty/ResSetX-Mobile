import SwiftUI

struct StdoutLog: Identifiable, Equatable {
    let message: String
    let id = UUID()
}

struct LogView: View {
    @StateObject var logger = Logger.shared
    
    private var verbose: Bool = true
    
    let pipe = Pipe()
    let sema = DispatchSemaphore(value: 0)
    @State private var stdoutString = ""
    @State private var stdoutItems = [StdoutLog]()
    
    @State var verboseID = UUID()
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(stdoutItems) { item in
                        HStack {
                            Text(item.message)
                                .font(.system(size: 10, weight: .regular, design: .monospaced))
                                .multilineTextAlignment(.leading)
                                .id(item.id)
                            Spacer()
                        }
                        .frame(width: geometry.size.width)
                    }
                    .onChange(of: logger.logItems) { _ in
                        DispatchQueue.main.async {
                            proxy.scrollTo(logger.logItems.last!.id, anchor: .bottom)
                        }
                    }
                    .onAppear {
                        pipe.fileHandleForReading.readabilityHandler = { fileHandle in
                            let data = fileHandle.availableData
                            if data.isEmpty  { // end-of-file condition
                                fileHandle.readabilityHandler = nil
                                sema.signal()
                            } else {
                                stdoutString += String(data: data, encoding: .utf8)!
                                stdoutItems.append(StdoutLog(message: String(data: data, encoding: .utf8)!))
                            }
                        }
                        // Redirect
                        // print("Redirecting stdout")
                        setvbuf(stdout, nil, _IONBF, 0)
                        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
                    }
                }
                .contextMenu {
                    Button {
                        UIPasteboard.general.string = verbose ? stdoutString : Logger.shared.logString
                    } label: {
                        Label("Copy to clipboard", systemImage: "doc.on.doc")
                    }
                }
            }
        }
    }
}
