import SwiftUI
import AVFoundation
import Speech

struct ContentView: View {
    @StateObject var llamaState = LlamaState()
    @State private var isListening = false
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var recognizedText = ""
    
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    
    var body: some View {
        VStack {
            Button(action: {
                playInitialMessage()
            }) {
                Text("Play")
            }
            .padding()
            
            if isListening {
                Text("Listening...")
            }
            
            ScrollView {
                Text(llamaState.messageLog)
                    .padding()
            }
            
            Button(action: {
                if isListening {
                    stopListening()
                } else {
                    startListening()
                }
            }) {
                Text(isListening ? "Stop" : "Start")
            }
            .padding()
            
            NavigationLink(destination: DrawerView(llamaState: llamaState)) {
                Text("View Models")
            }
            .padding()
        }
    }
    
    func playInitialMessage() {
        let initialMessage = "Welcome! How can I assist you today?"
        speakText(initialMessage)
        llamaState.messageLog += "AI: \(initialMessage)\n"
    }
    
    func startListening() {
        isListening = true
        recognizedText = ""
        
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    do {
                        try self.startRecording()
                    } catch {
                        print("Failed to start recording: \(error)")
                    }
                } else {
                    print("Speech recognition authorization denied")
                }
            }
        }
    }
    
    func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }
        
        isListening = false
        processVoiceInput(recognizedText)
    }
    
    func processVoiceInput(_ input: String) {
        llamaState.messageLog += "User: \(input)\n"
        Task {
            await llamaState.complete(text: input)
            if let response = llamaState.messageLog.components(separatedBy: "\n").last {
                speakText(response)
            }
        }
    }
    
    func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
    
    private func startRecording() throws {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                self.recognizedText = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
}

struct DrawerView: View {

    @ObservedObject var llamaState: LlamaState
    @State private var showingHelp = false
    func delete(at offsets: IndexSet) {
        offsets.forEach { offset in
            let model = llamaState.downloadedModels[offset]
            let fileURL = getDocumentsDirectory().appendingPathComponent(model.filename)
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("Error deleting file: \(error)")
            }
        }

        llamaState.downloadedModels.remove(atOffsets: offsets)
    }

    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    var body: some View {
        List {
            Section(header: Text("Download Models From Hugging Face")) {
                HStack {
                    InputButton(llamaState: llamaState)
                }
            }
            Section(header: Text("Downloaded Models")) {
                ForEach(llamaState.downloadedModels) { model in
                    DownloadButton(llamaState: llamaState, modelName: model.name, modelUrl: model.url, filename: model.filename)
                }
                .onDelete(perform: delete)
            }
            Section(header: Text("Default Models")) {
                ForEach(llamaState.undownloadedModels) { model in
                    DownloadButton(llamaState: llamaState, modelName: model.name, modelUrl: model.url, filename: model.filename)
                }
            }

        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle("Model Settings", displayMode: .inline).toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Help") {
                    showingHelp = true
                }
            }
        }.sheet(isPresented: $showingHelp) {
            VStack(alignment: .leading) {
                VStack(alignment: .leading) {
                    Text("1. Make sure the model is in GGUF Format")
                            .padding()
                    Text("2. Copy the download link of the quantized model")
                            .padding()
                }
                Spacer()
               }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
