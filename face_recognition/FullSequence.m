% This code creates functions from code from
% https://uk.mathworks.com/matlabcentral/fileexchange/72005-face-recognition-by-cnn
% to create a sequence for capturing faces,
% training a model, then capturing faces and seeing if the face is recognised. 
% Author: TB, Date: 27/06/2024.

% Yashwanth M (2024). Face-Recognition-by-CNN (https://github.com/Yash0330/Face-Recognition-by-CNN), GitHub. Retrieved July 4, 2024.


%% Capturing faces and training the model using SimpleFaceRecognition.m
n = 2;  % number of different faces to train on
newnet = SimpleFaceRecognition(n);

%% Capturing faces using capturefacesfromvideo.m for testing and prediction
%load("NNmodel.mat");
% number of images to take

%% Predicting the face

%[Hits,I] = Predict(50, 'Test2', newnet);
%liveFaceRecognition(newnet);