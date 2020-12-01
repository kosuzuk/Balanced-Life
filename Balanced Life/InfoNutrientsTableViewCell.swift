//
//  InfoNutrientsTableViewCell.swift
//  Balanced Life
//
//  Created by Koso Suzuki on 8/16/20.
//  Copyright © 2020 Koso Suzuki. All rights reserved.
//

import UIKit

class InfoNutrientsTableViewCell: UITableViewCell {
    @IBOutlet weak var foodNameLabel: UILabel!
    @IBOutlet weak var meterView: UIView!
    @IBOutlet weak var meterViewWC: NSLayoutConstraint!
    var meterValue: Float = 0
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

}
