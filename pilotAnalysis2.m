function pilotAnalysis_fMRI_SEQPDS_011413(specFileName, groupNum, subjName, testName, recordTime, saveName)
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

if nargin < 2
    error('Must provide required input parameters specFileName, subjName, and testName');
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

numTrials = size(stimNums,1)
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


for ii = 1:numTrials
    disp(ii);
    %open next elicited psuedoword
    
    if stimNums(ii)> 0
        cond = 1;
        stim = char(stimList(groupListTest(stimNums(ii))));
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
        
        %counts(1,groupNum) = counts(1,groupNum) + 1;
        trialNumString = num2str(ii);
        recordFile = strcat(subjName,'\',testName,'_',trialNumString,'_',stim);
        recordFile
        [y, fs] = wavread(recordFile);
        soundsc(y(1:round(recordTime*fs)), fs);
        y_orig = y;
        
        %GUI to classify--------------------
        SEQ_GUI(y, fs, recordTime);
        uiwait;
        
%         buttonVals{1}
%         buttonVals{2}
        
        data{ii}.accuracy = buttonVals{1};
        data{ii}.fluency = buttonVals{2};
        
        calc = 0;
        calc_half = 0;
        
        %calc onset and offset
        if (data{ii}.accuracy == 1) && (data{ii}.fluency == 1) %fluent && accurate
            calc = 1;
        elseif (data{ii}.accuracy == 1) && (data{ii}.fluency > 1) %disfluent
            calc = 1;
        elseif (data{ii}.fluency == 1) && (data{ii}.accuracy == 3) %fluent & usable error
            calc = 1;
        elseif (data{ii}.fluency == 1) && (data{ii}.accuracy == 5)
            calc_half = 1;
        end
            
            
        %calc onset and offset-----------------------------------------
        if calc == 1
            
            index2 = 1;
            while index2 == 1
                y = WienerScalart96(y,fs); %apply filter
                
                flagEndFound = 0;
                winSize = round(fs * .0015);
                Incr = round(fs * .001);
                time = 0:1/fs:(length(y)-1)/fs;
                noWins = length(winSize:Incr:(length(y)-winSize));
                iter = 1;
                I = [];
                tm = [];
                BegWin = 1;
                EndWin = BegWin + winSize;
                
                while EndWin < length(y) %ii = 1:noWins
                    dat = detrend(y(BegWin:EndWin, 1), 0);
                    dat=convn(dat,[1;-.95]);
                    dat = detrend(dat, 0);
                    int = sum(dat.^2);
                    I(iter) = 20*log10(int/.0015); %000015
                    tm(iter) = time(BegWin);
                    if iter > OnDur && speechOn == 0 && length(find(I(iter-OnDur:iter) > onThresh)) == length(I(iter-OnDur:iter)) && tm(iter-OnDur) > .09
                        disp('***');
                        speechOn = 1;
                        speechOnTime = tm(iter-OnDur);
                        endTm = round(speechOnTime*fs);
                        EndWin = BegWin + round(fs * .010);
                    elseif iter > OffDur && speechOn == 1 && isempty(find(I(iter-OffDur:iter) > offThresh)) == 1 && tm(iter-OffDur) - speechOnTime > .40
                        disp('###');
                        speechOff = 1;
                        speechOffTime = tm(iter-OffDur);
                        offTm = round(speechOffTime*fs);
                        winSize = round(fs * .0015);
                    end
                    if speechOn == 1 && speechOff == 1
                        figure('Position', pos);
                        %TOP PLOT-----------------------------------
                        subplot(3, 1, 1), plot(time, detrend(y, 0), 'k'); hold on;
                        %title(['Token is ' char(StimList(i)) '  < press spacebar to continue >']);
                        axis tight;
                        ax = axis;
                        line([speechOnTime speechOnTime], [ax(3) ax(4)], 'Color', 'k', 'LineWidth', 2.0);
                        line([speechOffTime speechOffTime], [ax(3) ax(4)], 'Color', 'k', 'LineWidth', 2.0);
                        %MIDDLE PLOT-----------------------------------
                        subplot(3, 1, 2), plot(tm, I, 'k'); hold on;
                        bx = axis;
                        line([speechOnTime speechOnTime], [bx(3) bx(4)], 'Color', 'k', 'LineWidth', 2.0);
                        line([speechOffTime speechOffTime], [bx(3) bx(4)], 'Color', 'k', 'LineWidth', 2.0);
                        axis([ax(1) ax(2) bx(3) bx(4)]);
                        %BOTTOM PLOT-----------------------------------
                        subplot(3, 1, 3); hold on;
                        nwin = 512; % samples
                        noverlap = 256; %samples
                        nfft = 512; %samples
                        spectrogram(y_orig, nwin, noverlap, nfft, fs, 'yaxis');
                        ylim([0 4000]);
                        
                        accept = menu('Select', 'Take', 'Edit');
                        switch accept
                            case 1
                                flagEndFound = 1;
                                data{ii}.times = [ii speechOnTime speechOffTime-speechOnTime];
                                
                            case 2
                                flagEndFound = 1;
                                
                                
                                %input times
                                strResp_on = input('Enter the onset time (in secs) and type Enter\n', 's');
                                strResp_end = input('Enter the offset time (in secs) and type Enter\n', 's');
                                numResp_on = str2double(strResp_on);
                                numResp_end = str2double(strResp_end);
                                
                                data{ii}.times = [ii numResp_on numResp_end];
                        end
                        %pause;
                        close;
                        %sigmat.signal = detrend(y(tgTm:end),0);
                        count = count + 1;
                        stimOn = 0;
                        speechOn = 0;
                        speechOff = 0;
                        %SaveFile = [FileName '.mat'];
                        %save(SaveFile, 'sigmat');
                        BegWin = BegWin + round(fs*2.0);
                        EndWin = EndWin + round(fs*2.0);
                        iter = 0;
                        I = [];
                        tm = [];
                        break;
                    end
                    BegWin = BegWin + Incr;
                    EndWin = EndWin + Incr;
                    iter = iter + 1;
                end
                
                if flagEndFound == 0
                    disp('*****');
                    figure('Position', pos);
                    %TOP PLOT-----------------------------------
                    subplot(3, 1, 1), plot(time, detrend(y, 0), 'k'); hold on;
                    %title(['Token is ' char(StimList(i)) '  < press spacebar to continue >']);
                    axis tight;
                    ax = axis;
                    %MIDDLE PLOT-----------------------------------
                    subplot(3, 1, 2), plot(tm, I, 'k'); hold on;
                    bx = axis;
                    %BOTTOM PLOT-----------------------------------
                    subplot(3, 1, 3); hold on;
                    nwin = 512; % samples
                    noverlap = 256; %samples
                    nfft = 512; %samples
                    spectrogram(y_orig, nwin, noverlap, nfft, fs, 'yaxis');
                    ylim([0 4000]);
                    
                    
                    %input times
                    strResp_on = input('What is the onset time (in secs)\n', 's');
                    strResp_end = input('What is the offset time (in secs)\n', 's');
                    numResp_on = str2double(strResp_on);
                    numResp_end = str2double(strResp_end);
                    
                    data{ii}.times = [ii numResp_on numResp_end];
                end
                index2 = 0;
            end
            
            %calc onset ONLY------------------------------------------
        elseif calc_half == 1
            
            y = WienerScalart96(y,fs); %apply filter
            
            flagEndFound = 0;
            winSize = round(fs * .0015);
            Incr = round(fs * .001);
            time = 0:1/fs:(length(y)-1)/fs;
            noWins = length(winSize:Incr:(length(y)-winSize));
            iter = 1;
            I = [];
            tm = [];
            BegWin = 1;
            EndWin = BegWin + winSize;
            
            while EndWin < length(y) %ii = 1:noWins
                dat = detrend(y(BegWin:EndWin, 1), 0);
                dat=convn(dat,[1;-.95]);
                dat = detrend(dat, 0);
                int = sum(dat.^2);
                I(iter) = 20*log10(int/.0015); %000015
                tm(iter) = time(BegWin);
                if iter > OnDur && speechOn == 0 && length(find(I(iter-OnDur:iter) > onThresh)) == length(I(iter-OnDur:iter)) && tm(iter-OnDur) > .09
                    disp('***');
                    speechOn = 1;
                    speechOnTime = tm(iter-OnDur);
                    endTm = round(speechOnTime*fs);
                    EndWin = BegWin + round(fs * .010);
                elseif iter > OffDur && speechOn == 1 && isempty(find(I(iter-OffDur:iter) > offThresh)) == 1 && tm(iter-OffDur) - speechOnTime > .40
                    disp('###');
                    speechOff = 1;
                    speechOffTime = tm(iter-OffDur);
                    offTm = round(speechOffTime*fs);
                    winSize = round(fs * .0015);
                end
                if speechOn == 1 %&& speechOff == 1
                    figure('Position', pos);
                    %TOP PLOT-----------------------------------
                    subplot(3, 1, 1), plot(time, detrend(y, 0), 'k'); hold on;
                    %title(['Token is ' char(StimList(i)) '  < press spacebar to continue >']);
                    axis tight;
                    ax = axis;
                    line([speechOnTime speechOnTime], [ax(3) ax(4)], 'Color', 'k', 'LineWidth', 2.0);
                    %                          line([speechOffTime speechOffTime], [ax(3) ax(4)], 'Color', 'k', 'LineWidth', 2.0);
                    %MIDDLE PLOT-----------------------------------
                    subplot(3, 1, 2), plot(tm, I, 'k'); hold on;
                    bx = axis;
                    line([speechOnTime speechOnTime], [bx(3) bx(4)], 'Color', 'k', 'LineWidth', 2.0);
                    %                          line([speechOffTime speechOffTime], [bx(3) bx(4)], 'Color', 'k', 'LineWidth', 2.0);
                    axis([ax(1) ax(2) bx(3) bx(4)]);
                    %BOTTOM PLOT-----------------------------------
                    subplot(3, 1, 3); hold on;
                    nwin = 512; % samples
                    noverlap = 256; %samples
                    nfft = 512; %samples
                    spectrogram(y_orig, nwin, noverlap, nfft, fs, 'yaxis');
                    ylim([0 4000]);
                    
                    accept = menu('Select', 'Take', 'Edit');
                    switch accept
                        case 1
                            flagEndFound = 1;
                            data{ii}.times = [ii speechOnTime -1];
                        case 2
                            flagEndFound = 1;
                            
                            %input times
                            strResp_on = input('Enter the onset time (in secs) and type Enter\n', 's');
                            numResp_on = str2double(strResp_on);
                            
                            data{ii}.times = [ii numResp_on -1];
                    end
                    %pause;
                    close;
                    %sigmat.signal = detrend(y(tgTm:end),0);
                    count = count + 1;
                    stimOn = 0;
                    speechOn = 0;
                    speechOff = 0;
                    %SaveFile = [FileName '.mat'];
                    %save(SaveFile, 'sigmat');
                    BegWin = BegWin + round(fs*2.0);
                    EndWin = EndWin + round(fs*2.0);
                    iter = 0;
                    I = [];
                    tm = [];
                    break;
                end
                BegWin = BegWin + Incr;
                EndWin = EndWin + Incr;
                iter = iter + 1;
            end
            
            if flagEndFound == 0
                figure('Position', pos);
                %TOP PLOT-----------------------------------
                subplot(3, 1, 1), plot(time, detrend(y, 0), 'k'); hold on;
                %title(['Token is ' char(StimList(i)) '  < press spacebar to continue >']);
                axis tight;
                ax = axis;
                %MIDDLE PLOT-----------------------------------
                subplot(3, 1, 2), plot(tm, I, 'k'); hold on;
                bx = axis;
                %BOTTOM PLOT-----------------------------------
                subplot(3, 1, 3); hold on;
                nwin = 512; % samples
                noverlap = 256; %samples
                nfft = 512; %samples
                spectrogram(y_orig, nwin, noverlap, nfft, fs, 'yaxis');
                ylim([0 4000]);
                
                
                %input times
                strResp_on = input('What is the onset time (in secs)\n', 's');
                %                      strResp_end = input('What is the offset time (in secs)\n', 's');
                numResp_on = str2double(strResp_on);
                %                      numResp_end = str2double(strResp_end);
                
                data{ii}.times = [ii numResp_on -1];
            end
            index2 = 0;
        end
    end
    
    speechOn = 0;
    speechOff = 0;
    iter = 0;
    I = [];
    tm = [];
end


matFileName = strcat(subjName,'\trials_',testName,'_',saveName);
save(matFileName, 'data');
