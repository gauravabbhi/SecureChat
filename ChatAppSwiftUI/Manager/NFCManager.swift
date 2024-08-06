import Foundation
import CoreNFC

class NFCManager: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var session: NFCNDEFReaderSession?
    @Published var message = ""
    @Published var payload: String?
    var dataToWrite: String?
    var onScanComplete: ((String?) -> Void)?
    
    var appState: AppState // Reference to global state
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    func scan() {
        guard NFCNDEFReaderSession.readingAvailable else {
            message = "NFC scanning not supported on this device"
            return
        }
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near an NFC tag to scan"
        session?.begin()
    }
    
    func write(data: String) {
        guard NFCNDEFReaderSession.readingAvailable else {
            message = "NFC writing not supported on this device"
            return
        }
        dataToWrite = data
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "Hold your iPhone near an NFC tag to write data"
        session?.begin()
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        DispatchQueue.main.async {
            self.message = "Session began"
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let ndefMessage = messages.first, let record = ndefMessage.records.first,
              let payload = String(data: record.payload, encoding: .utf8) else {
            DispatchQueue.main.async {
                self.message = "No valid data found"
                self.onScanComplete?(nil)  // Notify scan completion with no valid data
            }
            return
        }
        DispatchQueue.main.async {
            self.message = "Read data: \(payload)"
            self.onScanComplete?(payload)  // Notify scan completion with the read data
            self.payload = payload
            self.appState.nfcData = payload
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if let dataToWrite = dataToWrite {
            guard let tag = tags.first else {
                session.invalidate(errorMessage: "No tag found")
                return
            }
            session.connect(to: tag) { error in
                if let error = error {
                    session.invalidate(errorMessage: "Connection error: \(error.localizedDescription)")
                    return
                }
                tag.queryNDEFStatus { status, _, error in
                    if let error = error {
                        session.invalidate(errorMessage: "Query status error: \(error.localizedDescription)")
                        return
                    }
                    switch status {
                    case .notSupported:
                        session.invalidate(errorMessage: "Tag is not NDEF compliant")
                    case .readOnly:
                        session.invalidate(errorMessage: "Tag is read-only")
                    case .readWrite:
                        let payload = NFCNDEFPayload(format: .nfcWellKnown, type: "T".data(using: .utf8)!, identifier: Data(), payload: dataToWrite.data(using: .utf8)!)
                        let message = NFCNDEFMessage(records: [payload])
                        tag.writeNDEF(message) { error in
                            if let error = error {
                                session.invalidate(errorMessage: "Write error: \(error.localizedDescription)")
                            } else {
                                session.alertMessage = "Data written successfully"
                                session.invalidate()
                            }
                        }
                    @unknown default:
                        session.invalidate(errorMessage: "Unknown tag status")
                    }
                }
            }
        } else {
            let tag = tags.first!
            session.connect(to: tag) { error in
                if let error = error {
                    session.invalidate(errorMessage: "Connection error: \(error.localizedDescription)")
                    return
                }
                tag.queryNDEFStatus { status, capacity, error in
                    if let error = error {
                        session.invalidate(errorMessage: "Query status error: \(error.localizedDescription)")
                        return
                    }
                    switch status {
                    case .notSupported:
                        session.invalidate(errorMessage: "Tag is not NDEF compliant")
                    case .readOnly, .readWrite:
                        tag.readNDEF { message, error in
                            if let error = error {
                                session.invalidate(errorMessage: "Read error: \(error.localizedDescription)")
                            } else if let message = message {
                                self.readerSession(session, didDetectNDEFs: [message])
                                session.invalidate()
                            } else {
                                session.invalidate(errorMessage: "No NDEF message found")
                            }
                        }
                    @unknown default:
                        session.invalidate(errorMessage: "Unknown tag status")
                    }
                }
            }
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.session = nil
            if let readerError = error as? NFCReaderError {
                switch readerError.code {
                case .readerSessionInvalidationErrorFirstNDEFTagRead, .readerSessionInvalidationErrorUserCanceled:
                    break
                default:
                    self.message = "Error: \(readerError.localizedDescription)"
                }
            } else {
                self.message = "Error: \(error.localizedDescription)"
            }
        }
    }
}
