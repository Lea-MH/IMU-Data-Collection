//
//  Utils.swift
//  IMU Data SB
//
//  Created by Lea Hering on 01/09/2022.
//

import Foundation

class Utils
{
    func getCurrentDateTime() -> String {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd"
        return dateFormatter.string(from: date) + "_" + String(hour) + "-" + String(minutes)
    }
    
    func saveData(strToSave: String, fileName: String) -> String {
        let date = self.getCurrentDateTime()
        let dateFileName = fileName + "_" + date
        let path = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask)[0].appendingPathComponent(dateFileName)
        if let stringData = strToSave.data(using: .utf8) {
            try? stringData.write(to: path)
        }
        do {
            let data = try Data(contentsOf: path)
            return path.relativeString
        } catch {
            print("error")
            return "all_data"
        }
    }
        
    func get_str(arr: Array<Int>) -> String {
        var temp = ""
        let len = arr.count - 1
        for (idx, a) in arr.enumerated(){
            if idx == 0 {  temp = "["  }
            if idx == len {  temp = temp + String(a) + "]"  }
            else {  temp = temp + String(a) + ","  }
        }
        return temp
    }
    func get_str(arr: Array<Double>) -> String {
        var temp = ""
        let len = arr.count - 1
        for (idx, a) in arr.enumerated(){
            if idx == 0 {  temp = "["  }
            if idx == len {  temp = temp + String(a) + "]"  }
            else {  temp = temp + String(a) + ","  }
        }
        return temp
    }
    func get_str(arr: Array<Array<Double>>) -> String {
        var temp = ""
        let len = arr.count - 1
        for (idx, a) in arr.enumerated(){
            if idx == 0 {  temp = "["  }
            if idx == len {  temp = temp + self.get_str(arr: a) + "]"  }
            else {  temp = temp + self.get_str(arr: a) + ","  }
        }
        return temp
    }
    func get_str(arr: Array<Array<Array<Double>>>) -> String {
        var temp = ""
        let len = arr.count - 1
        for (idx, a) in arr.enumerated(){
            if idx == 0 {  temp = "["  }
            if idx == len {  temp = temp + self.get_str(arr: a) + "]"  }
            else {  temp = temp + self.get_str(arr: a) + ","  }
        }
        return temp
    }
    
    
    func deg2rad(_ no: Double) -> Double {
        return no * .pi / 180
    }
    
    func distance(latitude1:Double, longitude1:Double, latitude2:Double, longitude2:Double) -> Double {
        let lat1 = self.deg2rad(latitude1); let lat2 = self.deg2rad(latitude2);
        let long1 = self.deg2rad(longitude1); let long2 = self.deg2rad(longitude2);
        
        // Haversine formula
        let diff_long = long2 - long1; let diff_lat = lat2 - lat1;
        let a = pow(sin(diff_lat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(diff_long / 2), 2)
        let c = 2 * asin(sqrt(a))
        // Earth radius in cm -> 6371km
        let r = 637100078.5
        
        return c * r
    }
    func distance(location1:Array<Double>, location2:Array<Double>) -> Double {
        let latitude1 = location1[0]; let latitude2 = location2[0]
        let longitude1 = location1[1]; let longitude2 = location2[1]
        return self.distance(latitude1:latitude1, longitude1:longitude1, latitude2:latitude2, longitude2:longitude2)
    }
    
    
    
    func getXElemOfList(arr: Array<Array<Double>>, x: Int) -> Array<Double> {
        var xArr:[Double] = []
        for elem in arr {
            xArr.append(elem[x])
        }
        return xArr
    }
    
    func getXYElemOfList(arr: Array<Array<Double>>, x: Int, y: Int) -> (Array<Double>, Array<Double>) {
        var xArr:[Double] = []
        var yArr:[Double] = []
        for elem in arr {
            xArr.append(elem[x])
            yArr.append(elem[y])
        }
        return (xArr,yArr)
    }
    
    /**Compare each element of array to corresponding threshold elemt . If for all arr[x] compare thres[x] return true */
    func compare_arr_to_thres_arr(arr: Array<Double>, thres_arr: Array<Double>, compare: Character) -> Bool
    {
        var temp_arr = thres_arr
        if compare == Character("<")
        {
            for a in arr
            {
                let thres = temp_arr.removeFirst()
                if !(a < thres){  return false  }
            }
            return true
        }
        if compare == Character(">")
        {
            for a in arr
            {
                let thres = temp_arr.removeFirst()
                if !(a > thres){  return false  }
            }
            return true
        }
        if compare == Character("=")
        {
            for a in arr
            {
                let thres = temp_arr.removeFirst()
                if !(a == thres){  return false  }
            }
            return true
        }
        return false

    }
    /**Compare each element of array to threshold. If for all arr[x] compare Thres return true */
    func compare_arr_to_thres(arr: Array<Double>, thres: Double, compare: Character) -> Bool
    {
        if compare == Character("<")
        {
            for a in arr
            {
                if !(abs(a) < thres){  return false  }
            }
            return true
        }
        if compare == Character(">")
        {
            for a in arr
            {
                if !(abs(a) > thres){  return false  }
            }
            return true
        }
        if compare == Character("=")
        {
            for a in arr
            {
                if !(abs(a) == thres){  return false  }
            }
            return true
        }
        return false
    }
    
    
    
    func getMedian(arr: Array<Double>) -> Double {
        let sortedArr = arr.sorted()
        let mid = Int(floor(Double(sortedArr.count / 2)))
        return sortedArr[mid]
    }
}

