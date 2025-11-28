/* Arduino component of program to communicate with matlab to implement a burglar alarm system
 Title: lastversionburglaralarmarduino.ino
 Authors:  Max Nyman, Benedict Colin Yuwono, Lojain Mahfouz, Gazl Talib
 Date written:  05/05/2025    */


class actuators {  //actuator class
public:
  int pinNumber;
public:
  actuators(int pin) {
    pinNumber = pin;
    pinMode(pinNumber, OUTPUT);  //set as output
    deactivate();                //ensure actuator begins deactivated
  }


  void activate() {
    digitalWrite(pinNumber, HIGH);  // activates
  }


  void deactivate() {
    digitalWrite(pinNumber, LOW);  // deactivates
  }
};


class alarm : public actuators {  // alarm class inherits from actuator class so tone can be used instead of digitalWrite
public:


  alarm(int pin)
    : actuators(pin) {}


  void activate() {
    tone(pinNumber, 1000);  //buzzer rings
  }


  void deactivate() {
    noTone(pinNumber);  //buzzer does not ring
  }
};


class sensors {  //sensor class
public:
  int pinNumber;
  bool prevState;
  sensors(int pin) {
    pinNumber = pin;
    pinMode(pinNumber, INPUT);           //sets as input
    prevState = digitalRead(pinNumber);  //reads initial state to later detect state change
  }


  bool test() {
    bool currentState = digitalRead(pinNumber);                   // reads current state
    bool activated = (prevState == HIGH && currentState == LOW);  //ensures sensor activation if sensor goes from high to low
    prevState = currentState;                                     // resets prevState for future checks
    return activated;                                             // returns high if activated, low if not
  }
};


class timer {  // timer class
public:
  int waitTime;


  timer() {
    waitTime = 20;  //sets default wait time
  }


  void wait() {
    delay((waitTime - 10) * 1000);  //delays for 10 seconds less than entire wait time - a 10 second delay comes after it in the program
  }
};


class pir : public sensors {  // pir class inherits from sensors to ensure test is returned high if pir signal is high
public:
  pir(int pin)
    : sensors(pin) {
    pinMode(pinNumber, INPUT);  // set as input
  }


  bool test() {
    return digitalRead(pinNumber);  // return high if sensor is high, low otherwise
  }
};




class push : public sensors {  // push button class inherits from sensors so it can be set as input pull up, and return high if high, low otherwise
public:
  push(int pin)
    : sensors(pin) {
    pinMode(pinNumber, INPUT_PULLUP);  // set as input pull up
  }


  bool test() {
    return digitalRead(pinNumber);  // return high if sensor is high, low otherwise
  }
};


actuators redLight(7);
actuators yellowLight(9);
actuators greenLight(13);
actuators solenoid(2);
alarm buzzer(11);
pir pirSensor(12);
sensors magnetSensorDoor(8);
sensors magnetSensorWindow(5);
push pushButton(6);
timer delayTimer;  //initialise system components and set pin numbers




class keypad {  //keypad class
private:
  int correctCode;
  int facecheck = 0;
public:
  keypad() {
    correctCode = 1234;  //sets default pin to 1234
  }


  void codeCheck() {
    while (Serial.available() < 1) {
      delay(1);
    }                           //wait until a signal is sent ( if 0 is sent, face was not recognised)
    facecheck = Serial.read();  //reads from matlab whether face recognition was successful
    if (facecheck == 0) {       //enters section to ask for pin if face was not recognised
      while (true) {
        int enteredCode = 0;
        int counter = 0;


        while (enteredCode != correctCode) {  //while correct code has not yet been entered
          if (Serial.available() >= 2) {      //once entered pin has been sent from matlab
            int lowByte = Serial.read();
            int highByte = Serial.read();
            enteredCode = (highByte << 8) | lowByte;  //entered code set to pin entered in matlab


            if (enteredCode != correctCode) {  //if entered code is incorrect


              counter++;           //counter to track incorrect pin entries
              if (counter == 3) {  //if pin is entered incorrect 3 times
                Serial.write(2);   //inform matlab
                buzzer.activate();
                redLight.activate();
                greenLight.deactivate();  //set of alarm
                counter = 0;              //reset counter
                while (pushButton.test() == true) {
                  delay(1);
                }  //wait for push button to be pressed to deactivate alarm
                buzzer.deactivate();
                redLight.deactivate();
                greenLight.activate();  //deactivate alarm
                Serial.write(11);       //inform matlab system has been deactivated
                break;                  //return to pin entry stage with counter reset
              } else {
                Serial.write(0);  //inform matlab if pin is wrong but entry limit has not yet been reached
              }
            } else {            //if pin is correct
              Serial.write(1);  //inform matlab of correct entry
              buzzer.deactivate();
              redLight.deactivate();
              greenLight.activate();  //ensure alarm is not activated
              return;                 //continue with program
            }
          }
        }
      }
    } else {            // if face was recognised
      Serial.write(1);  //inform matlab
      buzzer.deactivate();
      redLight.deactivate();
      greenLight.activate();  //ensure alarm is not activatede
      return;                 //continue with program
    }
  }


  void changePIN(int newPIN) {
    correctCode = newPIN;  //function changes correct code to new pin entered in matlab
  }
};


keypad pad;  //initialise keypad


class session {  // whole system class
private:
  int systemstatus;


public:


  void systemGo() {
    systemstatus = 0;       //initialise system status as 0
    greenLight.activate();  // turn ono green LED
    if (Serial.available() > 0) {
      systemstatus = Serial.read();  //set new system status sent from matlab
    }
    if (systemstatus == 2) {  //user pressed 2 to log out in matlab
      pad.codeCheck();        //return to log in stage
      return;
    }


    if (systemstatus == 3) {  //user pressed 3 to change delay time in matlab
      while (Serial.available() < 1) {
        delay(1);
      }  //wait for new delay time sent from matlab
      int newDelay = Serial.read();
      if (newDelay >= 1 && newDelay <= 255) {  //ensure new delay is within boundary
        delayTimer.waitTime = newDelay;        // set new delay time
      }
      return;
    }




    if (systemstatus == 5) {             // if user pressed 5 to change pin in matlab
      while (Serial.available() < 2) {}  // wait for new pin to be entered in matlab
      int lowByte = Serial.read();
      int highByte = Serial.read();
      int newPIN = (highByte << 8) | lowByte;  //read new pin
      pad.changePIN(newPIN);                   //change pin
      return;
    }






    if (systemstatus == 1) {  // if user pressed 1 to activate system
      greenLight.deactivate();
      yellowLight.activate();  //deactivate green LED and activate yellow to signal request was successful
      delayTimer.wait();       //wait for set delay time
      solenoid.activate();     //activate lock
      delay(10000);            //wait an extra 10 seconds
      systemstatus = 6;        // move to next stage of activation
    }






    while (systemstatus == 6) {
      greenLight.activate();  // green LED lights back up to signify timer is finished and system has succesfully activated


      if (pirSensor.test() == 1) {  // if pir sensor is activated
        redLight.activate();
        buzzer.activate();  //set alarm off
        Serial.write(99);   //inform matlab of sensor status
        while (pushButton.test() == true) {
          delay(1);
        }                                           //wait for push button to be pressed to reset
        Serial.write(11);                           //inform matlab push button has been pressed
        systemstatus = 0;                           // return systemstatus to 0
      } else if (magnetSensorWindow.test() == 1) {  //if window sensor is activated
        redLight.activate();
        buzzer.activate();  //set alarm off
        Serial.write(98);   //inform matlab of sensor status
        while (pushButton.test() == true) {
          delay(1);
        }                                         //wait for push button to be pressed to reset
        Serial.write(11);                         //inform matlab push button has been pressed
        systemstatus = 0;                         // return systemstatus to 0
      } else if (magnetSensorDoor.test() == 1) {  //if door sensor is activated
        redLight.activate();
        buzzer.activate();
        Serial.write(97);
        while (pushButton.test() == true) {
          delay(1);
        }
        Serial.write(11);
        systemstatus = 0;                       //works the same as previous 2 sections
      } else if (pushButton.test() == false) {  //if push button is pressed before a sensor is activated
        Serial.write(11);
        systemstatus = 0;  //inform matlab and reset system status
      }




      if (pushButton.test() == false) {
        Serial.write(11);
        systemstatus = 0;
      }  //check push button again to avoid issues when activating multiple times
    }
    if (systemstatus == 0) {  //if system status = 0 - default
      greenLight.activate();
      yellowLight.deactivate();
      solenoid.deactivate();
      redLight.deactivate();
      buzzer.deactivate();  // deactivate alarm and all lights, activate green light
      return;
    }
  }
};


session wholeSession;  //initialise burglar alarm






void setup() {
  Serial.begin(9600);
  pad.codeCheck();  //initial log in
}




void loop() {
  wholeSession.systemGo();  //system activated
}
