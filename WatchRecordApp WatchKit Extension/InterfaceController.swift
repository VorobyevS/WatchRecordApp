//
//  InterfaceController.swift
//  WatchRecordApp WatchKit Extension
//
//  Created by ios dev on 11/15/18.
//  Copyright © 2018 ios dev. All rights reserved.
//

import WatchKit
import AVFoundation
import WatchConnectivity


final class InterfaceController: WKInterfaceController {
    
    //MARK: Constants
    private struct Constants {
        static let recorderOptions = [ AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                                       AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
    }
    
    //MARK: Properties
    private var recorder:AVAudioRecorder!
    @IBOutlet private weak var image: WKInterfaceImage!
    
    //MARK: Lifecycle
    override func willActivate() {
        super.willActivate()
        if (WCSession.isSupported()) {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    override func didDeactivate() {
        super.didDeactivate()
        stopRecording()
    }
    
    //MARK: Actions
    @IBAction private func startStopButtonClicked() {
        recorder == nil ? startRecording() : stopRecording()
    }
    
    //MARK: Recordin Methods
    private func startRecording() {
        let recordURL = FileManager.documentDirectory.appendingPathComponent(getTitleString())
        do {
            recorder = try AVAudioRecorder.init(url: recordURL, settings: Constants.recorderOptions)
            recorder.delegate = self
            recorder.record()
            setRecordImage(play: true)
        }
        catch {
            print(error)
        }
    }
    
    private func stopRecording() {
        guard recorder != nil else { return }
        recorder.stop()
        recorder = nil
        setRecordImage(play: false)
    }
    
    private func getTitleString() -> String {
        let date = Date()
        let formater = DateFormatter()
        formater.dateFormat = "dd.MM.yyyy.mm.ss"
        return "record" + formater.string(from: date) + ".m4a"
    }
    
    private func setRecordImage(play: Bool) {
        play ? image.setImageNamed("stop") : image.setImageNamed("play")
    }
    
}

//MARK: WCSessionDeelgate
extension InterfaceController : WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let fileName = message[WCSession.SesionKeys.fileName.rawValue] as? String else { return }
        DispatchQueue.main.async {[weak self] in
            self?.presentAlert(withTitle: "File transfered",
                               message: fileName,
                               preferredStyle: .alert,
                               actions: [WKAlertAction(title: "Ok", style: .cancel, handler: {})])
        }
        try? FileManager.default.removeItem(at: FileManager.documentDirectory.appendingPathComponent(fileName))
    }
}

//MARK: AVAudioRecorderDelegate
extension InterfaceController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            WCSession.default.transferFile(recorder.url, metadata: nil)
        }
    }
}
