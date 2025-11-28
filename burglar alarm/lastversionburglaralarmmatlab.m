% Matlab component of program to communicate with matlab to implement a burglar alarm system
% Title: lastversionburglaralarmmatlab.m
% Authors:  Max Nyman, Benedict Colin Yuwono, Lojain Mahfouz, Gazl Talib
% Date written:  05/05/2025
device = serialport('COM9',9600);%link with arduino
pause(2);
while true
   input("Press any key to enter system\n");%prompt user to enter any key to begin program
   load("NNmodel.mat");%load facial recognition
   [Hits,I] = Predict(50, 'Test2', newnet);%test face
   if Hits == 0%if face is not recognised, enter pin entry section
       write(device,0,"uint8");%inform arduino face was not recognised and pin is required
       codecheck = 0;
       while true
           PIN = 0;
           pinentry = input("Enter PIN to access system.\n",'s');%prompt user for pin
           PIN = str2double(pinentry);
           write(device,PIN,"uint16");    %send entered pin to arduino
           while device.NumBytesAvailable < 1
               pause(0.1);
           end %wait for response from arduino
           codecheck = read(device, 1, "uint8");%read response from matlab to determine if code was correct or incorrect, and if maximum entry attempts has been exceeded
           while codecheck == 0%while pin is incorrect but max entries is not yet exceedded
               pinentry = input("Incorrect PIN, try again.\n",'s');
               PIN = str2double(pinentry);
               write(device,PIN,"uint16");%prompt for entry again and send this to arduino
               while device.NumBytesAvailable < 1
                   pause(0.1);
               end%wait for response from arduino
               codecheck = read(device, 1, "uint8");%read response from arduino to determine if code was correct or incorrect, and if maximum entry attempts has been exceeded
           end
           if codecheck == 2% if max entries is exceeded
               display('MAXIMUM PIN ATTEMPTS EXCEEDED - ALARM ACTIVATED');%inform user wrong attempts have been exceeded and alarm has been activated
               while device.NumBytesAvailable < 1
                   pause(0.1);
               end%wait for arduino signal caused by push button being pressed to deactivate system
               read(device,1,"uint8");%consume signal sent, nothing needs to be done with it
               continue;% return to asking for pin after system has been deactivated
           else
               break;
           end
       end
   else%else if face was recognised
       write(device,16,"uint8");%inform arduino
       while device.NumBytesAvailable > 0
           read(device, device.NumBytesAvailable, "uint8");
       end%flush serial buffer
   end
   while true
       sensorCheck=0;
       buttonCheck=0;
       activateentry = input("Press 1 to activate system, 2 to log out, 3 to change timer delay or 5 to change PIN \n",'s');%ask user what they want to do
       systemstatus=str2double(activateentry);
       write(device,systemstatus,"uint8");%send system status to arduino
       while systemstatus == 1% while system status is 1 because user wanted to activate system
           if sensorCheck == 0
               disp('SYSTEM ACTIVE');%inform user system is active
               while device.NumBytesAvailable < 1
                   pause(0.1);
               end
           end %wait for confirmation from arduino
           while device.NumBytesAvailable < 1
               pause(0.1);
           end%wait for signal from arduino - either sensor activation or push button pressed to deactivate system
           sensorCheck = read(device, 1, "uint8");%read signal from arduino
           if sensorCheck == 99%if pir activated
               disp('MOTION DETECTED - ALARM SOUNDING')
           elseif sensorCheck == 98%if window sensor activated
               disp('WINDOW OPENED - ALARM SOUNDING')
           elseif sensorCheck == 97%if door sensor activated
               disp('DOOR OPENED - ALARM SOUNDING')
           elseif sensorCheck == 11%if push button pressed
               systemstatus =2;%deactivate systen
           else
               sensorCheck=10;%other signals have no effect
           end
           if sensorCheck == 99 || sensorCheck == 98 || sensorCheck == 97 %if a sensor has been activated
               while true
                   if device.NumBytesAvailable > 0
                       button = read(device, 1, "uint8");
                       if button == 11
                           systemstatus = 2;
                           break;
                       end
                   end
                   pause(0.1);
               end% keep waiting until an 11 has been sent from arduino signalling push button has been pressed to deactivate system
           end
       end
       if systemstatus == 2% if user pressed 2 to log out
           pause(0.1);
           break;%return to log in stage
       elseif systemstatus==3%if user pressed 3 to change delay timer
           while true
               newdelay=input("Enter new delay from 20 to 255 seconds (door locks 10 seconds earlier)\n",'s');%prompt for new delay
               delaycheck=str2double(newdelay);
               if isnan(delaycheck) || delaycheck < 20 || delaycheck >255
                   disp('Invalid input');%display invalid input and prompt again if input is not a number, or out of specified range
               else%if valid time is entered
                   write(device,delaycheck,"uint8");%send new delay time to arduino
                   break;%return to press 1, 2, 3 etc stage
               end
           end
       elseif systemstatus == 5% if user pressed 5 to change pin
           while true
               newpin = input("Enter new PIN number from 1 to 9999\n",'s');%prompt user for new pin
               pincheck = str2double(newpin);
               if isnan(pincheck) || pincheck < 0 || pincheck >9999
                   disp('Invalid input');%display invalid input and prompt again if input is not a number, or out of specified range
               else%if valid pin is entered
                   write(device,pincheck,"uint16");%send new pin to arduino
                   break;%return to press 1, 2, 3 etc stage
               end
           end
       end
   end
end