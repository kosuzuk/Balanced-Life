//
//  CalendarCell.swift
//  Balanced Life
//
//  Created by Koso Suzuki on 8/15/20.
//  Copyright © 2020 Koso Suzuki. All rights reserved.
//

import UIKit

class CalendarCell: UICollectionViewCell {
    @IBOutlet weak var markerImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    override func awakeFromNib() {
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.black.cgColor
    }
}
