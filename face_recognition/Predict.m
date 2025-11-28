% Funtion predict captures faces and predicts who that person is by
% printing to the screen. nameofs0x need to be changed accordingly, and x
% needs to be the correct number of people that can be recognised by the
% algorithm (from training stage). 

function [M,I] = Predict(n,str,newnet)

% Test a new Image
% use code below with giving path to your new image


count = zeros(3,1);

nameofs01 = 'Benedict Colin Yuwono';
nameofs04 = 'Max Nyman';
nameofs03 = 'Gazl Talib';
nameofs02 = 'Lojain Diab';

%% Capturing faces using capturefacesfromvideo.m for prediction
delete(fullfile('croppedfacesTest', 'Test1', '*.jpg'));
predictfacesfromvideo(n,'Test1');

delete(fullfile('croppedfacesTest', 'Test2', '*.jpg'));
ds1 = imageDatastore(fullfile('croppedfacesTest', 'Test1'), 'IncludeSubfolders', true, 'LabelSource', 'foldernames');
cropandsave(ds1,'Test2',0);

imageFiles = dir(fullfile('croppedfacesTest', 'Test2', '*.jpg'));
numFiles = numel(imageFiles);

%% Predicting the face
confidenceThreshold = 0.95;

for i=1:numFiles  %taking the n images
    img = imread(fullfile('croppedfacesTest', 'Test2', [int2str(i), '.jpg']));
    img = imresize(img,[227 227]);

    % can use [predict,score] = classify(newnet,img) here score says the percentage how confidence it is
    [predictFace, score] = classify(newnet, img);
    [maxScore, ~] = max(score); %it will always match an image to a label 

    if maxScore < confidenceThreshold
        %fprintf('The face is not recognized (low confidence: %.2f)\n', maxScore);
    else
        if predictFace == "s01"
            count(1) = count(1) + 1;
            %fprintf('The face detected is %s (confidence: %.2f)\n', nameofs01, maxScore);
        elseif predictFace == "s02"
            count(2) = count(2) + 1;
            %fprintf('The face detected is %s (confidence: %.2f)\n', nameofs02, maxScore);
        %elseif predictFace == "s03"
           %count(3) = count(3) + 1;
            %fprintf('The face detected is %s (confidence: %.2f)\n', nameofs02, maxScore);
        %elseif predictFace == "s04"
            %count(4) = count(4) + 1;
            %fprintf('The face detected is %s (confidence: %.2f)\n', nameofs02, maxScore);
        elseif predictFace == "s03"
            count(3) = count(3) + 1;
            %fprintf('The face is not recognized (unknown label).\n');
        end
    end
end

[M,I] = max(count);

if M == 0
    disp('The face is not recognized');
else
    if I == 1
        disp(['The face detected is ', nameofs01]);
    elseif  I == 2
        disp(['The face detected is ', nameofs02]);
    %elseif  I == 3
        %disp(['The face detected is ', nameofs03]);
    %elseif  I == 4
        %disp(['The face detected is ', nameofs04]);
    elseif I == 3
        disp('The face is not recognized');
    end
end
