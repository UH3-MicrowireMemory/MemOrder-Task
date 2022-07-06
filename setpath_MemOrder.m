
%adjust basepath variable and then run this as the first file before
%running a task. Delete everything from the path that does not belong to

%

% %% Huxley from Cedars
% 
% % Setup Pyschtoolbox
% cd 'C:\toolbox\psychtoolbox\'
% SetupPsychtoolbox
% 
% % comeback to the task folder
% cd 'c:\svnwork\consortium\code\psychophysics\MemSeg\Task_GUI'
% basepath='c:\svnwork\consortium\code\';
% path(path,basepath);
% 
% %processing of raw continous data
% path(path,[basepath 'psychophysics']);
% path(path,[basepath 'psychophysics\helpers']);
% path(path,[basepath 'psychophysics\stimFiles']);
% 
% %Assumes 64bit windows. If not, change to 'io32'
% path(path,[basepath '3rdParty\io64']);
% 
% %Add task GUI paths 
% path(path, [basepath 'psychophysics\MemSeg\Task_GUI']);
% path(path, 'C:\svnwork\consortium\code\psychophysics\MemSeg\Task_GUI\E00_InstruText');

%% Klab Computer
% restore all the MATLAB path to default
restoredefaultpath

% Setup Pyschtoolbox
cd 'C:\toolbox\psychtoolbox\'
SetupPsychtoolbox

% comeback to the task folder
cd 'C:\Experiments\svnwork\consortium\psychophysics\MemOrder\Task_GUI'
basepath='C:\Experiments\svnwork\consortium\';
path(path,basepath);

%processing of raw continous data
path(path,[basepath 'psychophysics']);
path(path,[basepath 'psychophysics\helpers']);
path(path,[basepath 'psychophysics\stimFiles']);

%Assumes 64bit windows. If not, change to 'io32'
path(path,[basepath '3rdParty\io64']);

%Add cPod path
path(path,[basepath 'psychophysics\cpod']);

%Add task GUI paths 
path(path, [basepath 'psychophysics\MemOrder\Task_GUI\helper_files']);
path(path, 'C:\Experiments\svnwork\consortium\psychophysics\MemOrder\Task_GUI\E00_InstruText');

%Back to task folder
cd 'C:\Experiments\svnwork\consortium\psychophysics\MemOrder\Task_GUI'

%% Set resolution to 1920 x 1080





