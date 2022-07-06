%%% From 'setpath_MemOrder.m' %%%

% Task folder
%cd 'C:\Experiments\svnwork\consortium\psychophysics\MemOrder\Task_GUI'
%basepath='C:\Experiments\svnwork\consortium\';
cd 'C:\Users\darwinm\Documents\SVN_Microwire\code\psychophysics\MemSeg\Task_GUI';
basepath = 'C:\Users\darwinm\Documents\SVN_Microwire\code\';
path(path,basepath);

% Processing of raw continuous data
path(path,[basepath 'psychophysics']);
path(path,[basepath 'psychophysics\helpers']);
%path(path,[basepath 'psychophysics\stimFiles']); %MLD- only has code for new/old in SVN folder

% Assumes 64bit windows. If not, change to 'io32'
path(path,[basepath '3rdParty\io64']);

%Add cPod path
path(path,[basepath 'psychophysics\cpod']);

%Add task GUI paths 
path(path, [basepath 'psychophysics\MemOrder\Task_GUI\helper_files']);
%path(path, 'C:\Experiments\svnwork\consortium\psychophysics\MemOrder\Task_GUI\E00_InstruText');
path(path, 'C:\Users\darwinm\Documents\SVN_Microwire\code\psychophysics\MemOrder\Task_GUI\E00_InstruText');

% Back to task folder
%cd 'C:\Experiments\svnwork\consortium\psychophysics\MemOrder\Task_GUI'
cd 'C:\Users\darwinm\Documents\SVN_Microwire\code\psychophysics\MemOrder\Task_GUI';

%%% From 'A00_ | B00_ | C00_MemOrder_Encoding_cpod' %%%

try
%--------------------------------------------------------------------------
%                       PTB setup (Same for A00, B00, and C00)
%--------------------------------------------------------------------------
%clear all
%clc
sca; 
commandwindow; 
% config_io
HideCursor;
% PsychDefaultSetup(2);
% Screen('Preference','SkipSyncTests', 2); % skip screen test AGPS changed
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
[window, windowRect] = PsychImaging('OpenWindow', screenid, gray, para.windowRect_define); % rezied window
% [window, windowRect] = PsychImaging('OpenWindow', screenid, gray); % full screen
% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA','GL_ONE_MINUS_SRC_ALPHA');

%%%%%%%%%%%%%%%%%%%% Scaled Text Presentation Setup %%%%%%%%%%%%%%%%%%%%%%%
% Get size of the on screen window
screenXpixels  = windowRect(3);
screenYpixels  = windowRect(4);
% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);
% Load example image. All the images are the same size
theImg=imread(fullfile(pwd,'\E00_InstruText\A01_EncodingInstruText.png'));
% Get the size of the image
[orig_width, orig_height, ~]=size(theImg); 
% Define the fraction of scale, this is for Y axis match between img and screen
heightScaler = 0.8; % 80% height of the screen y axis
imgHeight = screenYpixels * heightScaler;
imgWidth = imgHeight * orig_height / orig_width;
theRect = [0 0 imgWidth imgHeight];
dstRect = CenterRectOnPointd(theRect, screenXpixels/2, screenYpixels/2);

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
itiTimeSecs = 1;  

%%%%%%%%%%%%%%%%%%%% Scaled Movie Presentation Setup %%%%%%%%%%%%%%%%%%%%%%
% FIXME later

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
para.Ntrial = 90; % the total number of trials 
%%% TESTING: four numbers for now, change for real experiment
ques_gap = ones(1,para.Ntrial);
%ques_gap = [5*ones(1,5) 6*ones(1,4) 7*ones(1,5)]; % Interval between nearby random questions
% Seed for the random number generator
rng('shuffle','twister'); 
% Randomize the question gap
ques_gap = ques_gap(randperm(length(ques_gap)));
% Assign questions to specific trial  
ques_indx = cumsum(ques_gap); 
% clip list folder
para.clipDIR = fullfile(pwd,'\A02_Clips\');

%%%%%%%%%%%%%%%%%%%% Experiement Keyboard SetUp %%%%%%%%%%%%%%%%%%%%%%%%%%%
spaceKey = KbName('space');
escapeKey = KbName('Esc');
NoSureKey = KbName('s');
NoLessSureKey = KbName('d'); 
NoVeryUnsureKey = KbName('f'); 
YesVeryUnsureKey = KbName('j'); 
YesLessSureKey = KbName('k');
YesSureKey = KbName('l'); 

%%%%%%%%%%%%%%%%%%%% Experiement Parameters SetUp %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
% check for existing result file to prevent accidentally overwriting
% files from a previous subject/session (except for subject numbers > 99):
para.output_filename = fullfile(pwd,['\D00_Logs\',para.sub_id,'_encoding.mat']);
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
fileLabel = [para.sub_id, '_encoding_eye_'];
[para.eyefidLog, para.eyefnameLog, para.eyeTimestampStr] = openLogfile(fileLabel,[pwd,'\D00_Logs\eyeLogs\']);
para.eyedata_filename = [pwd,'\D00_Logs\', fileLabel, para.eyeTimestampStr,'.mat'];
if para.eyelink_flag % set up eyelink for eye tracking
   dummymode = 0;       % set to 1 to initialize in dummymode 
   retCode = eyeLink_setup_PTB3(window, dummymode, ['MemSeg_encoding_eye' para.eyeTimestampStr(end-5:end)]);   
   if retCode % success connected
      Eyelink('Message', para.eyefnameLog);
   else
      Priority(0);
      fprintf('Experiment aborted due to the failure of eye link setup');
      ShowCursor; sca; return
   end
end

% Need to send TTL pulses?
para.TTL_flag = 1;
if para.TTL_flag
   para.TTL.task_onset = 61;
   para.TTL.fix_cross = 11;
   para.TTL.clip_onset = 1;
   para.TTL.clip_offset = 2;
   para.TTL.probe = 3;
   para.TTL.response = 4;
   para.TTL.task_offset = 60; 
   para.TTL.afterTTLDelay=0;  %in secs, wait till reset of TTL to 0
   % open cpod for preparation
   openTTL_cpod('COM4');
end

recordingDate = clock;
respMat= []; % Initialize the variable to store log information
% 1-CrossStart; 2-CrossEnd; 3-ClipStart; 4-ClipEnd; 5-ClipName; 
% 6-QuesStart; 7-QuesName; 8-respValue; 9-respTime; 
errorMsg = []; % Intialize the variable to store error messages

%--------------------------------------------------------------------------
%                        Load Task Instruction
%--------------------------------------------------------------------------
% Restrict Key to escape and space
RestrictKeysForKbCheck([spaceKey escapeKey]);
InstruImg=imread(fullfile(pwd,'\E00_InstruText\A01_EncodingInstruText.png'));
% make texture image out of image matrix 'imdata'
InstruTex=Screen('MakeTexture', window, InstruImg);
% Draw texture image to backbuffer. 
Screen('DrawTexture', window, InstruTex,[], dstRect); % proportional display
% Show instructions on screen at next possible display refresh cycle
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

%--------------------------------------------------------------------------
%                        Load Practice Trial
%--------------------------------------------------------------------------
eg_file = {'A02_Example_1','A02_Example_2', 'ready'};
egs_n = length(eg_file);
for n_eg = 1:egs_n
    egImg = imread([pwd,'\E00_InstruText\',eg_file{n_eg}, '.png']);
    egTex = Screen('MakeTexture', window, egImg);
    Screen('DrawTexture', window, egTex,[], dstRect); % proportional display
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

%%%%%%%%%%%%%%%%%%%%%%%%%% Scan clip folder %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clipList = dir([para.clipDIR,'\*.mp4']);
para.clipNum = length(clipList);
% Check whether video clips number matches with trial number
if para.clipNum ~= para.Ntrial
   Priority(0);
   errorMsg = {'Clip number and trial number do not match'};
   ShowCursor;
   save(para.output_filename,'recordingDate','respMat','errorMsg','para'); sca;
end
%%%%%%%%%%%%%%%%%%%%%%%%%% Single trial SetUp %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Restrict Key to escape, left and right
RestrictKeysForKbCheck([escapeKey NoSureKey NoLessSureKey NoVeryUnsureKey ... 
                        YesVeryUnsureKey YesLessSureKey YesSureKey]);
trial_indx = 0; % count the trial number
for trial_n = randperm(para.clipNum,para.clipNum)
    %inputemu({'key_normal','H\BACKSPACE'});
    
    trial_indx = trial_indx + 1;
    %%%%%%%%%%%%%%%% Fixation period (~1s)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    Screen('DrawLines', window, fixCoords, lineWidthPix, white, [xCenter yCenter]);
    [~, startrt] = Screen('Flip', window);
    % Send a TTL pulse to mark the onset of fixation cross and save this baseline onset in the respMat
    if para.TTL_flag
       % sendTTLsEYElink(para.TTL.fix_cross,0,para.eyefidLog,para.TTL.afterTTLDelay,para.eyelink_flag);
       sendTTL_cpod(para.TTL.fix_cross);
    end
    respMat(trial_indx).CrossStart = double(startrt);
    % add jitter to fixation cross
    para.itiTimeSecs(trial_indx) = itiTimeSecs - (randperm(1000,1)/1000-0.5);
    % Show fixation cross until the ITI duration elapsed or 
    % the 'escapeKey' is pressed to quit the experiment
    while (GetSecs - startrt)<= para.itiTimeSecs(trial_indx)
         [keyIsDown,secs, keyCode] = KbCheck;
         if keyCode(escapeKey)
            Priority(0);
            errorMsg = {['user pressed ESC, quit task during the encoding at the fixation cross of trial ', num2str(trial_indx)]};
            ShowCursor; 
            save(para.output_filename,'recordingDate','respMat','errorMsg','para'); sca; return;
         end
        % Wait 1 ms before checking the keyboard again to prevent
        % overload of the machine at elevated Priority():
        WaitSecs(0.001);
    end
    Screen('Flip', window);
    respMat(trial_indx).CrossEnd = double(GetSecs);
    WaitSecs(0.01);

    %%%%%%%%%%%%%%%%% Clip display (~8s) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    clipfile = [clipList(trial_n).folder,'\',clipList(trial_n).name];
    % Wait until user releases keys on keyboard: 
    KbReleaseWait;
    % Open movie file:
    movie = Screen('OpenMovie', window, clipfile); % FIXME later with scaled display
    % Start playback engine:
    Screen('PlayMovie', movie, 1);
    % send a TTL pulse to mark the onset of movie display and save this
    % encoding onset in the respMat
    if para.TTL_flag
       % sendTTLsEYElink(para.TTL.clip_onset,trial_indx,para.eyefidLog,para.TTL.afterTTLDelay,para.eyelink_flag);
        sendTTL_cpod(para.TTL.clip_onset);
    end
    respMat(trial_indx).ClipStart = double(GetSecs);
    respMat(trial_indx).ClipName = clipList(trial_n).name;
    % Playback loop: Runs until end of movie or keypress: 
    while 1
        [keyIsDown,secs, keyCode] = KbCheck;
        if keyCode(escapeKey)
           Priority(0);
           errorMsg = {['user pressed ESC, quit task during the encoding at the clip display of trial ', num2str(trial_indx)]};
           ShowCursor; 
           save(para.output_filename,'recordingDate','respMat','errorMsg','para');sca;return;
        end
        % Wait for next movie frame, retrieve texture handle to it
        tex = Screen('GetMovieImage', window, movie);
        % Valid texture returned? A negative value means end of movie reached:
        if tex <= 0
            % We're done, break out of loop:
            break;
        end
        % Draw the new texture immediately to screen:
        Screen('DrawTexture', window, tex); 
        % Update display:
        Screen('Flip', window);
        % Release texture:
        Screen('Close', tex);   
    end
    % Stop playback: 
    Screen('PlayMovie', movie, 0); 
    % Close movie:
    Screen('CloseMovie', movie);  
    % Move over to another trial, gray background
    WaitSecs(0.01);
    Screen('Flip', window);
    % send a TTL pulse to mark the offset of the movie display and save
%     % this encoding offset in the respMat
    if para.TTL_flag
    %    sendTTLsEYElink(para.TTL.clip_offset,trial_indx,para.eyefidLog,para.TTL.afterTTLDelay,para.eyelink_flag);
        sendTTL_cpod(para.TTL.clip_offset);
    end
    respMat(trial_indx).ClipEnd = double(GetSecs);

    %%%%%%%%%%%%%%%%% Random question (self-paced) %%%%%%%%%%%%%%%%%%%%%%%%
    if sum(ques_indx == trial_indx)
       ques_file_indx = randperm(4,1);
       QuesImg=imread(fullfile(pwd,['\E00_InstruText\','A03_QuesText_' num2str(ques_file_indx) '.png']));
       % make texture image out of image matrix 'imdata' 
       QuesTex=Screen('MakeTexture', window, QuesImg);
       % Draw texture image to backbuffer.
       Screen('DrawTexture', window, QuesTex,[],dstRect); % proportional display, no rotation
       % Show question on screen at next possible display refresh cycle,
       % and record question onset time in 'startrt': 
       Screen('Flip', window);
       % send a TTL pulse to mark the onset of question and save this onset in the respMat
       if para.TTL_flag
       %   sendTTLsEYElink(para.TTL.probe,trial_indx,para.eyefidLog,para.TTL.afterTTLDelay,para.eyelink_flag);
           sendTTL_cpod(para.TTL.probe);
       end
       respMat(trial_indx).QuesStart = double(GetSecs);
       respMat(trial_indx).QuesName = ['A03_QuesText_' num2str(ques_file_indx) '.png'];
       % start Response screen (not a loop! - wait for resp), KbPressWait
       % is not used here because there is 5ms delay
       if para.cedrus_flag
          CedrusResponseBox('FlushEvents', handle); % clear up the previous button press
          CedrusResponseBox('ResetRTTimer', handle);
          % evt.button = 0;
          while 1
%           evt = CedrusResponseBox('WaitButtonPress', handle);
            [keyIsDown,secs, keyCode] = KbCheck;
            if keyCode(escapeKey)
                Priority(0);
                errorMsg = {['user pressed ESC, quit task during the encoding at the random question of trial ', num2str(trial_indx)]};
                ShowCursor;
                save(para.output_filename,'recordingDate','respMat','errorMsg','para'); sca; return
            end
            evt = CedrusResponseBox('GetButtons', handle);
            if ~isempty(evt) && evt.button ~= 8
                RT = evt.rawtime;
                % send a TTL pulse to mark the reponse time and save this response time to the respMat
                if para.TTL_flag
                   % sendTTLsEYElink(para.TTL.response,[RT,evt.button],para.eyefidLog,para.TTL.afterTTLDelay,para.eyelink_flag);
                    sendTTL_cpod(para.TTL.response);
                end
                respMat(trial_indx).respValue = evt.button;
                break;
            end
          end
          evt = [];
          CedrusResponseBox('FlushEvents', handle);
       else
           respToBeMade = true; 
           while respToBeMade
                % Now we wait for a keyboard button signaling the observers response.
                % You can also press escape if you want to exit the program                  
                [keyIsDown,secs, keyCode] = KbCheck;
                if keyCode(escapeKey)
                    Priority(0);
                    errorMsg = {['user pressed ESC, quit task during the encoding at the random question of trial ', num2str(trial_indx)]};
                    ShowCursor;
                    save(para.output_filename,'recordingDate','respMat','errorMsg','para'); sca; return
                elseif keyCode(NoSureKey)
                    respMat(trial_indx).respValue = -3; % NO, Sure
                    respToBeMade = false;
                elseif keyCode(NoLessSureKey)
                    respMat(trial_indx).respValue = -2; % NO, Less Sure
                    respToBeMade = false;
                 elseif keyCode(NoVeryUnsureKey)
                    respMat(trial_indx).respValue = -1; % NO, Very Unsure
                    respToBeMade = false; 
                 elseif keyCode(YesVeryUnsureKey)
                    respMat(trial_indx).respValue = 1; % YES, Very Unsure
                    respToBeMade = false;  
                 elseif keyCode(YesLessSureKey)
                    respMat(trial_indx).respValue = 2; % YES, Less Sure
                    respToBeMade = false;
                 elseif keyCode(YesSureKey)
                    respMat(trial_indx).respValue = 3; % YES, Sure
                    respToBeMade = false;
                end   
           end
           respMat(trial_indx).respTime = double(secs); %get time of response
       end
        
    end  
end

% Send a TTL pulse to mark the end of the task
if para.TTL_flag
%  sendTTLsEYElink(para.TTL.task_offset,trial_indx,para.eyefidLog,para.TTL.afterTTLDelay,para.eyelink_flag);
   sendTTL_cpod(para.TTL.task_offset);
   pause(0.5);
   % close cpod for future use
   closeTTL_cpod('COM4');
end

%%%%%%%%%%%%%%%%%%%%%%%%%% Save Output File %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
save(para.output_filename,'recordingDate','respMat','errorMsg','para');
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

