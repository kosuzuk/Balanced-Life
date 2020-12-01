//
//  MealsVC.swift
//  Balanced Life
//
//  Created by Koso Suzuki on 8/16/20.
//  Copyright © 2020 Koso Suzuki. All rights reserved.
//

import UIKit
import Firebase
import FirebaseFirestore
class MealsVC: UIViewController, UINavigationControllerDelegate {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var contentViewHC: NSLayoutConstraint!
    var MainVC: MainVC? = nil
    var dateString = ""
    var mealList: [[String: Any]] = []
    var mealButtons: [UIButton] = []
    var selectedMealInd = 0
    var selectedMealData: [String: Any] = [:]
    var mealListDidChange = false
    var newHealthValue: [String: Any] = [:]
    var curButtonY = 80.0
    
    func getMealsData(completetionHandler: @escaping (Bool) -> ()) {
        db.collection("meals").document(dateString).getDocument(completion: {(QuerySnapshot, Error) in
            if Error != nil {
                print(Error!)
                completetionHandler(false)
                return
            }
            let data = QuerySnapshot!.data()
            if data == nil {
                completetionHandler(false)
                return
            }
            self.mealList = data!["data"] as! [[String: Any]]
            completetionHandler(true)
        })
    }
    
    func getLabels(_ mealInd: Int) -> [UILabel] {
        let titleLabel = UILabel()
        titleLabel.text = mealList[mealInd]["title"] as? String
        titleLabel.font = UIFont.boldSystemFont(ofSize: 30)
        titleLabel.textColor = .white
        titleLabel.frame = CGRect(x: 10, y: 10, width: view.bounds.width * 0.8, height: 30)
        
        let descLabel = UILabel()
        descLabel.text = mealList[mealInd]["description"] as? String
        descLabel.numberOfLines = 10
        descLabel.font = UIFont(name: "Helvetica Neue", size: 15)
        descLabel.textColor = .white
        descLabel.frame = CGRect(x: 10, y: 35, width: view.bounds.width * 0.8, height: view.bounds.width * 0.35 - 30)
        
        return [titleLabel, descLabel]
    }
    
    func addButtons() {
        curButtonY = 110
        for i in 0..<mealList.count {
            let btn = UIButton()
            btn.backgroundColor = healthyGreen
            btn.layer.cornerRadius = 20
            btn.alpha = 0
            let w = view.bounds.width * 0.9
            let h = w * 0.4
            btn.frame = CGRect(x: (view.bounds.width - w) / 2, y: CGFloat(curButtonY), width: w, height: h)
            btn.addTarget(self, action: #selector(mealButtonPressed), for: .touchUpInside)
            let labels = getLabels(i)
            btn.addSubview(labels[0])
            btn.addSubview(labels[1])
            contentView.addSubview(btn)
            mealButtons.append(btn)
            curButtonY += Double(h) + 20.0
        }
    }
    
    func fadeInButtons() {
        for i in 0..<mealButtons.count {
            let delay = Double(i) * 0.3
            mealButtons[i].frame.origin.y += 20
            UIView.animate(withDuration: 0.6, delay: delay, options: UIView.AnimationOptions.curveEaseOut, animations: {
                self.mealButtons[i].alpha = 1
                self.mealButtons[i].frame.origin.y -= 20
            })
        }
    }
    
    func getWeekday(_ month: Int, _ day: Int, _ year: Int) -> Int {
        var dateComponents = DateComponents()
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.year = year
        let dateObj = Calendar.current.date(from: dateComponents)!
        return Calendar.current.component(.weekday, from: dateObj)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let month = Int(dateString.prefix(2))!
        let day = Int(dateString.prefix(4).suffix(2))!
        let year = Int(dateString.suffix(4))!
        let weekday = getWeekday(month, day, year)
        dateLabel.text = monthNames[month - 1] + String(day) + "日" + "（" + weekdays[weekday - 1] + "）"
        getMealsData() {(success) in
            if success {
                self.addButtons()
                self.fadeInButtons()
                if self.curButtonY > Double(self.scrollView.bounds.height) {
                    self.contentViewHC.constant = CGFloat(self.curButtonY + 30.0)
                } else {
                    self.contentViewHC.constant = self.scrollView.bounds.height
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if mealListDidChange {
            for btn in mealButtons {
                btn.removeFromSuperview()
            }
            mealButtons = []
            addButtons()
            for btn in mealButtons {
                btn.alpha = 1
            }
            if curButtonY > Double(scrollView.bounds.height) {
                contentViewHC.constant = CGFloat(curButtonY + 30.0)
            } else {
                contentViewHC.constant = scrollView.bounds.height
            }
            mealListDidChange = false
            selectedMealInd = 0
            selectedMealData = [:]
            if newHealthValue.isEmpty {
                MainVC!.markersDict[dateString] = nil
            } else {
                MainVC!.markersDict[dateString] = (newHealthValue["value"] as! Int)
            }
            MainVC!.calendarCollectionView.reloadData()
            newHealthValue = [:]
        }
    }
    
    @objc func mealButtonPressed(_ sender: UIButton) {
        selectedMealInd = mealButtons.firstIndex(of: sender)!
        selectedMealData = mealList[selectedMealInd]
        self.performSegue(withIdentifier: "mealsToInfo", sender: self)
    }

    @IBAction func addMealPressed(_ sender: Any) {
        selectedMealInd = mealList.count
        self.performSegue(withIdentifier: "mealsToEdit", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc1 = segue.destination as? MealInfoVC
        if let mivc = vc1 {
            mivc.mvc = self
            mivc.mealData = selectedMealData
        }
        let vc2 = segue.destination as? MealEditVC
        if let mevc = vc2 {
            mevc.mvc = self
            mevc.isNewEntry = true
            mevc.mealInd = selectedMealInd
            mevc.mealsData = mealList
            mevc.dateString = dateString
        }
    }

}
