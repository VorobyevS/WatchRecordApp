//
//  FileManager+Extension.swift
//  WatchRecordApp
//
//  Created by Hela on 21/11/2018.
//  Copyright © 2018 ios dev. All rights reserved.
//

import Foundation

extension FileManager {
    static let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
}
