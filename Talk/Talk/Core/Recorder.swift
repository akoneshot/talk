import AVFoundation
import Foundation
import Combine

class Recorder: NSObject, ObservableObject {
    static let shared = Recorder()

    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var levelCallback: ((Float) -> Void)?
    private var currentRecordingURL: URL?

    // Audio settings optimized for Whisper
    private let audioSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 16000.0,  // Whisper expects 16kHz
        AVNumberOfChannelsKey: 1,   // Mono
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]

    private override init() {
        super.init()
    }

    // MARK: - Recording Control

    func startRecording(levelCallback: @escaping (Float) -> Void) {
        self.levelCallback = levelCallback

        // Create temporary file URL
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "talk_recording_\(Date().timeIntervalSince1970).wav"
        let url = tempDir.appendingPathComponent(fileName)
        currentRecordingURL = url

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: audioSettings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()

            // Start level metering
            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.updateAudioLevel()
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func stopRecording() -> URL? {
        levelTimer?.invalidate()
        levelTimer = nil
        levelCallback = nil

        audioRecorder?.stop()
        let url = currentRecordingURL
        audioRecorder = nil
        currentRecordingURL = nil

        return url
    }

    func cancelRecording() {
        levelTimer?.invalidate()
        levelTimer = nil
        levelCallback = nil

        audioRecorder?.stop()

        // Delete the recording file
        if let url = currentRecordingURL {
            try? FileManager.default.removeItem(at: url)
        }

        audioRecorder = nil
        currentRecordingURL = nil
    }

    // MARK: - Audio Level

    private func updateAudioLevel() {
        guard let recorder = audioRecorder else { return }

        recorder.updateMeters()
        let avgPower = recorder.averagePower(forChannel: 0)

        // Convert dB to linear scale (0 to 1)
        // avgPower is typically -160 to 0 dB
        let minDb: Float = -60
        let level = max(0, min(1, (avgPower - minDb) / (-minDb)))

        levelCallback?(level)
    }

    // MARK: - Audio File Conversion

    /// Converts audio file to Float32 samples at 16kHz for Whisper
    static func loadAudioSamples(from url: URL) throws -> [Float] {
        let file = try AVAudioFile(forReading: url)

        // Create a format for 16kHz mono Float32
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false) else {
            throw RecorderError.formatCreationFailed
        }

        // Create converter
        guard let converter = AVAudioConverter(from: file.processingFormat, to: format) else {
            throw RecorderError.converterCreationFailed
        }

        // Calculate output frame count
        let ratio = 16000.0 / file.processingFormat.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(file.length) * ratio)

        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: outputFrameCount) else {
            throw RecorderError.bufferCreationFailed
        }

        var error: NSError?
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 4096) else {
                outStatus.pointee = .noDataNow
                return nil
            }

            do {
                try file.read(into: inputBuffer)
                outStatus.pointee = inputBuffer.frameLength > 0 ? .haveData : .endOfStream
                return inputBuffer
            } catch {
                outStatus.pointee = .endOfStream
                return nil
            }
        }

        converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)

        if let error = error {
            throw error
        }

        // Extract Float32 samples
        guard let floatData = outputBuffer.floatChannelData?[0] else {
            throw RecorderError.sampleExtractionFailed
        }

        return Array(UnsafeBufferPointer(start: floatData, count: Int(outputBuffer.frameLength)))
    }
}

// MARK: - AVAudioRecorderDelegate

extension Recorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording finished unsuccessfully")
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Recording encode error: \(error)")
        }
    }
}

// MARK: - Errors

enum RecorderError: LocalizedError {
    case formatCreationFailed
    case converterCreationFailed
    case bufferCreationFailed
    case sampleExtractionFailed

    var errorDescription: String? {
        switch self {
        case .formatCreationFailed:
            return "Failed to create audio format"
        case .converterCreationFailed:
            return "Failed to create audio converter"
        case .bufferCreationFailed:
            return "Failed to create audio buffer"
        case .sampleExtractionFailed:
            return "Failed to extract audio samples"
        }
    }
}
