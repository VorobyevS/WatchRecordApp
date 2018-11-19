//
//  InterfaceController.swift
//  WatchRecordApp WatchKit Extension
//
//  Created by ios dev on 11/15/18.
//  Copyright © 2018 ios dev. All rights reserved.
//

import WatchKit
import Foundation
import AVFoundation
import WatchConnectivity


final class InterfaceController: WKInterfaceController {
    private var isRecording = false
    private var recorder:AVAudioRecorder!
    private var recordURL: URL!
    let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    //MARK: Outlets
    @IBOutlet private weak var image: WKInterfaceImage!
    
    //MARK: Lifecycle
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
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
        isRecording ? stopRecording() : startRecording()
    }
    
    private func startRecording() {
        guard recorder == nil else { return }
        recordURL = path.appendingPathComponent(getTitleString())
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
        do {
            recorder = try AVAudioRecorder.init(url: recordURL, settings: settings)
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
    
    private func sendFile() {
        guard let record = recordURL else { return }
        WCSession.default.transferFile(record, metadata: nil)
    }
    
    private func getTitleString() -> String {
        let date = Date()
        let formater = DateFormatter()
        formater.dateFormat = "dd.MM.yyyy.mm.ss"
        return "record" + formater.string(from: date) + ".m4a"
    }
    
    private func setRecordImage(play: Bool) {
        play ? image.setImageNamed("stop") : image.setImageNamed("play")
        isRecording = play
    }
    
}

//MARK: WCSessionDeelgate
extension InterfaceController : WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let fileName = message["file"] as? String else { return }
        DispatchQueue.main.async {[weak self] in
            self?.presentAlert(withTitle: "File transfered",
                               message: fileName,
                               preferredStyle: .alert,
                               actions: [WKAlertAction(title: "Ok", style: .cancel, handler: {})])
        }
        try? FileManager.default.removeItem(at: path.appendingPathComponent(fileName))
    }
}

//MARK: AVAudioRecorderDelegate
extension InterfaceController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            sendFile()
        }
    }
}
