//
//  MainVC.swift
//  Balanced Life
//
//  Created by Koso Suzuki on 8/15/20.
//  Copyright © 2020 Koso Suzuki. All rights reserved.
//

import UIKit
import FirebaseFirestore

class MainVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate {
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var calendarCollectionView: UICollectionView!
    @IBOutlet weak var calendarPrevButton: UIButton!
    @IBOutlet weak var calendarNextButton: UIButton!
    let calendar = Calendar.current
    let dateObjToday = Date()
    var dateStringToday = ""
    var curMonth = 0
    var curYear = 0
    var calendarMonth = 0
    var calendarYear = 0
    var calendarNumDays = 0
    var calendarFirstDayOffset = 0
    var markersDict: [String: Int] = [:]
    let markers = ["X", "triangle", "circle", "double_circle", "star"]
    var datePressed = ""
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if calendarNumDays + calendarFirstDayOffset < 36 {
            return 35
        } else {
            return 42
        }
    }
    
    func getDateString(_ month: Int, _ day: Int, _ year: Int) -> String {
        var m = String(month)
        if m.count == 1 {
            m = "0" + m
        }
        var d = String(day)
        if d.count == 1 {
            d = "0" + d
        }
        let y = String(year)
        
        return m + d + y
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CalendarCell", for: indexPath) as! CalendarCell
        let i = indexPath.row
        let date = i + 1 - calendarFirstDayOffset
        if date >= 1 && date <= calendarNumDays {
            let dateString = getDateString(calendarMonth, date, calendarYear)
            if dateString == dateStringToday {
                cell.backgroundColor = healthyGreen
            } else if i % 7 == 0 || i % 7 == 6 {
                cell.backgroundColor = UIColor(red: 210/255.0, green: 210/255.0, blue: 210/255.0, alpha: 1)
            } else {
                cell.backgroundColor = .white
            }
            cell.layer.borderWidth = 1
            cell.dateLabel.text = String(date)
            cell.dateLabel.isHidden = false
            if let markerValue = markersDict[dateString] {
                cell.markerImageView.image = UIImage(named: "mealMarker_" + markers[markerValue])
            } else {
                cell.markerImageView.image = nil
            }
        } else {
            cell.backgroundColor = UIColor(red: 100/255.0, green: 100/255.0, blue: 100/255.0, alpha: 1)
            cell.layer.borderWidth = 0
            cell.dateLabel.isHidden = true
            cell.markerImageView.image = nil
        }
        return cell
    }
    
    func getCalendarInfo(_ date: Date) {
        let dateComps = calendar.dateComponents([.timeZone, .year, .month, .day, .weekday], from: date)
        calendarMonth = dateComps.month!
        calendarYear = dateComps.year!
        calendarNumDays = calendar.range(of: .day, in: .month, for: dateObjToday)!.count
        calendarFirstDayOffset = ((dateComps.weekday! - dateComps.day! + 1) % 7 + 6) % 7
    }
    
    func setMealMarkers() {
        db.collection("mealMarkers").document("*").getDocument(completion: {(QuerySnapshot, Error) in
            if Error != nil {
                print(Error!)
                return
            }
            let data = QuerySnapshot!.data()
            if data == nil {
                return
            }
            self.markersDict = data!["data"] as! [String: Int]
            self.calendarCollectionView.reloadData()
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        calendarCollectionView.dataSource = self
        calendarCollectionView.delegate = self
        getCalendarInfo(dateObjToday)
        curMonth = calendarMonth
        curYear = calendarYear
        let day = calendar.dateComponents([.day], from: dateObjToday).day!
        dateStringToday = getDateString(calendarMonth, day, calendarYear)
        monthLabel.text = monthNames[calendarMonth - 1]
        calendarNextButton.isHidden = true
        setMealMarkers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        let cellSize = floor(calendarCollectionView.bounds.width / 7)
        layout.itemSize = CGSize(width: cellSize, height: cellSize)
        calendarCollectionView.collectionViewLayout = layout
    }
    
    @IBAction func calendarPressed(_ sender: UIGestureRecognizer) {
        let indexPath = calendarCollectionView.indexPathForItem(at: sender.location(in: calendarCollectionView))
        if indexPath == nil {
            return
        }
        let ind = indexPath!.row
        if ind < calendarFirstDayOffset || ind >= calendarFirstDayOffset + calendarNumDays {
            return
        }
        var monthString = String(calendarMonth)
        if monthString.count == 1 {
            monthString = "0" + monthString
        }
        var dayString = String(ind - calendarFirstDayOffset + 1)
        if dayString.count == 1 {
            dayString = "0" + dayString
        }
        let yearString = String(calendarYear)
        datePressed = monthString + dayString + yearString
        self.performSegue(withIdentifier: "calendarToMeals", sender: self)
    }
    
    @IBAction func calendarPrevPressed(_ sender: Any) {
        if calendarMonth == 1 {
            calendarMonth = 12
            calendarYear -= 1
        } else {
            calendarMonth -= 1
        }
        let yearDiff = calendarYear - curYear
        let monthDiff = (calendarMonth - curMonth) + yearDiff * 12
        let dateObj = calendar.date(byAdding: .month, value: monthDiff, to: dateObjToday)!
        getCalendarInfo(dateObj)
        var newMonth = curMonth + monthDiff % 12
        if newMonth < 1 {
            newMonth = newMonth % 12 + 12
        } else if newMonth > 12 {
            newMonth = newMonth % 12
        }
        monthLabel.text = monthNames[newMonth - 1]
        calendarCollectionView.reloadData()
        calendarNextButton.isHidden = false
    }
    
    @IBAction func calendarNextPressed(_ sender: Any) {
        if calendarMonth == 12 {
            calendarMonth = 1
            calendarYear += 1
        } else {
            calendarMonth += 1
        }
        let yearDiff = calendarYear - curYear
        let monthDiff = (calendarMonth - curMonth) + yearDiff * 12
        let dateObj = calendar.date(byAdding: .month, value: monthDiff, to: dateObjToday)!
        getCalendarInfo(dateObj)
        var newMonth = curMonth + monthDiff % 12
        if newMonth < 1 {
            newMonth = newMonth % 12 + 12
        } else if newMonth > 12 {
            newMonth = newMonth % 12
        }
        monthLabel.text = monthNames[newMonth - 1]
        calendarCollectionView.reloadData()
        if calendarMonth == curMonth && calendarYear == curYear {
            calendarNextButton.isHidden = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as? MealsVC
        if let mvc = vc {
            mvc.dateString = datePressed
            mvc.MainVC = self
        }
        
    }
}

