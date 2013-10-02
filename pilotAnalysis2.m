function pilotAnalysis2(specFileName, groupNum, subjName, testName, recordTime, saveName, varargin)
%e.g. pilotAnalysis_fMRI_SEQPDS_011413('fmria', 1, 'SEQ01C03_fMRI', 'test1', 'testfoo')
%group #: SEQ<group#><C/P><subjNum>
%for SEQPDS: test1 - fmria, test2 - fmrib, etc.

%expects folders with stim, specfiles, siand subject's utterances to be at
%same level as script

%OUTPUT: saves struct 1-3 items into subject folder.  all have accuracy, speaking conditions
%have accuracy and fluency, items where onset and/or offset measured have
%accuracy, fluency, and times

%...cond: 1 = baseline, 2 = learned, illegal, 3 = legal, 4 = novel, illegal
% ACCURACY
%     case 'accurate' = 1;
%     case 'silence' = 2;
%     case 'error_use' = 3;
%     case 'error_unrecog' = 4;
%     case 'error_unfinish' = 5;
% 
% FLUENCY
%     case 'fluent' = 1
%     case 'st_rep' = 2
%     case 'st_pro' = 3
%     case 'st_block' = 4;
%     case 'st_clust' = 5;

global buttonVals
global done
global accuracyLowConfid
global fluencyLowConfid
global bStarter

if nargin < 2
    error('Must provide required input parameters specFileName, subjName, and testName');
end

bFilt = 1;
if nargin > 6
    if isequal(varargin{1}, 'noFilter')
        bFilt = 0;
    end
end

audioMode = 'soundsc';
if ~isempty(fsic(varargin, 'audioplayer'))
    audioMode = 'audioplayer';
elseif ~isempty(fsic(varargin, 'wavplay'))
    audioMode = 'wavplay';
end

screen_pts = get(0,'ScreenSize');
pos = [screen_pts(1) screen_pts(2) screen_pts(3) screen_pts(4) - 45];

specFile = strcat('specFiles\',specFileName,'.txt');
[stimNums waits] = textread(specFile,'%d %d');
%stim to be presented, file name under which recorded is saved, ISI
clear waits;

data = {};
% recordTime = 3;
done = 0;

numTrials = size(stimNums,1);
stimList = textread('stim\StimNumList.txt','%s');
% for SEQ03005 since practiced as 1, but tested as 4
%groupListLearn = textread(strcat('specFiles\group1_learn.txt'),'%u');
groupListLearn = textread(strcat('specFiles\group',num2str(groupNum),'_learn.txt'),'%u');
groupListTest = textread(strcat('specFiles\group',num2str(groupNum),'_test.txt'),'%u');

%with wiener
%SEQ03001
OnDur = 5;    % this value is in ms and controls how long the intensity should exceed the threshold to be considered an onset
onThresh = -30;   % onset threshold
OffDur = 80;
offThresh = -35;

count = 1;
stimOn = 0;
speechOn = 0;
speechOff = 0;
iter = 1;
term = 0;

matFileName = strcat(subjName,'\trials_',testName,'_',saveName);
if ~isequal(matFileName(end - 3 : end), '.mat')
    matFileName = [matFileName, '.mat'];
end

%% Process optinal single trial selection
if ~isempty(fsic(varargin, 'redo')) || ~isempty(fsic(varargin, 'redoCatOnly'))
    if ~isempty(fsic(varargin, 'redo')) && ~isempty(fsic(varargin, 'redoCatOnly'))
        error('Options redo and redoCatOnly should not be used together');
    end
    
    if ~isempty(fsic(varargin, 'redo'))
        redoTrialN = varargin{fsic(varargin, 'redo') + 1};
        
        bRedoCatOnly = 0;
    else
        redoTrialN = varargin{fsic(varargin, 'redoCatOnly') + 1};
        
        bRedoCatOnly = 1;
    end
        
    if ~isfile(matFileName)
        error('Cannot find saved data file %s. Cannot proceed with mode redo.\n', matFileName);
    end
    load(matFileName);
    
    a_numTrials = redoTrialN;
else
    redoTrialN = [];
    a_numTrials = 1 : numTrials;
end

%% Build data list 
if ~isfile(matFileName)
    bNew = 1;
else
%     a = input(sprintf('Found existing .mat file: %s. Resume data processing? (0/1): ', matFileName));
%     
%     if a == 1
%         bNew = 0;
%     elseif a == 0
%         a = input('Are you sure that you want to overwrite the existing data processing results? (y/n): ', 's');
%         if isequal(a, 'y')
%             bNew = 1;
%         elseif isequal(a, 'n')
%             bNew = 0;
%         else
%             error('Unrecognized input: %s', a);
%         end
%         
%         bNew = 1;
%     else
%         error('Unrecognized input: %d', a);
%     end
    fprintf('Found existing .mat file: %s. Resuming.\n', matFileName)
    bNew = 0;
end
    
if length(testName) > 4 && isequal(testName(1 : 4), 'test') %--- test sessions ---%
    tType = 'test';
elseif length(testName) > 4 && isequal(testName(1 : 4), 'prac') %--- prac sessions ---%
    tType = 'prac';
else
    error('Unrecognized testName: ', testName);
end

if bNew
    data = {};
    for ii = a_numTrials
        if stimNums(ii) <= 0
            continue;
        end

        if isequal(tType, 'test') %--- test sessions ---%
            cond = 1;

            stim = groupListTest(stimNums(ii));
            stimWord = stimList{stim};
            groupNum = groupListTest(stimNums(ii));

            if groupNum <= 24
                cond = 3;
            else
                learned = 0;
                jj = 16;
                while (jj <= 30) && (groupNum >= groupListLearn(jj)) && (learned == 0)
                    if groupNum == groupListLearn(jj)
                        learned = 1;
                        %disp('**learned**');
                    else
                        jj = jj + 1;
                    end
                end

                if learned == 1
                    cond = 2;

                else
                    cond = 4;
                end
            end

            data{ii}.cond = cond;
            data{ii}.stim = stim;
            data{ii}.stimWord = stimWord;

        elseif isequal(tType, 'prac') %--- prac sessions ---%

            cond = 1;
            stim = stimNums(ii);
            stimWord = char(stimList(groupListLearn(stimNums(ii))));

            if stim <15
                cond = 1;
            else
                cond = 2;
            end

            data{ii}.cond = cond;
            data{ii}.stim = stim;
            data{ii}.stimWord = stimWord;
        end

        data{ii}.recordFile = fullfile('.', subjName, ...
                                       sprintf('%s_%d_%s.wav', testName, ii, data{ii}.stimWord));

        %-- Initialize data --%
        data{ii}.accuracy = NaN;
        data{ii}.fluency = NaN;
        data{ii}.accuracyLowConfid = NaN;
        data{ii}.fluencyLowConfid = NaN;
        data{ii}.bStarter = NaN;
        data{ii}.times = [];
        data{ii}.starterOnset = NaN;

        data{ii}.status = 0;

        if ~isfile(data{ii}.recordFile) % Check the existence of osound recording file
            error('Cannot find wav file for trial #%d: %s', ...
                  ii, data{ii}.recordFile)
        end

    end
    
    save(matFileName, 'data');
    assert(exist(matFileName) == 2);
else
    load(matFileName);
    assert(exist('data', 'var') == 1);
end

%% Create trial list window
uihdls = mkTrialList(data, subjName, testName);
uihdls.matFileName = matFileName;
uihdls.bFilt = bFilt;
uihdls.audioMode = audioMode;
uihdls.recordTime = recordTime;
uihdls.pos = pos;

% uihdls.OnDur = OnDur;
% uihdls.onThresh = onThresh;
% uihdls.OffDur = OffDur;
% uihdls.offThresh = offThresh;



% OnDur = 5;    % this value is in ms and controls how long the intensity should exceed the threshold to be considered an onset
% onThresh = -30;   % onset threshold
% OffDur = 80;
% offThresh = -35;
% 
% count = 1;
% stimOn = 0;
% speechOn = 0;
% speechOff = 0;
% iter = 1;
% term = 0;

set(uihdls.btnProc, 'Callback', {@cbkProcSingleTrial, uihdls});

return

%% Main loop
for ii = a_numTrials
    
end



fprintf(1, 'Results saved to file %s\n', matFileName);
