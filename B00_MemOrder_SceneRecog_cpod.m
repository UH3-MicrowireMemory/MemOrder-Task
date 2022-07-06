%% Scene Recognition task: identify whether the image is old or new
% Inter-trial interval is 0.5 second
% Each image lasts 1 second: 
%   50% of targe (FrameA at 2s of the clip; FrameB at 6s of the clip)
%   50% of Foil (Similar frames near the clip but not shown before)
%   i.e. 25% FrameAtarget, 25% FrameBtarget. 25%FrameAFoil, 25%FrameBFoil
% Response OLD or NEW, self-paced, reponse within 2 seconds
% TTL pulses were sent at CrossStart, ClipStart, ClipEnd
%
% Output file: respMat_SceneRecog, a structure variable with log info
%   respMat_SceneRecog.CrossStart: time onset of fixation period in second
%   respMat_SceneRecog.CrossEnd: time offset of fixation period in second
%   respMat_SceneRecog.FrameStart: time onset of frame display period in second
%   respMat_SceneRecog.FrameEnd: time offset of frame display period in second
%   respMat_SceneRecog.FrameName: filename of the frame image
%   respMat_SceneRecog.QuesStart: time onset of random question period in second
%   respMat_SceneRecog.respValue: subjects' response value including
%                      -3 = OLD, SURE                 3 = NEW, SURE
%                      -2 = OLD, LESS SURE            2 = NEW, LESS SURE
%                      -1 = OLD, VERY UNSURE          1 = NEW, VERY UNSURE
%   or if Cedrus response box is used, then
%                      2 = NO, SURE                  5 = YES, SURE
%                      3 = NO, LESS SURE             6 = YES, LESS SURE
%                      4 = NO, VERY UNSURE           7 = YES, VERY UNSURE  
%   respMat_SceneRecog.respTime: timestamp when subject presses the button in second


try
%--------------------------------------------------------------------------
%                       PTB setup
%--------------------------------------------------------------------------
clear all
clc
sca; 
commandwindow; 
HideCursor;
% config_io
% PsychDefaultSetup(2);
% Screen('Preference','SkipSyncTests',0.005,50, 0.3,5); % skip screen test
% AGPS changed
Screen('Preference','SyncTestSettings', 0.005,50, 0.3,5); % screen syncing
% Check if Psychtoolbox is properly installed: 
AssertOpenGL;
if IsWin && ~IsOctave && psychusejava('jvm')
    fprintf('Running on Matlab for Microsoft Windows, with JVM enabled!\n');
    fprintf('This may crash. See ''help GStreamer'' for problem and workaround.\n');
    warning('Running on Matlab for Microsoft Windows, with JVM enabled!');
end

%--------------------------------------------------------------------------
%                       Display setup
%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%% Screen Feature Setup %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set the screen number to the external secondary monitor if there is one
% connected 
screenid = max(Screen('Screens'));
% Define black, white and grey
white = WhiteIndex(screenid);
gray = GrayIndex(screenid);
black = BlackIndex(screenid);
%%% TESTING: Smaller screen, switch to full screen for real experiment
para.windowRect_define = [0 0 1370 680]; % 13.3inch mac is 2560 x 1600
%%% TESTING: Open 'windowrect' sized window, switch to full screen for real experiment
[window, windowRect] = PsychImaging('OpenWindow', screenid, gray, para.windowRect_define); % resized screen
% [window, windowRect] = PsychImaging('OpenWindow', screenid, gray);
% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA','GL_ONE_MINUS_SRC_ALPHA');

%%%%%%%%%%%% Scaled Text (instruction and question) Setup %%%%%%%%%%%%%%%%%
% Get size of the on screen window
screenXpixels  = windowRect(3);
screenYpixels  = windowRect(4);
% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);
% Load example image. Instruction and question are the same size
theImg_text=imread(fullfile(pwd,'\E00_InstruText\B01_SceneRecogInstruText.png')); % 1066 X 1422
% Get the size of the image
[orig_width_text, orig_height_text, ~]=size(theImg_text); 
% Define the fraction of scale, this is for Y axis match between img and screen
heightScaler_text = 0.8; % 80% height of the screen y axis
imgHeight_text = screenYpixels * heightScaler_text;
imgWidth_text = imgHeight_text * orig_height_text / orig_width_text;
theRect_text = [0 0 imgWidth_text imgHeight_text];
dstRect_text = CenterRectOnPointd(theRect_text, screenXpixels/2, screenYpixels/2);
% %%% TESTING: Draw the image to the center of the screen with scaled size
% % Make the image into a texture
% theTexture = Screen('MakeTexture', window, theImg_text);
% Screen('DrawTextures', window, theTexture, [], dstRect_text);
% Screen('Flip', window);% Flip to the screen
% KbStrokeWait;% Wait for Key press
% sca% Clear the screen

%%%%%%%%%%%%%%%%%%%%%%%% Scaled Image Setup %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Load example image. Instruction and question are the same size
theImg=imread(fullfile(pwd,'\B01_SceneRecogImg\HB_1cut_1_1.png')); % 960 x 540
% Get the size of the image
[orig_width, orig_height, ~]=size(theImg); 
% Define the fraction of scale, this is for Y axis match between img and screen
heightScaler = 0.6; % 60% height of the screen y axis
imgWidth = screenXpixels * heightScaler;
imgHeight = imgWidth * orig_width / orig_height;
theRect = [0 0 imgWidth imgHeight];
dstRect = CenterRectOnPointd(theRect, screenXpixels/2, screenYpixels/2);
% %%% TESTING: Draw the image to the center of the screen with scaled size
% % Make the image into a texture
% theTexture = Screen('MakeTexture', window, theImg);
% Screen('DrawTextures', window, theTexture, [], dstRect);
% Screen('Flip', window);% Flip to the screen
% KbStrokeWait;% Wait for Key press
% sca% Clear the screen

%%%%%%%%%%%%%%%%%% Scaled Inter-trial Fixation Cross Setup %%%%%%%%%%%%%%%%
% Screen Y axis fraction for fixation cross  
crossFrac = 0.0167;
% Here we set the size of the arms of our fixation cross
fixCrossDimPix = screenYpixels * crossFrac;
% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix]; 
fixCoords = [xCoords; yCoords];
% Set the line width for our fixation cross
lineWidthPix = 4;
% Duration for fixation cross in seconds
itiTimeSecs = 0.5; 
% Duration for frame display in seconds:
para.frameTimeSecs = 1.5;
% Duration ofr question period in seconds:
para.QuesTimeSecs = 5;

%--------------------------------------------------------------------------
%                   Experiment Parameter Setup
%--------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%% Script Execution Warm Up %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set priority for script execution to realtime priority:
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);
% Query the frame duration
ifi = Screen('GetFlipInterval', window);
% Do dummy calls to GetSecs, WaitSecs, KbCheck to make sure
% they are loaded and ready when we need them - without delays
% in the wrong moment:
KbCheck;
WaitSecs(0.1);
GetSecs;

%%%%%%%%%%%%%%%%%%%% Experiement Features Define %%%%%%%%%%%%%%%%%%%%%%%%%%
para.Ntrial = 180; % the total number of trials, FIXME later 
% Seed for the random number generator
rng('shuffle','twister'); 
% clip list folder
para.frameDIR = fullfile(pwd,'\B01_SceneRecogImg\'); % stimuli directory

%%%%%%%%%%%%%%%%%%%% Experiement Keyboard SetUp %%%%%%%%%%%%%%%%%%%%%%%%%%%
KbName('UnifyKeyNames');
spaceKey = KbName('space');
% escapeKey = KbName('Esc');
escapeKey = KbName('ESCAPE');
NoSureKey = KbName('s');
NoLessSureKey = KbName('d'); 
NoVeryUnsureKey = KbName('f'); 
YesVeryUnsureKey = KbName('j'); 
YesLessSureKey = KbName('k');
YesSureKey = KbName('l'); 
pauseKey = KbName('Tab'); % Save the key for pause, FIXME later

%%%%%%%%%%%%%%%%%%%% Experiement Output SetUp %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add the helper_files into the working path, which contains subfunctions
addpath([pwd, '\helper_files']); 

% assign the subject ID
if ~psychusejava('jvm')
   current_time = clock;
   para.sub_id = sprintf('%d', current_time(1:end-1));
else
   prompt = 'What is the subject id?';
   % para.sub_id = input(prompt,'s');
   answer = inputdlg(prompt, 'Subject ID', [1 35]);
   para.sub_id = answer{1,1};
end
HideCursor;
para.output_filename = fullfile(pwd,['\D00_Logs\',para.sub_id,'_sceneRecog.mat']);
% check for existing result file to prevent accidentally overwriting
% files from a previous subject/session (except for subject numbers > 99):
if isempty(para.sub_id)
    Priority(0);
    fprintf('Please restart and enter the subject id');
    ShowCursor; sca; return; 
elseif fopen(para.output_filename, 'rt') ~= -1
    Priority(0);
    fprintf('The file name already exists, please change to another one');
    ShowCursor; sca; return;
end

% Setup for Cedrus reponse box 
para.cedrus_flag = 1; % Will use cedrus box for response? 1 = YES, 0 = NO
if para.cedrus_flag % setup Cedrus response box
    % clear up any Cedrus connections
    try
        port = initCEDRUS_multiOS; % search all the
    catch
        CedrusResponseBox('CloseAll');
        port = initCEDRUS_multiOS;
    end
    % Try to open and init the box, return handle 'h' to it:
    handle = CedrusResponseBox('Open', port);
end

% Setup for EyeLink1000
para.eyelink_flag = 0; % Will use EyeLink1000 for eye tracking? 1 = YES, 0 = NO
fileLabel = [para.sub_id, '_sceneRecog_eye_'];
[para.eyefidLog, para.eyefnameLog, para.eyeTimestampStr] = openLogfile(fileLabel,[pwd,'\D00_Logs\eyeLogs\']);
para.eyedata_filename = [pwd,'\D00_Logs\', fileLabel, para.eyeTimestampStr];
% writeLog_withEyelink(para.eyefidLog,0,para.eyedata_filename, 0);

%setup eye tracker
if para.eyelink_flag
    dummymode=0;       % set to 1 to initialize in dummymode
    % edffilename_local = [logDir 'NO' timestampStr '.edf'];
    retCode = eyeLink_setup_PTB3(window, dummymode, ['MemSeg_seneRecog_eye_' para.eyeTimestampStr(end-5:end)]);
    
    if retCode~=1   % 1 means succeedeed
       %aborted
       terminateExperiment(window,para.eyefidLog,para.eyeLink_flag);
       disp('Experiment aborted in eyelink setup screen');
       return;
    else
        
        Eyelink('Message', [para.eyefnameLog]); 
        Eyelink('Message', para.eyedata_filename );
        
        Eyelink('command', 'record_status_message "NO exp init"'); 

    end
end


% if para.eyelink_flag % set up eyelink for eye tracking
%    dummymode = 0;       % set to 1 to initialize in dummymode 
%    % retCode = eyeLink_setup_PTB3(window, dummymode, ['MemSeg_seneRecog_eye_' para.eyeTimestampStr(end-5:end)]);   
%    eyeLink_setup_PTB3(window, dummymode, ['MemSeg_seneRecog_eye_' para.eyeTimestampStr(end-5:end)]);
%    if retCode % success connected
%       Eyelink('Message', para.eyefnameLog);
%    else
%       Priority(0);
%       fprintf('Experiment aborted due to the failure of eye link setup');
%       ShowCursor; sca; return
%    end
    
%end

% Need to send TTL pulses?
para.TTL_flag = 1;
if para.TTL_flag
   para.TTL.task_onset = 61;
   para.TTL.fix_cross = 11;
   para.TTL.img_onset = 1;
   para.TTL.img_offset = 2;
   para.TTL.probe = 3;
   para.TTL.response = 4;
   para.TTL.task_offset = 60; 
   para.TTL.afterTTLDelay=0;  %in secs, wait till reset of TTL to 0
   % open cpod for preparation
   openTTL_cpod('COM4');   
end

recordingDate = clock;
respMat_SceneRecog= []; % Initialize the variable to store log information
% 1-CrossStart; 2-CrossEnd; 3-ImgStart; 4-ImgEnd; 5-ImgName; 
% 6-QuesStart; 7-QuesName; 8-respValue; 9-respTime;
errorMsg = []; % Intialize the variable to store error messages

%--------------------------------------------------------------------------
%                        Load Task Instruction
%--------------------------------------------------------------------------
% Restrict Key to escape and space
RestrictKeysForKbCheck([spaceKey escapeKey]);
FrameImg=imread(fullfile(pwd,'\E00_InstruText\B01_SceneRecogInstruText.png'));
% make texture image out of image matrix 'imdata'
FrameTex=Screen('MakeTexture', window, FrameImg);
% Draw texture image to backbuffer. 
Screen('DrawTexture', window, FrameTex,[], dstRect_text); % proportional display
% Show instructions on screen at next possible display refresh cycle
Screen('Flip', window); 
[~, KeyCode, ~] = KbPressWait;
% Check the KeyCode for different function
if KeyCode(escapeKey)
   Priority(0);
   errorMsg = {'User pressed ESC, quit task at Instruction phase'};
   ShowCursor;
   save(para.output_filename,'recordingDate','respMat_SceneRecog','errorMsg','para'); sca;
end
if KeyCode(spaceKey)
   Screen('Flip', window);
end

%--------------------------------------------------------------------------
%                        Load Practice Trial
%--------------------------------------------------------------------------
eg_file = {'B02_Example_1','B02_Example_2', 'ready'};
egs_n = length(eg_file);
for n_eg = 1:egs_n
    egImg = imread([pwd,'\E00_InstruText\',eg_file{n_eg}, '.png']);
    egTex = Screen('MakeTexture', window, egImg);
    Screen('DrawTexture', window, egTex,[], dstRect_text); % proportional display
    Screen('Flip', window);
    [~, KeyCode, ~] = KbPressWait;
    % Check the KeyCode for different function
    if KeyCode(escapeKey)
       Priority(0);
       errorMsg = {'User pressed ESC, quit task at Instruction phase'};
       ShowCursor; 
       save(para.output_filename,'recordingDate','respMat','errorMsg','para'); sca;
    end
    if KeyCode(spaceKey)
       Screen('Flip', window);
    end
end    

%--------------------------------------------------------------------------
%                        Start Real Experiment
%--------------------------------------------------------------------------
% Send a TTL pulse to mark the onset of the experiment
if para.TTL_flag
   % sendTTLsEYElink(para.TTL.task_onset,0,para.eyefidLog,para.TTL.afterTTLDelay,para.eyelink_flag);
   sendTTL_cpod(para.TTL.task_onset);
end

%%%%%%%%%%%%%%%%%%%%%%%%%% Scan frame folder %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
frameList = dir([para.frameDIR,'\*.png']);
para.frameNum = length(frameList);
% Check whether video clips number matches with trial number
if para.frameNum ~= para.Ntrial
   Priority(0);
   errorMsg = {'Not all the frame images are included'};
   ShowCursor;
   save(para.output_filename,'recordingDate','respMat_SceneRecog','errorMsg','para'); sca;
end
% pre-load question image, since it's the same for all the trials, no need
% to add into the for loop
QuesImg=imread(fullfile(pwd,'\E00_InstruText\B03_QuesText.png'));
% make texture image out of image matrix 'QuesImg' 
QuesTex=Screen('MakeTexture', window, QuesImg);
  
%%%%%%%%%%%%%%%%%%%%%%%%%% Single trial SetUp %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Restrict Key to escape, left and right
% RestrictKeysForKbCheck([escapeKey pauseKey]); % only enable the escape key for the fixation and image display period
trial_indx = 0; % count the trial number
for trial_n = randperm(para.frameNum,para.frameNum)
    %inputemu({'key_normal','H\BACKSPACE'});
    % Simulate key pression to avoid sleep
    
    trial_indx = trial_indx + 1;
    %%%%%%%%%%%%%%%% Fixation period (0.5s)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Screen('DrawLines', window, fixCoords, lineWidthPix, white, [xCenter yCenter]);
    [~, startrt] = Screen('Flip', window);
    % Send a TTL pulse to mark the onset of fixation cross and save this baseline onset in the respMat
    if para.TTL_flag
       % sendTTLsEYElink(para.TTL.fix_cross,0,para.eyefidLog,para.TTL.afterTTLDelay,para.eyelink_flag);
       sendTTL_cpod(para.TTL.fix_cross);
    end
    respMat_SceneRecog(trial_indx).CrossStart = double(startrt);
    % add jitter to fixation cross
    para.itiTimeSecs(trial_indx) = itiTimeSecs - (randperm(500,1)/1000-0.25);
    % Show fixation cross until the ITI duration elapsed or 
    % the 'escapeKey' is pressed to quit the experiment
    while (GetSecs - startrt)<= para.itiTimeSecs(trial_indx)
         [keyIsDown,secs, keyCode] = KbCheck;
         if keyCode(escapeKey)
            Priority(0);
            errorMsg = {['user pressed ESC, quit task during the encoding at the fixation cross of trial ', num2str(trial_indx)]};
            ShowCursor; 
            save(para.output_filename,'recordingDate','respMat_SceneRecog','errorMsg','para'); sca; return;
         end
                  %%%%%%%%%%% Added pause key by JZ %%%%%%%%%
         if keyCode(pauseKey)
            Screen('Flip', window);
            pause
         end
        % Wait 1 ms before checking the keyboard again to prevent
        % overload of the machine at elevated Priority():
        WaitSecs(0.001);
    end
    Screen('Flip', window);
    respMat_SceneRecog(trial_indx).CrossEnd = double(GetSecs);
    WaitSecs(0.01);
    
    %%%%%%%%%%%%%%%%%%%%%%% Frame display period (1s) %%%%%%%%%%%%%%%%%%%%%
    FrameImg=imread(fullfile(pwd,'\B01_SceneRecogImg\', frameList(trial_n).name));
    % make texture image out of image matrix 'FrameImg'
    FrameTex=Screen('MakeTexture', window, FrameImg);
    % Draw texture image to backbuffer. 
    Screen('DrawTexture', window, FrameTex,[], dstRect); % proportional display
    % Show instructions on screen at next possible display refresh cycle
    [~, startrt_frame] = Screen('Flip', window); 
    % Send a TTL pulse to mark the onset of the image and save img_onset to the variable 'respMat_SceneRecog'
    if para.TTL_flag
       % sendTTLsEYElink(para.TTL.img_onset,trial_indx,para.eyefidLog,para.TTL.afterTTLDelay,para.eyelink_flag);
       sendTTL_cpod(para.TTL.img_onset);
    end
    respMat_SceneRecog(trial_indx).FrameStart = double(startrt_frame);
    respMat_SceneRecog(trial_indx).FrameName = frameList(trial_n).name;
    while (GetSecs - startrt_frame) <= para.frameTimeSecs
        [keyIsDown,secs, keyCode] = KbCheck;
        if keyCode(escapeKey)
            Priority(0);
            errorMsg = {['user pressed ESC, quit task during the encoding at the frame display of trial ', num2str(trial_indx)]};
            ShowCursor; 
            save(para.output_filename,'recordingDate','respMat_SceneRecog','errorMsg','para'); sca; return;
        end
          %%%%%%%%%%% Added pause key by JZ %%%%%%%%%
        if keyCode(pauseKey)
            Screen('Flip', window);
            pause
        end
        % Wait 1 ms before checking the keyboard again to prevent
        % overload of the machine at elevated Priority():
        WaitSecs(0.001);
    end
    Screen('Flip', window);
    if para.TTL_flag
       % sendTTLsEYElink(para.TTL.img_offset,trial_indx,para.eyefidLog,para.TTL.afterTTLDelay,para.eyelink_flag);
       sendTTL_cpod(para.TTL.img_offset);
    end
    respMat_SceneRecog(trial_indx).FrameEnd = double(GetSecs);
    WaitSecs(0.01);
    
    %%%%%%%%%%%%%%% Question Period (self-paced, up to 2s) %%%%%%%%%%%%%%%%
    RestrictKeysForKbCheck([escapeKey NoSureKey NoLessSureKey NoVeryUnsureKey ... 
                        YesVeryUnsureKey YesLessSureKey YesSureKey pauseKey]);
    % Draw texture image to backbuffer.
    Screen('DrawTexture', window, QuesTex,[],dstRect_text); % proportional display, no rotation
    % Show question on screen at next possible display refresh cycle,
    % and record question onset time in 'startrt': 
     Screen('Flip', window);
    if para.TTL_flag
       % sendTTLsEYElink(para.TTL.probe,trial_indx,para.eyefidLog,para.TTL.afterTTLDelay,para.eyelink_flag);
        sendTTL_cpod(para.TTL.probe);
    end
    respMat_SceneRecog(trial_indx).QuesStart = double(GetSecs);
    % start Response screen (not a loop! - wait for resp), KbPressWait
    % is not used here because there is 5ms delay
    respMat_SceneRecog(trial_indx).respValue = [];
        % Now we wait for a keyboard button signaling the observers response.
        % You can also press escape if you want to exit the program  
        if para.cedrus_flag
           CedrusResponseBox('FlushEvents', handle); % clear up the previous button press
           CedrusResponseBox('ResetRTTimer', handle);
          while 1
            % Check whether the 'esc' was pressed to quit the experiment
            [keyIsDown,secs, keyCode] = KbCheck;
            if keyCode(escapeKey)
                Priority(0);
                errorMsg = {['user pressed ESC, quit task during the encoding at the random question of trial ', num2str(trial_indx)]};
                ShowCursor;
                save(para.output_filename,'recordingDate','respMat_SceneRecog','errorMsg','para'); sca; return
            end
           evt = CedrusResponseBox('GetButtons', handle);
            if (GetSecs - respMat_SceneRecog(trial_indx).QuesStart) > para.QuesTimeSecs
                break;
            end
            if ~isempty(evt) && evt.button ~= 8
                RT = evt.rawtime;
                % send a TTL pulse to mark the reponse time and save this response time to the respMat
                if para.TTL_flag
                  %  sendTTLsEYElink(para.TTL.response,[RT,evt.button],para.eyefidLog,para.TTL.afterTTLDelay,para.eyelink_flag);
                   sendTTL_cpod(para.TTL.response);
                end
                respMat_SceneRecog(trial_indx).respValue = evt.button; break;
            end
           end
          evt = [];
          CedrusResponseBox('FlushEvents', handle);
        else
           while (GetSecs - respMat_SceneRecog(trial_indx).QuesStart) <= para.QuesTimeSecs
            [keyIsDown,secs, keyCode] = KbCheck;
            if keyCode(escapeKey)
                Priority(0);
                errorMsg = {['user pressed ESC, quit task during the encoding at question session of trial ', num2str(trial_indx)]};
                ShowCursor;
                save(para.output_filename,'recordingDate','respMat_SceneRecog','errorMsg','para'); sca; return
            elseif keyCode(NoSureKey)
                respMat_SceneRecog(trial_indx).respValue = -3; % NO, Sure
                break;
            elseif keyCode(NoLessSureKey)
                respMat_SceneRecog(trial_indx).respValue = -2; % NO, Less Sure
                break;
            elseif keyCode(NoVeryUnsureKey)
                respMat_SceneRecog(trial_indx).respValue = -1; % NO, Very Unsure
                break;
            elseif keyCode(YesVeryUnsureKey) 
                respMat_SceneRecog(trial_indx).respValue = 1; % YES, Very Unsure 
                break;
            elseif keyCode(YesLessSureKey)
                respMat_SceneRecog(trial_indx).respValue = 2; % YES, Less Sure
                break;
            elseif keyCode(YesSureKey) 
                respMat_SceneRecog(trial_indx).respValue = 3; % YES, Sure
                break;
            end
           end
       end
    respMat_SceneRecog(trial_indx).respTime = double(secs); %get time of response 
end


% Send a TTL pulse to mark the end of the task
if para.TTL_flag
   % sendTTLsEYElink(para.TTL.task_offset,trial_indx,para.eyefidLog,para.TTL.afterTTLDelay,para.eyelink_flag);
   sendTTL_cpod(para.TTL.task_offset);
   pause(0.5);
    % close cpod for the next use
   closeTTL_cpod('COM4');
end

%%%%%%%%%%%%%%%%%%%%%%%%%% Save Output File %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
save(para.output_filename,'recordingDate','respMat_SceneRecog','errorMsg','para');
% Close Screen, we're done:
sca;

catch %#ok<CTCH>
    % catch error: This is executed in case something goes wrong in the
    % 'try' part due to programming error etc.:
    % Do same cleanup as at the end of a regular session...
    sca;
    ShowCursor;
    fclose('all');
    Priority(0);
    % Output the error message that describes the error:
    psychrethrow(psychlasterror);
end