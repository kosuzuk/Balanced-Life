//
//  nutritionCheckerVC.swift
//  Balanced Life
//
//  Created by Koso Suzuki on 8/20/20.
//  Copyright © 2020 Koso Suzuki. All rights reserved.
//

import UIKit

fileprivate struct Response: Decodable {
    var parsed: [parsedData]
}

fileprivate struct parsedData: Decodable {
    var food: foodData
}

struct foodData: Decodable {
    var nutrients: [String: Float]
}

class nutritionCheckerVC: UIViewController {
    @IBOutlet weak var foodField: UITextField!
    @IBOutlet weak var gramsField: UITextField!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var noDataLabel: UILabel!
    @IBOutlet weak var calField: UILabel!
    @IBOutlet weak var carbsField: UILabel!
    @IBOutlet weak var proteinField: UILabel!
    @IBOutlet weak var fatField: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        noDataLabel.isHidden = true
    }
    
    func handleNoData() {
        noDataLabel.isHidden = false
        calField.text = "カロリー："
        carbsField.text = "炭水化物："
        proteinField.text = "タンパク質："
        fatField.text = "脂質："
        searchButton.isHidden = false
    }
    
    @IBAction func searchPressed(_ sender: Any) {
        var food = foodField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if gramsField.text! == "" {
            gramsField.text = "100"
        }
        guard let grams = Float(gramsField.text!) else {
            let alertController = UIAlertController(title: "エラー", message: "数字で分量を入力してください", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            self.present(alertController, animated: true, completion: nil)
            return
        }
        food = food.replacingOccurrences(of: " ", with: "%20")
        searchButton.isHidden = true
        let URLString = "https://api.edamam.com/api/food-database/v2/parser?ingr=\(food)&app_id=6a076ca7&app_key=21a97cd7c852973457dfddaaeb3934cc"
        if let url = URL(string: URLString) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    do {
                        let multiplier = grams / Float(100.0)
                        let res = try JSONDecoder().decode(Response.self, from: data)
                        if res.parsed.count != 0 {
                            let nutrientsData = res.parsed[0].food.nutrients
                            DispatchQueue.main.async {
                                self.noDataLabel.isHidden = true
                                self.calField.text = "カロリー：" + String(nutrientsData["ENERC_KCAL"]! * multiplier)
                                self.carbsField.text = "炭水化物：" + String(nutrientsData["CHOCDF"]! * multiplier)
                                self.proteinField.text = "タンパク質：" + String(nutrientsData["PROCNT"]! * multiplier)
                                self.fatField.text = "脂質：" + String(nutrientsData["FAT"]! * multiplier)
                                self.searchButton.isHidden = false
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.handleNoData()
                            }
                        }
                    } catch let error {
                        print(error)
                        DispatchQueue.main.async {
                            self.handleNoData()
                        }
                    }
                } else {
                    self.handleNoData()
                }
            }.resume()
        } else {
            self.handleNoData()
        }
    }

}
