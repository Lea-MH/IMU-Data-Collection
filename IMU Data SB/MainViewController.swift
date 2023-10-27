//
//  MainViewController.swift
//  IMU Data SB
//
//  Created by Lea Hering on 30/07/2022.
//

import CoreMotion
import UIKit
import MapKit
import CoreLocation
import HealthKit


class MainViewController: UIViewController, CLLocationManagerDelegate {
    // Labels for Accelerometer
    @IBOutlet private var label_acc_x: UILabel!
    @IBOutlet private var label_acc_y: UILabel!
    @IBOutlet private var label_acc_z: UILabel!
    // Labels for Gyroscope
    @IBOutlet private var label_gyro_x: UILabel!
    @IBOutlet private var label_gyro_y: UILabel!
    @IBOutlet private var label_gyro_z: UILabel!
    @IBOutlet private var label_status: UILabel!
    @IBOutlet private var label_latitude: UILabel!
    @IBOutlet private var label_longitude: UILabel!
    @IBOutlet private var data_button: UIButton!
    
    @IBOutlet var iphone_view: UIView!
    
    let ut = Utils()
    
    /// Filename where file is saved as
    var filePath = "all_data"
    var fileName = "all_data"
    
    /// Location Manager
    let locationManager = CLLocationManager()
    //    var location_str = ""
    let location_round_val = 1000.0
    var longitude_no = 0.0; var latitude_no = 0.0;
    var last_median_loc: [Double] = []
    var last_locations: [[Double]] = []
    var median_location: [Double] = []
    let last_loc_max = 5
    var all_loc_arr: [[Double]] = []
    /// Heading, Facing direction
    var magneticHeading = 0.0; var trueHeading = 0.0;
    var heading_arr: [[Double]] = []
    
    /// Motion Manager
    let motionManager = CMMotionManager()
    
    //Variables for accelerometer
    var acc_x = 0.0; var acc_y = 0.0; var acc_z = 0.0
    var user_acc_x = 0.0; var user_acc_y = 0.0; var user_acc_z = 0.0
    var pitch_angle = 0.0; var yaw_angle = 0.0; var roll_angle = 0.0
    var rotationMat: [[Double]] = []
    
    //Variables for gyroscope
    var gyro_x = 0.0; var gyro_y = 0.0; var gyro_z = 0.0;
    let round_value = 10000.0
    
    //Button clicked?
    var toggle_button = false
    
    //Array for accelerometer data & gyroscope data
    /**arr[x][0] = accelerometer data; arr[x][1] = gyroscope data; x  * timeinterval = s**/
    var data_arr: [[[Double]]] = []
    let data_max_capacity = 10000
    let data_sectioning = 20
    var last_data_section: [[Double]] = []
    var user_acc_data_arr: [[Double]] = []
    var rotMat_arr: [[[Double]]] = []
    
    var timer = Timer.init()
    let time_interval = 0.01
    
    var total_acc_diff: [[Double]] = []
    var total_gyro_diff: [[Double]] = []
    let original_status_text = "Not Started"
    let original_latitude_text = "Location: latitude"
    let original_longitude_text = "Location: longitude"
    
    var is_still_walk_run_car = [1,0,0,0]
    var last_motion_feedback = -5
    var motion_feedback: [Int] = []
    var motion_no = -5
    
    /// Activity Manager
    let activityManager = CMMotionActivityManager()
    /// Pedometer
    let pedometer = CMPedometer()
    
    /// Height, weight & biosex
    var height = 0
    var weight = 0
    var bioSex = 0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.isModalInPresentation = true
        
        motionManager.startGyroUpdates()
        motionManager.startAccelerometerUpdates()
        motionManager.startDeviceMotionUpdates()
        
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled()
        {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = kCLDistanceFilterNone
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }
    }
    
    @IBAction func buttonClicked(_ sender: UIButton)
    {
        if toggle_button == false
        {
            toggle_button = true
            data_button.setTitle("Stop Data Query", for: .normal)
            // Every time_interval (in s) get data
            self.timer = Timer.scheduledTimer(withTimeInterval: time_interval, repeats: true)
            { [self] _ in
                /// Activity Manager: Update activity in regular intervals.
                activityManager.startActivityUpdates(to: .main)
                {   (activity) in
                    guard let activity = activity else {  return  }
                    if activity.stationary {  self.is_still_walk_run_car = [1,0,0,0];  } //Still
                    else if activity.walking {  self.is_still_walk_run_car = [0,1,0,0];  } //Walking
                    else if activity.running {  self.is_still_walk_run_car = [0,0,1,0];  } //Running
                    else if activity.automotive {  self.is_still_walk_run_car = [0,0,0,1];  } //Car
                }
                /// Accelerometer Data: Get x,y,z from accelerometer (acceleration in x,y,z)
                if let acc_data = self.motionManager.accelerometerData
                {
                    self.acc_x = floor(acc_data.acceleration.x * self.round_value) / self.round_value
                    self.acc_y = floor(acc_data.acceleration.y * self.round_value) / self.round_value
                    self.acc_z = floor(acc_data.acceleration.z * self.round_value) / self.round_value
                    self.label_acc_x.text = "a_x: " + String(self.acc_x)
                    self.label_acc_y.text = "a_y: " + String(self.acc_y)
                    self.label_acc_z.text = "a_z: " + String(self.acc_z)
                }
                if let userAcceleration = self.motionManager.deviceMotion?.userAcceleration
                {
                    self.user_acc_x = userAcceleration.x
                    self.user_acc_y = userAcceleration.y
                    self.user_acc_z = userAcceleration.z
                }
                /// Get pitch, yaw & roll angle (rotation around own axis)
                if let attitude = self.motionManager.deviceMotion?.attitude
                {
                    self.pitch_angle = attitude.pitch * 180 / Double.pi;
                    self.yaw_angle = attitude.yaw * 180 / Double.pi;
                    self.roll_angle = attitude.roll * 180 / Double.pi;
                    let rmat = attitude.rotationMatrix
                    self.rotationMat = [[rmat.m11, rmat.m12, rmat.m13],
                                        [rmat.m21, rmat.m22, rmat.m23],
                                        [rmat.m31, rmat.m32, rmat.m33]]
                }
                /// Get gyroscope data (rotation rate)
                if let gyro_data = self.motionManager.gyroData
                {
                    self.gyro_x = floor( gyro_data.rotationRate.x * self.round_value) / self.round_value
                    self.gyro_y = floor( gyro_data.rotationRate.y * self.round_value) / self.round_value
                    self.gyro_z = floor( gyro_data.rotationRate.z * self.round_value) / self.round_value
                    self.label_gyro_x.text = "g_x: " + String(self.gyro_x)
                    self.label_gyro_y.text = "g_y: " + String(self.gyro_y)
                    self.label_gyro_z.text = "g_z: " + String(self.gyro_z)
                }
                let temp_arr = [[[self.acc_x, self.acc_y, self.acc_z],
                                 [self.gyro_x, self.gyro_y, self.gyro_z],
                                 [self.pitch_angle, self.roll_angle, self.yaw_angle]]]
                self.data_arr.append(contentsOf: temp_arr)
                self.all_loc_arr.append([self.latitude_no, self.longitude_no])
                self.motion_feedback.append(self.motion_no)
                self.heading_arr.append([self.trueHeading, self.magneticHeading])
                
                self.user_acc_data_arr.append(contentsOf: [[self.user_acc_x, self.user_acc_y, self.user_acc_z]])
                self.rotMat_arr.append(contentsOf: [self.rotationMat])
                
                let data_cnt = self.data_arr.count
                // Compare the average of the last # data_section to current # data_section
                if (data_cnt % self.data_sectioning) == 0
                {  self.getMotionFeedback()  }
                
                if data_cnt >= self.data_max_capacity
                {
                    let save_str = self.getSaveStr()
                    self.fileName = "data_part"
                    self.filePath = ut.saveData(strToSave: save_str, fileName: self.fileName)
                    self.data_arr.removeAll()
                    self.all_loc_arr.removeAll()
                    self.motion_feedback.removeAll()
                    self.heading_arr.removeAll()
                }
                /// Pedometer: Count steps the phone has taken. But as of right now, it seems a bit buggy.
                //                CMPedometer.authorizationStatus()
                //                if CMPedometer.isStepCountingAvailable()
                //                {
                //                    pedometer.startUpdates(from: Date()) { pedometerData, error in
                //                        guard let pedometerData = pedometerData, error == nil else { return }
                //                        DispatchQueue.main.async{  print(pedometerData.numberOfSteps.intValue)  }}
                //                }
                activityManager.stopActivityUpdates()
            }
        }
        else
        {
            data_button.setTitle("Start Data Query", for: .normal)
            self.timer.invalidate()
            self.label_acc_x.text = "a_x: "; self.label_acc_y.text = "a_y: ";
            self.label_acc_z.text = "a_z: "; self.label_gyro_x.text = "g_x: ";
            self.label_gyro_y.text = "g_y: "; self.label_gyro_z.text = "g_z: ";
            toggle_button = false
            /// Make screen return to normal
            self.label_status.text = self.original_status_text
            self.label_longitude.text = self.original_longitude_text
            self.label_latitude.text = self.original_latitude_text
            self.view.backgroundColor = UIColor.systemBackground
            
            
            var last_ac:[Double] = []; var mean_acc = [0.0, 0.0, 0.0];
            for ac in total_acc_diff
            {
                if last_ac.isEmpty {  last_ac.append(contentsOf: ac)  }
                else {  mean_acc = zip(mean_acc, last_ac).map(+); last_ac.removeAll(); last_ac.append(contentsOf: ac)  }
            }
            mean_acc = mean_acc.map{Double($0) / Double(self.total_acc_diff.count)}
            
            var last_gy:[Double] = []; var mean_gyro = [0.0, 0.0, 0.0];
            for gy in total_gyro_diff
            {
                if last_gy.isEmpty {  last_gy.append(contentsOf: gy)  }
                else {
                    mean_gyro = zip(mean_gyro, last_gy).map(+);
                    last_gy.removeAll();
                    last_gy.append(contentsOf: gy)  }
            }
            mean_gyro = mean_gyro.map{Double($0) / Double(self.total_gyro_diff.count)}
            
            let last_motion = self.motion_feedback.last ?? -5
            self.motion_feedback.removeFirst(self.data_sectioning)
            let total_elems_left = self.data_arr.count - self.motion_feedback.count
            let no_left_elems = total_elems_left % data_sectioning
            if no_left_elems < 10 // if the amount of data left is too small, then the error cannot be removed
            {
                for _ in 0...total_elems_left
                {  self.motion_feedback.append(last_motion)  }
            }
            else
            {
                if total_elems_left < data_sectioning
                {
                    let last_data_elems = self.data_arr.suffix(total_elems_left)
                    self.getMotionFeedbackLastSegment(data: last_data_elems)
                    for _ in 0...total_elems_left
                    {  self.motion_feedback.append(self.motion_no)  }
                }
                else
                {
                    for _ in 0...data_sectioning
                    {  self.motion_feedback.append(last_motion)  }
                    let last_data_elems = self.data_arr.suffix(no_left_elems)
                    self.getMotionFeedbackLastSegment(data: last_data_elems)
                    for _ in 0...no_left_elems
                    {  self.motion_feedback.append(self.motion_no)  }
                }
            }
            
            let save_str = self.getSaveStr()
            self.filePath = ut.saveData(strToSave: save_str, fileName: self.fileName)
            self.data_arr.removeAll()
            self.all_loc_arr.removeAll()
            self.motion_feedback.removeAll()
            self.heading_arr.removeAll()
            
            /// Make screen return to normal
            self.label_status.text = self.original_status_text
            self.label_longitude.text = self.original_longitude_text
            self.label_latitude.text = self.original_latitude_text
            self.view.backgroundColor = UIColor.systemBackground
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location:CLLocationCoordinate2D = manager.location!.coordinate
        self.latitude_no = location.latitude;
        self.longitude_no = location.longitude;
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.trueHeading = newHeading.trueHeading
        self.magneticHeading = newHeading.magneticHeading
    }
    
    /** All arrays: [acc[x,y,z] ,  gyro[x,y,z]]*/
    func get_movement(mean_data: Array<Array<Double>>, mean_diff: Array<Array<Double>>, all_diff: Array<Array<Array<Double>>>) -> (String, Int)
    {
        self.last_motion_feedback = motion_feedback.last ?? -5
        let thres_sit_stand = 0.85 // sit:z; stand:y
        let thres_sit_sum_xz = 1.2
        let thres_sit_xy = 0.4 // sit: roll & pitch angle (x,y);
        let thres_stand_xz = 0.45
        let thres_move_sit = 0.8
        let thres_still_gyro = 0.09
        let thres_movement_gyro = 0.4
        
        // sit: between [0.3, 0.3, 0.85] and [0.0, 0.0, 1.0] (*-1)
        // if in pocket sit maybe: [0.7, 0.0, 0.7] and [0.4, 0.0, 0.8]
        let acc_is_iphone_sit = ((abs(mean_data[0][0]) < thres_sit_xy)
                                 && (abs(mean_data[0][1]) < thres_sit_xy)
                                 && (abs(mean_data[0][2]) > thres_sit_stand)
                                 || ((abs(mean_data[0][0]) + abs(mean_data[0][2])) > thres_sit_sum_xz))
        
        // stand: between [0.45, 0.85, 0.45] and [0.0, 1.0, 0.0] (*-1)
        let acc_is_iphone_stand = ((abs(mean_data[0][0]) < thres_stand_xz)
                                   && (abs(mean_data[0][1]) > thres_sit_stand)
                                   && (abs(mean_data[0][2]) < thres_stand_xz))
        
        // movement from stand to sit -> walking is impossible because close to sit
        let gyro_is_iphone_sit = ut.compare_arr_to_thres(arr: mean_data[1], thres: thres_still_gyro, compare: "<")
        let gyro_is_iphone_stand = ut.compare_arr_to_thres(arr: mean_data[1], thres: thres_movement_gyro, compare: "<")
        let gyro_is_iphone_move = ut.compare_arr_to_thres(arr: mean_data[1], thres: thres_movement_gyro, compare: ">")
        
        let no_acc = all_diff[0][0].count
        let second_acc = all_diff[0][1]
        let last_acc = all_diff[0][no_acc-1]
        
        let max_acc_diff = (zip(second_acc.map(fabs), last_acc.map(fabs)).map(-)).map(fabs)
        let walking_possible1 = max_acc_diff[1] < 0.4 && max_acc_diff[2] < 0.4
        let walking_possible2 = ((abs(mean_data[0][0]) < 0.2) && ((abs(mean_data[0][1]) + abs(mean_data[0][2])) > 1.5))
        
        // movement from stand to sit -> walking is impossible because close to sit
        let walking_impossible = (max_acc_diff[1] > 0.6 && max_acc_diff[2] > 0.6) && (abs(mean_data[0][2]) > thres_move_sit)
        
        let walking_possible = (walking_possible1 || walking_possible2) && (walking_impossible == false)
        
        // Get information from apple motion detection
        let is_motion_still = (self.is_still_walk_run_car == [1,0,0,0]);
        let is_motion_walk = (self.is_still_walk_run_car == [0,1,0,0]);
        let is_motion_run = (self.is_still_walk_run_car == [0,0,1,0]);
        let is_motion_strongmove = (self.is_still_walk_run_car == [0,0,0,1]);
        
        // Use differences within time intervall to get movement
        let diff_gyro = mean_diff[1]
        
        var return_str = ""
        // if differs = -1; all_sit = 1; all_stand = 2; all_walk = 3; move_sit = 4; all_move = 5;
        var return_move_no = -1
        
        if gyro_is_iphone_move && is_motion_strongmove //strong movement detected from motiondetection (car) & gyro
        {
            return_move_no = 5
            return_str =    ut.get_str(arr: is_still_walk_run_car) + "Acc : " +  ut.get_str(arr: mean_data[0])
            + "; Gyro move " + ut.get_str(arr: diff_gyro ) + "; "
        }
        else if is_motion_still // no motion detected from motiondetection
        {
            return_str = "Motion still; "
            if acc_is_iphone_sit
            {
                return_str += "Acc sit; "
                return_move_no = 1 //sit
                if gyro_is_iphone_sit {  return_str += "Gyro sit; "  }
                else if gyro_is_iphone_stand {  return_str += "Gyro stand; "  }
                else {  return_str += "Gyro movement; "; return_move_no = 4 /*stand <-> sit*/  }
            }
            else if acc_is_iphone_stand
            {
                return_str += "Acc stand; "
                return_move_no = 2 //stand
                if gyro_is_iphone_sit {  return_str += "Gyro still; "  }
                else if gyro_is_iphone_stand  {  return_str += "Gyro stand; "  }
                else {  return_str += "Gyro move; "; return_move_no = 3 /*probably walking*/  }
            }
            else
            {
                
                if walking_possible && !gyro_is_iphone_sit
                {
                    return_move_no = 3
                    return_str += "Acc walk "
                }
                else if (abs(mean_data[0][2]) > 0.5) {  return_move_no = 4  }
                else {  return_move_no = -1  }
                return_str += "Acc " +  ut.get_str(arr: mean_data[0]) + "; "
                if gyro_is_iphone_sit {  return_str += "Gyro still; "  }
                else if gyro_is_iphone_stand {  return_str += "Gyro stand; "  }
                else {  return_str += "Gyro move; "  }
            }
        }
        else if walking_possible && (is_motion_walk || is_motion_run)
        {
            return_str = "Motion walk; "
            return_move_no = 3 //walk
            if gyro_is_iphone_sit //no movement detected from gyro
            {
                return_str += "Gyro no movement; ";
                if acc_is_iphone_sit {  return_move_no = 1 /*no movement, so sitting*/  }
                else if acc_is_iphone_stand {  return_move_no = 2 /*no movement, so standing*/  }
                else {  return_move_no = -1 /*indecisive*/  }
            }
            else //movement detected from gyro
            {
                if gyro_is_iphone_stand {  return_str += "Gyro stand; "  }
                else {  return_str += "Gyro movement; "  }
                if acc_is_iphone_sit // if close to sit -> movement from stand to sit <->
                {
                    return_str += "Acc sit; "
                    return_move_no = 4 /*stand <-> sit*/
                }
                else if acc_is_iphone_stand {  return_str += "Acc stand; "  }
                else // neither sit nor stand
                {
                    return_str += "Acc " +  ut.get_str(arr: mean_data[0]) + "; "
                    if (mean_data[0][2] > 0.5 && mean_data[0][2] < -0.5) {  return_move_no = 4  }
                    else {  return_move_no = 4 /*stand <-> sit*/  }
                }
            }
        }
        else if  (is_motion_walk || is_motion_run) //walking_impossible && (is_motion_walk || is_motion_run)
        {
            return_str = "Walking impos. Motion walk; Acc sit<->stand " + ut.get_str(arr: mean_data[0]) + " ";
            return_move_no = 4
            if gyro_is_iphone_sit
            {
                return_str += "Gyro no movement; ";
                return_move_no = 1 //no movement, so sitting
            }
        }
        else
        {
            return_str += "Indecisive "
            return_move_no = -1 //indecisive
        }
        if self.last_motion_feedback == 3 && return_move_no == -1
        {
            return_str = "last-walk "
            return_move_no = 3
        }
        self.last_motion_feedback = return_move_no
        return_str += String(return_move_no)
        return (return_str, return_move_no)
    }
    
    func getMotionFeedback()
    {
        var move_str = ""; var move_no = -5
        // last_x = [[[acc_x, acc_y, acc_z], [gyro_x, gyro_y, gyro_z], [pitch_angle, roll_angle, yaw_angle]]]
        let last_x = self.data_arr.suffix(self.data_sectioning)
        var mean_acc = [0.0, 0.0, 0.0]; var mean_gyro = [0.0, 0.0, 0.0]
        var mean_acc_diff = [0.0, 0.0, 0.0]; var mean_gyro_diff = [0.0, 0.0, 0.0]
        var last_acc:[Double] = []; var last_gyro:[Double] = []
        var acc_diff:[[Double]] = []; var gyro_diff:[[Double]] = []
        var last_diff_a  = [0.0, 0.0, 0.0]; var last_diff_g  = [0.0, 0.0, 0.0];
        
        
        for elem in last_x
        {   // elem[0] = [acc_x, acc_y, acc_z]
            // elem[1] = [gyro_x, gyro_y, gyro_z]
            // elem[2] = [pitch_angle, roll_angle, yaw_angle]
            
            if last_acc.isEmpty     // if not initialised, set last_acc as first acceleration of last_x
            {  last_acc = elem[0].map(fabs)  }  // last_acc = abs([acc_x, acc_y, acc_z])
            else
            {   // diff = abs(previous acceleration) - abs(current acceleration)
                // Maybe it would be better to get the actual difference: abs(previous_acc - current_acc)
                let diff = (zip(last_acc, elem[0].map(fabs)).map(-)).map(fabs)
                last_diff_a = diff.map{floor(Double($0) * self.round_value) / self.round_value}     // floor value
                acc_diff.append(last_diff_a)
                last_acc = elem[0].map(fabs)    // set last_acc for next iteration
            }
            
            if last_gyro.isEmpty     // if not initialised, set last_gyro as first gyroscope data point of last_x
            {  last_gyro = elem[1].map(fabs)  }
            else
            {   //diff = abs(previous gyro) - abs(current gyro)
                // Maybe it would be better to get the actual difference: abs(previous_gyro - current_gyro)
                let diff = (zip(last_gyro, elem[1].map(fabs)).map(-)).map(fabs)
                last_diff_g = diff.map{floor(Double($0) * self.round_value) / self.round_value}     // floor value
                gyro_diff.append(last_diff_g)
                last_gyro = elem[1].map(fabs)    // set last_gyro for next iteration
            }
            
            // mean_..._diff = sum ( last_diff_xxx )
            mean_acc_diff = zip(mean_acc_diff, last_diff_a).map(+)
            mean_gyro_diff = zip(mean_gyro_diff, last_diff_g).map(+)
            // mean_... = sum ( last_xxx )
            mean_acc = zip(mean_acc, last_acc).map(+)
            mean_gyro = zip(mean_gyro, last_gyro).map(+)
        }
        
        // Calculate the mean by dividing the sum by # of data points
        mean_acc = (mean_acc.map{Double($0) / Double(self.data_sectioning)}).map{floor(Double($0) * self.round_value) / self.round_value}
        mean_gyro = (mean_gyro.map{Double($0) / Double(self.data_sectioning)}).map{floor(Double($0) * self.round_value) / self.round_value}
        mean_acc_diff = (mean_acc_diff.map{Double($0) / Double(self.data_sectioning)}).map{floor(Double($0) * self.round_value) / self.round_value}
        mean_gyro_diff = (mean_gyro_diff.map{Double($0) / Double(self.data_sectioning)}).map{floor(Double($0) * self.round_value) / self.round_value}
        self.total_acc_diff.append(mean_acc_diff)
        self.total_gyro_diff.append(mean_gyro_diff)
        let current_data_section = [mean_acc, mean_gyro]
        // get_movement calculates the move_no and move_str from the provided data
        (move_str, move_no) = self.get_movement(mean_data: current_data_section, mean_diff: [mean_acc_diff, mean_gyro_diff], all_diff: [acc_diff, gyro_diff])
        self.motion_no = move_no
        switch move_no {    // depending on the move_no change the label on the display and the background colour of the app
            // all_inactive = 0; all_sit = 1; all_stand = 2; all_walk = 3; move_sit = 4; all_move = 5;
        case 0: //all_flat
            //              self.view.backgroundColor = UIColor.lightGray; self.label_status.text = "Still & flat surface"
            self.view.backgroundColor = UIColor.green
            self.label_status.text = "Sitting"
        case 1: //all_sit
            self.view.backgroundColor = UIColor.green
            self.label_status.text = "Sitting"
        case 2: // all_stand
            self.view.backgroundColor = UIColor.cyan
            self.label_status.text = "Standing"
        case 3: // all_walk
            self.view.backgroundColor = UIColor.yellow
            self.label_status.text = "Walking"
        case 4: // move_sit
            self.view.backgroundColor = UIColor.orange
            self.label_status.text = "Move sit<->stand"
        case 5: // all_move
            self.view.backgroundColor = UIColor.red
            self.label_status.text = "Strong Movement"
        default:
            self.view.backgroundColor = UIColor.purple
            self.label_status.text = "Indecisive"
        }
        //        self.label_latitude.text = String(self.latitude_no)
        //        self.label_longitude.text = String(self.longitude_no)
        self.label_latitude.text = "tH: " + String(self.trueHeading)
        self.label_longitude.text = "mH: " + String(self.magneticHeading)
        self.last_locations.append([self.latitude_no, self.longitude_no])
        if self.last_locations.count >= self.last_loc_max
        {
            let (last_lats, last_longs) = ut.getXYElemOfList(arr: last_locations, x: 0, y:1)
            let medianLat = ut.getMedian(arr: last_lats)
            let medianLong = ut.getMedian(arr: last_longs)
            self.median_location = [medianLat, medianLong]
            self.last_locations.removeAll()
        }
        //      if !self.last_median_loc.isEmpty { }
        self.last_median_loc = self.median_location
        self.last_data_section = current_data_section
        if move_str != "" {  print(move_str)  }
    }
    
    
    func getMotionFeedbackLastSegment(data: ArraySlice<Array<Array<Double>>>)
    {
        var move_str = ""; var move_no = -5
        var mean_acc = [0.0, 0.0, 0.0]; var mean_gyro = [0.0, 0.0, 0.0]
        var mean_acc_diff = [0.0, 0.0, 0.0]; var mean_gyro_diff = [0.0, 0.0, 0.0]
        var last_acc:[Double] = []; var last_gyro:[Double] = []
        var acc_diff:[[Double]] = []; var gyro_diff:[[Double]] = []
        var last_diff_a  = [0.0, 0.0, 0.0]; var last_diff_g  = [0.0, 0.0, 0.0];
        
        for elem in data
        {
            if last_acc.isEmpty {  last_acc = elem[0].map(fabs)  }
            else
            {
                let diff = (zip(last_acc, elem[0].map(fabs)).map(-)).map(fabs)
                last_diff_a = diff.map{floor(Double($0) * self.round_value) / self.round_value}
                acc_diff.append(last_diff_a)
                last_acc = elem[0].map(fabs)
            }
            if last_gyro.isEmpty {  last_gyro = elem[1].map(fabs)  }
            else
            {
                let diff = (zip(last_gyro, elem[1].map(fabs)).map(-)).map(fabs)
                last_diff_g = diff.map{floor(Double($0) * self.round_value) / self.round_value}
                gyro_diff.append(last_diff_g)
                last_gyro = elem[1].map(fabs)
            }
            mean_acc_diff = zip(mean_acc_diff, last_diff_a).map(+)
            mean_gyro_diff = zip(mean_gyro_diff, last_diff_g).map(+)
            mean_acc = zip(mean_acc, last_acc).map(+)
            mean_gyro = zip(mean_gyro, last_gyro).map(+)
        }
        mean_acc = (mean_acc.map{Double($0) / Double(self.data_sectioning)}).map{floor(Double($0) * self.round_value) / self.round_value}
        mean_gyro = (mean_gyro.map{Double($0) / Double(self.data_sectioning)}).map{floor(Double($0) * self.round_value) / self.round_value}
        mean_acc_diff = (mean_acc_diff.map{Double($0) / Double(self.data_sectioning)}).map{floor(Double($0) * self.round_value) / self.round_value}
        mean_gyro_diff = (mean_gyro_diff.map{Double($0) / Double(self.data_sectioning)}).map{floor(Double($0) * self.round_value) / self.round_value}
        let current_data_section = [mean_acc, mean_gyro]
        (move_str, move_no) = self.get_movement(mean_data: current_data_section, mean_diff: [mean_acc_diff, mean_gyro_diff], all_diff: [acc_diff, gyro_diff])
        self.motion_no = move_no
        if move_str != "" {  print(move_str)  }
    }
    
    
    func getSaveStr() -> String
    {
        let str_data_arr = "# [[[accelerometer], [gyroscope], [pitch,roll,yaw]]]\n" +  "data_arr = " + ut.get_str(arr: self.data_arr)  + "\n\n"
        //        let str_all_loc_arr = "all_loc_arr = " + ut.get_str(arr: self.all_loc_arr)  + "\n\n"
        //        let str_user_acc = "user_acc = " + ut.get_str(arr: self.user_acc_data_arr)  + "\n\n"
        //        let str_rot_mat = "rot_mat = " + ut.get_str(arr: self.rotMat_arr)  + "\n\n"
        let str_motion_info = "# -1:indesicive; 1:sit; 2:stand; 3:walk; 4:sit<->stand; 5:move;\n"
        let str_motion_feedback = "motion_feedback = " + ut.get_str(arr: self.motion_feedback) + "\n\n"
        let str_heading = "# [true-heading, magnetic-heading]\n" + "heading = " + ut.get_str(arr: self.heading_arr) + "\n\n"
        let str_data_points = "# data points per second\n" + "data_points = " + String(1 / self.time_interval) + " # per second"
        //        let save_str = str_data_arr + str_all_loc_arr + str_user_acc + str_rot_mat + "data_section = " + String(self.data_sectioning) + "\n\n" + str_motion_info + str_motion_feedback + str_heading + str_data_points
        let save_str = str_data_arr + "data_section = " + String(self.data_sectioning) + "\n\n" + str_motion_info + str_motion_feedback + str_heading + str_data_points
        return save_str
    }

    func setHeight(height: Int)
    {
        self.height = height
    }
}
