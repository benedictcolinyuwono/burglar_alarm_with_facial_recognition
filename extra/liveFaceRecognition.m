function liveFaceRecognition(newnet)
% liveFaceRecognition(newnet)
%
% Live face recognition using an already-trained network (newnet).
% Assumes faces have already been captured and trained using your
% previous system. Uses AlexNet-based network for prediction.
%
% Example:
%   load('NNmodel.mat');  % your trained model
%   liveFaceRecognitionOnly(newnet);

% Define names of your people here:
nameofs01 = 'Benedict Colin Yuwono';
nameofs02 = 'Max Nyman';
nameofs03 = 'Gazl Talib';
nameofs04 = 'Lojain Diab';

% Add more names if needed:
% nameofs03 = 'Another Person';

% Initialize webcam
try
    vidObj = webcam; % default webcam
catch
    beep;
    disp('Please make sure that a properly recognized webcam is connected and try again.');
    return
end

% Create face detector
faceDetector = vision.CascadeObjectDetector('FrontalFaceCART', 'MinSize', [150, 150]);

% Set up figure window
hFig = figure('Name', 'Live Face Recognition', 'NumberTitle', 'off');

disp('Close the figure window to stop live recognition.');

while ishandle(hFig)
    % Capture a frame
    videoFrame = snapshot(vidObj);
    videoFrameGray = rgb2gray(videoFrame);

    % Detect faces
    bboxes = faceDetector.step(videoFrameGray);
    
    % Annotate each detected face
    if ~isempty(bboxes)
        for i = 1:size(bboxes, 1)
            % Crop face
            faceImg = imcrop(videoFrame, bboxes(i, :));
            
            % Resize to [227, 227] for AlexNet
            try
                faceImg = imresize(faceImg, [227, 227]);
            catch
                % Skip if resize fails (e.g., tiny faces)
                continue;
            end
            
            % Predict face
            [predictFace, score] = classify(newnet, faceImg);
            [maxScore, ~] = max(score);
            confidenceThreshold = 0.95;
            
            % Determine label
            if maxScore < confidenceThreshold
                label = 'Unrecognized';
            else
                if predictFace == "s01"
                    label = nameofs01;
                elseif predictFace == "s02"
                    label = nameofs02;
                elseif predictFace == "s03"
                    label = nameofs03;
                elseif predictFace == "s04"
                    label = nameofs04;
                else
                    label = 'Unrecognized';
                end
            end
            
            % Annotate face in video frame
            videoFrame = insertObjectAnnotation(videoFrame, 'rectangle', bboxes(i, :), ...
                sprintf('%s (%.2f)', label, maxScore), 'LineWidth', 3, 'Color', 'yellow', 'FontSize', 18);
        end
    end
    
    % Display the video frame
    imshow(videoFrame);
    drawnow;
end

% Clean up (if you manually stop the loop)
delete vidObj;
release(faceDetector);

end
