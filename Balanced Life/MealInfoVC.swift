//
//  MealInfoVC.swift
//  Balanced Life
//
//  Created by Koso Suzuki on 8/16/20.
//  Copyright © 2020 Koso Suzuki. All rights reserved.
//

import UIKit
import FirebaseStorage

infix operator ¡
//returns true if cell 1's index path row is less than cell 2's
func ¡(cell1: InfoNutrientsTableViewCell, cell2: InfoNutrientsTableViewCell) -> Bool {
    return cell1.tag < cell2.tag
}

class MealInfoVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var nutrientsTableView: UITableView!
    var mvc: MealsVC? = nil
    var mealData: [String: Any] = [:]
    var nutrientNameList = ["carbs", "protein", "veggies", "fruits", "sweets", "sodium", "healthiness"]
    var nutrientNameListJP = ["炭水化物", "タンパク質", "野菜", "フルーツ", "スイーツ", "塩分", "健康さ"]
    var pageDidAppear = false
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        7
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = nutrientsTableView.dequeueReusableCell(withIdentifier: "foodCell", for: indexPath) as! InfoNutrientsTableViewCell
        cell.foodNameLabel.text = nutrientNameListJP[indexPath.row]
        cell.meterValue = mealData[nutrientNameList[indexPath.row]] as? Float ?? 0
        if !pageDidAppear {
            cell.meterViewWC.constant = 0
        } else {
            cell.meterViewWC.constant = CGFloat(cell.meterValue) * cell.bounds.width * 0.8
        }
        cell.meterView.layer.cornerRadius = 7
        return cell
    }
    
    func animateMeters() {
        for cell in nutrientsTableView.visibleCells {
            let cell = (cell as! InfoNutrientsTableViewCell)
            let w = CGFloat(cell.meterValue) * cell.bounds.width * 0.8
            cell.meterViewWC.constant = w
            cell.meterView.frame.size.width = 0
            UIView.animate(withDuration: 0.4, delay: 0, options: UIView.AnimationOptions.curveEaseOut, animations: {
                cell.meterView.frame.size.width = w
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nutrientsTableView.delegate = self
        nutrientsTableView.dataSource = self
        titleLabel.text = mealData["title"] as? String
        descriptionTextView.text = mealData["description"] as? String
        descriptionTextView.layer.borderWidth = 1
        if let imageKey = mealData["imageKey"] as? String {
            view.addSubview(formatLoadingIcon(loadingIcon))
            loadingIcon.startAnimating()
            startNoInput()
            storage.child(imageKey).getData(maxSize: 3 * 1024 * 1024) {data, Error in
                if let Error = Error {
                    print(Error)
                    loadingIcon.stopAnimating()
                    endNoInput()
                    return
                }
                self.imageView.image = UIImage(data: data!)
                loadingIcon.stopAnimating()
                endNoInput()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        animateMeters()
        if mvc!.mealListDidChange {
            self.dismiss(animated: true, completion: nil)
        }
        pageDidAppear = true
    }
    
    @IBAction func editPressed(_ sender: Any) {
        performSegue(withIdentifier: "InfoToEdit", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as? MealEditVC
        if let mevc = vc {
            mevc.mvc = mvc
            mevc.mealInd = mvc!.selectedMealInd
            mevc.mealsData = mvc!.mealList
            mevc.imageData = imageView.image
            mevc.dateString = mvc!.dateString
        }
    }

}
