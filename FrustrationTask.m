%Clear memory
close all;
clear all;
sca;

%--------------------------------------------------------------------------
%Get Participant Info
%--------------------------------------------------------------------------
fail1='Program aborted. Participant number not entered';
prompt = {'Enter participant number:'};
dlg_title ='New Participant';
num_lines = 1;
 
def = {'0'};
answer = inputdlg(prompt,dlg_title,num_lines,def);%presents box to enterdata into
subjectId = [];
switch isempty(answer)
    case 1%deals with both cancel and X presses
        error(fail1)
    case 0
        subjectId = (answer{1});
end

%Determine if this is the experimental condition or control
num = num2str(subjectId);
isExperimental = str2double(num(1));
penalty = .5;
if isExperimental == 1
    penalty = 1;
end

%--------------------------------------------------------------------------
%Set up Screens
%--------------------------------------------------------------------------

%Call some default settings
PsychDefaultSetup(2);

%The screens attached to the computer
screens = Screen('Screens');

%The screen we are drawing in
screenNumber = max(screens);
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
Screen('Preference', 'SkipSyncTests', 0);

%Window is the window we are drawing in. Window Rect is
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
%anti-aliasing
Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

[xCenter, yCenter] = RectCenter(windowRect);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Measure the vertical refresh rate of the monitor
ifi = Screen('GetFlipInterval', window);

%--------------------------------------------------------------------------
%Parameters
%--------------------------------------------------------------------------
responseTime = .5;%seconds
interStimDelay = 1;%seconds
time = 120;
%--------------------------------------------------------------------------
%Set Up Fixation Point
%--------------------------------------------------------------------------

% Here we set the size of the arms of our fixation cross
fixCrossDimPix = 20;

% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

% Set the line width for our fixation cross
lineWidthPix = 2;

%--------------------------------------------------------------------------
%Set Up Squares
%--------------------------------------------------------------------------
%Rectangle Size
baseRect = [0 0 100 100];

xLeft = screenXpixels/5;
xRight = screenXpixels - screenXpixels/5;

% Center the rectangle on the centre of the screen using fractional pixel
% values.
% For help see: CenterRectOnPointd
leftSquare = CenterRectOnPointd(baseRect, xLeft, yCenter);
rightSquare = CenterRectOnPointd(baseRect, xRight, yCenter);

%--------------------------------------------------------------------------
%Progress Bar
%--------------------------------------------------------------------------
progress = 0; %their saturated score
trueProgress = 0; %their actual progress
performance = 0; %progress/totalProg

totalProg = 500; %the max value for progress
yProgBar = screenYpixels/5;

baseFrame = [0 0 totalProg 10];
progFrame = CenterRectOnPointd(baseFrame, xCenter, yProgBar);
width = 2;
%--------------------------------------------------------------------------
%Run the Experiment
%--------------------------------------------------------------------------

score = 0;

mu = .5;
sig = .7;
dist = makedist('Normal', 'mu', mu, 'sig', sig);
waitframes = 1;

%A Description of the Task
Screen('TextSize', window, 20);
DrawFormattedText(window, 'In this portion of experiment you will be shown two squares.\n One on the left side of the screen, and one on the right side of the screen', 'center',...
    screenYpixels * 0.20, [1 1 1]);
DrawFormattedText(window, 'It is your task to determine which square appeared first', 'center',...
    screenYpixels * 0.25, [1 1 1]);
DrawFormattedText(window, 'Press "f" if the left square appears first or "j" if the right square appears first', 'center',...
    screenYpixels * 0.30, [1 1 1]);
DrawFormattedText(window, 'Press any key to continue', 'center',...
    screenYpixels * 0.40, [1 1 1]);

Screen('DrawLines', window, allCoords,...
    lineWidthPix, white, [xCenter yCenter], 2);

Screen('Flip', window);

KbStrokeWait;

Screen('Flip', window);
for frame = 1:10
    Screen('TextSize', window, 20);
    DrawFormattedText(window, 'You can view your score in the progress bar above', 'center',...
        screenYpixels * 0.20, [1 1 1]);
    DrawFormattedText(window, 'If the bar is filled you will recieve candy', 'center',...
        screenYpixels * 0.25, [1 1 1]);
    DrawFormattedText(window, 'Press any key to begin', 'center',...
        screenYpixels * 0.40, [1 1 1]);

    Screen('DrawLines', window, allCoords,...
        lineWidthPix, white, [xCenter yCenter], 2);

    Screen('Flip', window);
end
KbStrokeWait;

%--------------------------------------------------------------------------
%Let The Task Begin
%--------------------------------------------------------------------------
start = GetSecs;
%Time for a certain amount of time
trial = 1;
currentTime = GetSecs;
while currentTime - start < time

    elapsed = currentTime - start;
    
    response = 'wrong';
    baseBar = [0 0 progress 10];
    progBar = [progFrame(:,1), progFrame(:,2),...
        progFrame(:,1) + progress, progFrame(:,4) ]; 
    CenterRectOnPointd(baseBar, xCenter, yProgBar);
    
    progBar = round(progBar);
    %InterStimulus Period
    %Clear the Screen
    vbl = Screen('Flip', window);
    frameNumber = round(interStimDelay / ifi);
    for frame = 1:frameNumber
        Screen('FillRect', window, [0, 0, 0]);
        Screen('FillRect', window, [1,1,1], progBar);
        Screen('FrameRect', window, [.5,0,0], progFrame, width);
        Screen('DrawLines', window, allCoords,...
    lineWidthPix, white, [xCenter yCenter], 2);

        vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi); 
    end
    
    %Randomly get the first square to appear
    squares = [leftSquare; rightSquare];
    answer = 'left';
    if rand < .5
        squares(1,:) = rightSquare;
        squares(2,:) = leftSquare;
        answer = 'right';
    end
    
    %The period between the two squares being displayed
    interSquareDelay = dist.random;
    
    if interSquareDelay > 1
        interSquareDelay =1;
    end
    
    frameNumber = round(interSquareDelay / ifi);
    if interSquareDelay > 0
        vbl = Screen('Flip', window);
        for frame = 1:frameNumber
            Screen('FillRect', window, [1,1,1], progBar);
            Screen('FrameRect', window, [.5, 0,0], progFrame, width);
            Screen('DrawLines', window, allCoords,...
        lineWidthPix, white, [xCenter yCenter], 2);
            Screen('FillRect', window, [1, 1, 1], squares(1,:));

            vbl = Screen('Flip', window, vbl + (waitframes - 0.5) * ifi);

            [keyIsDown, secs, keyCode] = KbCheck;

            %Exit this stimuli presentation if a key is pressed
            if keyIsDown
                %Record the stimuli
                key = KbName(keyCode);
                key = key(1,1);
                if strcmp(key, 'f')
                    response = 'left';
                elseif strcmp(key, 'j')
                    response = 'right';
                else
                    response = 'wrong';
                end
            end

        end
    end
    frameNumber = round(responseTime / ifi);
    
    vbl = Screen('Flip', window);
    for frame = 1:frameNumber
        Screen('FillRect', window, [1,1,1], progBar);
        Screen('FrameRect', window, [.5, 0,0], progFrame, width);
        Screen('DrawLines', window, allCoords,...
    lineWidthPix, white, [xCenter yCenter], 2);
        Screen('FillRect', window, [1, 1, 1], squares(2,:));
        Screen('FillRect', window, [1, 1, 1], squares(1,:));

        vbl = Screen('Flip', window, vbl + (waitframes - 0.5)*ifi);
        
        [keyIsDown,secs, keyCode] = KbCheck;
        
        %Exit this stimuli presentation if a key is pressed
        if keyIsDown
            %Record the stimuli
            key = KbName(keyCode);
            key = key(1,1);
            if strcmp(key, 'f')
                response = 'left';
            elseif strcmp(key, 'j')
                response = 'right';
            else
                response = 'wrong';
            end
        end
        
    end
    
    %In the Experimental Group, Rig the task against them
    %If they do well enough, they will automatically be wrong with some
    %probability. However, if in the last portion of the experiment, there
    %is a brief period of unrigging, followed by a period of total rigging
    if isExperimental == 1
        %The task is impossible
        if performance >= 9/10
            answer = 'wrong';
        end
        %Rig the Game if the task is is half way through the experiment
        if elapsed/time > .90
            answer = 'wrong';
        elseif ~(performance > .8 && elapsed/time > .75 && elapsed/time < .80)            
            %Otherwise, make them automatically wrong, with a probability
            %proportional to the their closeness, but only if the delay was
            %small, that way it is harder to recognize the task is rigged
            if rand < (progress/totalProg/2) && interSquareDelay < .25
                answer = 'wrong';
            end
        end
    end
        
    %Calc Progress
    %If the answer is correct increment the Score
    if strcmp(response, answer)
        score = score + 1;
    %If the answer is correct decrement the score
    else
        score = score - penalty;
        %The score bottoms out at 0
        if score < 0
            score = 0;
        end
        
    end
    
    %For the Progress Bar
    %trueProgress is their actuall progress without saturation beyond 100%
    %progress is the number of pixels long the bar is
    trueProgress = (score/(.2*time))*totalProg;
    progress = trueProgress;
    if trueProgress > totalProg
        progress = totalProg;
    end
    
    %In the Experimental Group, adjust the difficulty
    if isExperimental == 1
        performance = progress/totalProg;
        %Recalculate the distribution
        
        %If they aren't doing horridly, increase the difficulty
        if performance > .25
            mu = mu - (mu/(1/performance));
            if mu < .05
                mu = .05;
            end
            dist = makedist('Normal', 'mu', mu, 'sig', sig);
        end
    end
    
    %In either Group, adjust the difficulty to be easier if they are doing
    %horridly
    if (score/trial) < .25
        %adjust it proportional to their score
        mu = mu + (mu/10);
        %Cap the distribution at 1
        if isExperimental && mu > .5
            mu = .5;
        elseif mu > 1
            mu = 1;
        end
        dist = makedist('Normal', 'mu', mu, 'sig', sig);
    end
    
    currentTime = GetSecs;
    trial = trial + 1;
end
Screen('FillRect', window, [0,0,0]);
Screen('Flip', window);

frameNumber = round(.5 / ifi);
    
vbl = Screen('Flip', window);
for frame = 1:frameNumber
    Screen('FillRect', window, [1,1,1], progBar, width);
    Screen('FrameRect', window, [.5, 0,0], progFrame, width);
    vbl = Screen('Flip', window, vbl + (waitframes - 0.5)*ifi);
end

Screen('FillRect', window, [1,1,1], progBar);
Screen('FrameRect', window, [.5, 0,0], progFrame, width);
if progress/totalProg >= 1
    if isExperimental ~= 1
        DrawFormattedText(window, 'Tell the experimenter you are in group 2', 'center',...
        screenYpixels * 0.25, [1 1 1]);
    else
        DrawFormattedText(window, 'Tell the experimenter you are in group 0', 'center',...
        screenYpixels * 0.30, [1 1 1]);        
    end
    DrawFormattedText(window, 'Threshold Performance! You Get Candy', 'center',...
        screenYpixels * 0.30, [1 1 1]);
else
    if isExperimental ~= 1
        DrawFormattedText(window, 'Tell the experimenter you are in group 0', 'center',...
        screenYpixels * 0.25, [1 1 1]);
    else 
        DrawFormattedText(window, 'Tell the experimenter you are in group 1', 'center',...
        screenYpixels * 0.25, [1 1 1]);
    end
    DrawFormattedText(window, 'Sub-Threshold Performance. No Candy', 'center',...
        screenYpixels * 0.30, [1 1 1]);
end
DrawFormattedText(window, 'Press any key to end', 'center',...
    screenYpixels * 0.40, [1 1 1]);
Screen('Flip', window);

KbStrokeWait;

performance = progress/totalProg;
save(strcat(subjectId, '.mat'), 'subjectId', 'performance', 'trueProgress', 'totalProg');

sca;