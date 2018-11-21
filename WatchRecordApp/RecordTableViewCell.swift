//
//  RecordTableViewCell.swift
//  WatchRecordApp
//
//  Created by ios dev on 11/15/18.
//  Copyright © 2018 ios dev. All rights reserved.
//

import UIKit

final class RecordTableViewCell: UITableViewCell {    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    var deleteAction: (()->Void)?
    
    @IBAction private func deleteButtonClicked() {
        deleteAction?()
    }
}
