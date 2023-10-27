# IMU-Data-Collection
 
### Requirements: 

Xcode (Apple's IDE for macOS) and iPhone

---

### About

This repository allows to create a simple IMU application for iPhone that allows to estimate labels for short sequences of human motion within indoor scenes. For this, the iPhone is placed in the right front pocket. To start the recording press the start button, to stop the recording press the stop button.

---

### Motion Labels

Here, the motion labels "sitting", "standing" and "walking" can be distinguished. To that end, the parameters gravitaional acceleration, gyroscope, attitude, heading angle and motion activity are retrieved frequently. 

---

### Retrieve Collected Data

The collected data including the estimated motion labels are saved within the application (on the deviece). To retrieve these: 

1. Connect the iPhone to your computer
2. Open Xcode
3. In the menu bar choose "Window"  > "Devices and Simulators"
4. Select your device on the left side
5. Select the application from the list of "installed apps" (center)
6. Either view the content by "Show Container" or download the content via "Download Container"
