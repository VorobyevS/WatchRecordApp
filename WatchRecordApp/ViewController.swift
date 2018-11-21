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
    
    //MARK: Constants
    private struct Constants {
        static let nibName = "RecordTableViewCell"
        static let cellName = String(describing: RecordTableViewCell.self)
    }
    
    //MARK: Properties
    private var items = [AVURLAsset]()
    private var player : AVAudioPlayer?
    @IBOutlet private weak var recordsTableView: UITableView!
    
    //MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        commonInit()
        recordsTableView.register(UINib(nibName: Constants.nibName, bundle: nil), forCellReuseIdentifier: Constants.cellName)
        if (WCSession.isSupported()) {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    private func commonInit() {
        guard let tracks = try? FileManager.default.contentsOfDirectory(atPath: FileManager.documentDirectory.path) else { return }
        for item in tracks where item.hasSuffix(".m4a") {
            let fullURL = FileManager.documentDirectory.appendingPathComponent(item)
            items.append(AVURLAsset(url: fullURL))
        }
    }
    
    //MARK: Auxilary Methods
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
        let cell = recordsTableView.dequeueReusableCell(withIdentifier: Constants.cellName) as! RecordTableViewCell
        let item = items[indexPath.row]
        cell.nameLabel.text = getFileNameFrom(URL: item.url)
        let totalSeconds = CMTimeGetSeconds(item.duration)
        cell.durationLabel.text = "Duration: " +
                                            "\(Int(totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60):" +
                                            "\(Int(ceil(totalSeconds.truncatingRemainder(dividingBy: 60))))"
        cell.deleteAction = {[weak self] in
            guard let `self` = self else {return}
            do {
                try FileManager.default.removeItem(at: self.items[indexPath.row].url)
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
        let fileUrl = items[indexPath.row].url
        do {
            player = try AVAudioPlayer(contentsOf: fileUrl)
            player?.play()
        }
        catch {
            print(error)
        }
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
            let fileURL = FileManager.documentDirectory.appendingPathComponent(fileName)
            try FileManager.default.moveItem(atPath: file.fileURL.path, toPath: fileURL.path)
            items.append(AVURLAsset(url: fileURL))
            DispatchQueue.main.async { [weak self] in
                self?.recordsTableView.reloadData()
            }
            WCSession.default.sendMessage([WCSession.SesionKeys.fileName.rawValue: fileName],
                                          replyHandler: nil,
                                          errorHandler: nil)
        }
        catch {
            print(error)
        }
    }
    
}
