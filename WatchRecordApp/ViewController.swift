//
//  ViewController.swift
//  WatchRecordApp
//
//  Created by ios dev on 11/15/18.
//  Copyright © 2018 ios dev. All rights reserved.
//

import UIKit
import AVFoundation
import WatchConnectivity

final class ViewController: UIViewController {
    private var items = [AVURLAsset]()
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private var player : AVAudioPlayer?
    
    //MARK: Outlets
    @IBOutlet private weak var recordsTableView: UITableView!
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
        recordsTableView.register(UINib(nibName: "RecordTableViewCell", bundle: nil), forCellReuseIdentifier: RecordTableViewCell.indetifier)
        if (WCSession.isSupported()) {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    private func commonInit() {
        guard let tracks = try? FileManager.default.contentsOfDirectory(atPath: documentsDirectory.path) else { return }
        for item in tracks where item.hasSuffix(".m4a") {
            items.append(AVURLAsset(url: URL(fileURLWithPath: documentsDirectory.appendingPathComponent(item).path)))
        }
    }
    
    private func getFileNameFrom(URL: URL)-> String {
        return String(URL.path.split(separator: "/").last!)
    }
    
}

//MARK: TableViewDataSource, TableViewDelegate
extension ViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = recordsTableView.dequeueReusableCell(withIdentifier: RecordTableViewCell.indetifier) as! RecordTableViewCell
        cell.nameLabel.text = FileManager.default.displayName(atPath: items[indexPath.row].url.path)
        let totalSeconds = CMTimeGetSeconds(items[indexPath.row].duration)
        cell.durationLabel.text = "Duration: " +
                                            "\(Int(totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60):" +
                                            "\(Int(ceil(totalSeconds.truncatingRemainder(dividingBy: 60))))"
        cell.deleteAction = {[weak self] in
            guard let `self` = self else {return}
            do{
                let fileName = self.getFileNameFrom(URL: self.items[indexPath.row].url)
                try FileManager.default.removeItem(at: self.documentsDirectory.appendingPathComponent(fileName))
                self.items.remove(at: indexPath.row)
                self.recordsTableView.reloadData()
            }
            catch {
                print(error)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let fileName = self.getFileNameFrom(URL: items[indexPath.row].url)
        let fileUrl = documentsDirectory.appendingPathComponent(fileName)
        
        player = try? AVAudioPlayer.init(contentsOf: fileUrl)
        player?.play()
    }
}

//MARK  WCSessionDelegate
extension ViewController : WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        do {
            let fileName = self.getFileNameFrom(URL: file.fileURL)
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            try FileManager.default.moveItem(atPath: file.fileURL.path, toPath: fileURL.path)
            items.append(AVURLAsset.init(url: fileURL))
            DispatchQueue.main.async { [weak self] in
                self?.recordsTableView.reloadData()
            }
            WCSession.default.sendMessage(["file": fileName],
                                          replyHandler: nil,
                                          errorHandler: nil)
        }
        catch {
            print(error)
        }
    }
    
}
