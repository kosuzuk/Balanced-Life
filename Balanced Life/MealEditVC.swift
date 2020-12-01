//
//  MealEditVC.swift
//  Balanced Life
//
//  Created by Koso Suzuki on 8/16/20.
//  Copyright © 2020 Koso Suzuki. All rights reserved.
//

import UIKit
import FirebaseFirestore

class MealEditVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewPlusLabel: UILabel!
    @IBOutlet weak var removeImageButton: UIButton!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet var descriptionToolBar: UIToolbar!
    @IBOutlet weak var nutrientsTableView: UITableView!
    @IBOutlet weak var deleteButton: UIButton!
    var mvc: MealsVC? = nil
    var nutrientNameList = ["carbs", "protein", "veggies", "fruits", "sweets", "sodium"]
    var nutrientNameListJP = ["炭水化物", "タンパク質", "野菜", "フルーツ", "スイーツ", "塩分"]
    var isNewEntry = false
    var mealInd = 0
    var mealsData: [[String: Any]] = []
    var imageData: UIImage? = nil
    var dateString = ""
    var imageRemoved = false
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        6
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = nutrientsTableView.dequeueReusableCell(withIdentifier: "foodCell", for: indexPath) as! EditNutrientsTableViewCell
        cell.foodNameLabel.text = nutrientNameListJP[indexPath.row]
        if !isNewEntry {
            cell.meterSlider.setValue(mealsData[mealInd][nutrientNameList[indexPath.row]] as! Float, animated: true)
        }
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nutrientsTableView.delegate = self
        nutrientsTableView.dataSource = self
        titleField.delegate = self
        descriptionTextView.delegate = self
        descriptionTextView.layer.borderWidth = 1
        if !isNewEntry {
            let mealData = mealsData[mealInd]
            titleField.text = (mealData["title"] as! String)
            if imageData != nil {
                imageView.image = imageData
                imageViewPlusLabel.isHidden = true
            } else {
                removeImageButton.isHidden = true
            }
            descriptionTextView.text = (mealData["description"] as! String)
        } else {
            removeImageButton.isHidden = true
            deleteButton.isHidden = true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    @IBAction func descriptionFieldDonePressed(_ sender: Any) {
        view.endEditing(true)
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textView.inputAccessoryView = descriptionToolBar
        return true
    }
    
    @IBAction func imageViewPressed(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let newImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.dismiss(animated: true, completion: {
                self.imageView.image = newImage
                self.removeImageButton.isHidden = false
                self.imageViewPlusLabel.isHidden = true
            })
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func removeImagePressed(sender: Any) {
        imageView.image = nil
        removeImageButton.isHidden = true
        imageViewPlusLabel.isHidden = false
        imageRemoved = true
    }
    
    func getImageState() -> String {
        if isNewEntry {
            if imageView.image != nil {
                return "added"
            }
        } else {
            let imageKey = mealsData[mealInd]["imageKey"] as! String
            if imageKey == "" && imageView.image != nil {
                return "added"
            } else if imageRemoved {
                if imageView.image != nil {
                    return "updated"
                } else {
                    return "deleted"
                }
            }
        }
        return ""
    }
    
    func getHealthinessValue(_ newMealData: [String: Any]) -> Float {
        var healthinessValue = Float(0.5)
        if (newMealData["carbs"] as! Float) < 0.2 || (newMealData["carbs"] as! Float) > 0.7 {
            healthinessValue -= 0.2
        } else {
            healthinessValue += 0.1
        }
        if (newMealData["protein"] as! Float) < 0.1 || (newMealData["protein"] as! Float) > 0.8 {
            healthinessValue -= 0.2
        } else {
            healthinessValue += 0.1
        }
        if newMealData["veggies"] as! Float > 0.6 {
            healthinessValue += 0.12
        } else {
            healthinessValue += (newMealData["veggies"] as! Float) * 0.2
        }
        if (newMealData["fruits"] as! Float) > 0.8 {
            healthinessValue -= 0.12
        } else {
            healthinessValue += (newMealData["fruits"] as! Float) * 0.1
        }
        healthinessValue -= (newMealData["sweets"] as! Float) * 0.23
        healthinessValue -= (newMealData["sodium"] as! Float) * 0.16
        if healthinessValue < 0 {
            healthinessValue = 0
        }
        if healthinessValue > 10 {
            healthinessValue = 10
        }
        return healthinessValue
    }
    
    func getMealsHealthScore() -> Int {
        var sum = Float(0.0)
        for meal in mealsData {
            sum += meal["healthiness"] as! Float
        }
        var average = sum * 10 / Float(mealsData.count)
        if average == 10 {
            average = 8
        }
        return Int(average.rounded(.down)) / 2
    }
    
    func exitPage() {
        loadingIcon.stopAnimating()
        endNoInput()
        self.navigationController?.popViewController(animated: true)
        if !isNewEntry {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func savePressed(_ sender: Any) {
        view.addSubview(formatLoadingIcon(loadingIcon))
        loadingIcon.startAnimating()
        startNoInput()
        var originalImageKey: String?
        if !isNewEntry {
            originalImageKey = mealsData[mealInd]["imageKey"] as? String
        }
        let imageData = imageView.image?.jpegData(compressionQuality: 1)
        let imageState = getImageState()
        var imageKey = ""
        //manage fb image data
        if imageState == "added" {
            let newImageKey = NSUUID().uuidString
            storage.child(newImageKey).putData(imageData!, metadata: nil) {(metadata, error) in
                self.exitPage()
            }
            imageKey = newImageKey
        } else if imageState == "updated" {
            storage.child(originalImageKey!).putData(imageData!, metadata: nil) {(metadata, error) in
                self.exitPage()
            }
            imageKey = originalImageKey!
        } else if imageState == "deleted" {
            storage.child(originalImageKey!).delete(completion: {
                (error) in
                self.exitPage()
            })
        } else {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {_ in
                self.exitPage()
            }
        }
        //bundle up data in page
        var newMealData: [String: Any] = ["title": titleField.text!, "description": descriptionTextView.text!, "imageKey": imageKey]
        for i in 0..<nutrientNameList.count {
            let nutrientCell = nutrientsTableView.cellForRow(at: IndexPath(row: i, section: 0)) as! EditNutrientsTableViewCell
            newMealData[nutrientNameList[i]] = nutrientCell.meterSlider.value
        }
        newMealData["healthiness"] = getHealthinessValue(newMealData)
        //combine new data with other meal data
        if isNewEntry {
            mealsData.insert(newMealData, at: mealInd)
        } else {
            mealsData[mealInd] = newMealData
        }
        let healthScore = getMealsHealthScore()
        db.collection("meals").document(dateString).setData(["data": mealsData])
        db.collection("mealMarkers").document("*").setData(["data": [dateString: healthScore]], merge: true)
        mvc!.mealList = mealsData
        mvc!.mealListDidChange = true
        mvc!.newHealthValue = ["day": dateString, "value": healthScore]
    }
    
    func handleDeletePressed(_ _: UIAlertAction) {
        startNoInput()
        let imageKey = mealsData[mealInd]["imageKey"] as! String
        mealsData.remove(at: mealInd)
        if mealsData.count == 0 {
            db.collection("meals").document(dateString).delete()
            db.collection("mealMarkers").document("*").setData(["data": [dateString: FieldValue.delete()]], merge: true)
            mvc!.mealList = []
            mvc!.mealListDidChange = true
            mvc!.newHealthValue = [:]
        } else {
            let newHealthScore = getMealsHealthScore()
            db.collection("meals").document(dateString).setData(["data": mealsData])
            db.collection("mealMarkers").document("*").setData(["data": [dateString: newHealthScore]], merge: true)
            mvc!.mealList = mealsData
            mvc!.mealListDidChange = true
            mvc!.newHealthValue = ["day": dateString, "value": newHealthScore]
        }
        
        if imageKey != "" {
            storage.child(imageKey).delete(completion: {
                (Error) in
                self.exitPage()
            })
        } else {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {_ in
                self.exitPage()
            }
        }
    }
    
    @IBAction func deletePressed(_ sender: Any) {
        let alertController = UIAlertController(title: "確認", message: "本当に削除しますか？", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "はい", style: .destructive, handler: handleDeletePressed)
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
