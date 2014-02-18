function cbkProcSingleTrial(src, evntDat, uihdls, varargin)
%% Get trial number and name
[ii, listTrialNums] = get_curr_trial_index(uihdls.trialListBox);

%%
assert(~isnan(ii) && ii > 0);

%% Load data
assert(exist('data') == 0);
load(uihdls.matFileName);
assert(exist('data') == 1);

%% 
[y, fs] = wavread(data{ii}.recordFile);

%%
y_orig = y;

ysnd = WienerScalart96(y, fs); % Apply filter
if length(ysnd) < length(y_orig)
    ysnd = [ysnd; zeros(length(y_orig) - length(ysnd), 1)];
end

yvis = ysnd;
y = ysnd;
if ~uihdls.bFilt
    ysnd = y_orig;
end
%         if ~isempty(strfind(lower(getenv('OS')), 'windows'))
if isequal(uihdls.audioMode, 'soundsc')
%             soundsc(ysnd(1 : round(uihdls.recordTime*fs)), fs);
    soundsc(ysnd, fs);
elseif isequal(uihdls.audioMode, 'wavplay');
    wavplay(ysnd, fs);
%             wavplay(ysnd(1 : round(uihdls.recordTime*fs)), fs);
else
    ap = audioplayer(ysnd(1 : round(uihdls.recordTime*fs)), fs);
    play(ap, 1);
end

%--- Find prior formant tracking settings ---%
if isfield(data{ii}, 'fmtOpts') && ~isempty(data{ii}.fmtOpts)
    fmtOpts = data{ii}.fmtOpts;
    
else
    bFoundSW = 0; % Found same-word formant settings
    % for iprev = [ii, setxor(length(data) : -1 : 1, ii)]
    for iprev = [ii, setxor(fliplr(listTrialNums), ii)];
        if data{iprev}.status == 1 && isequal(data{iprev}.stimWord, data{ii}.stimWord)
            bFoundSW = 1;
            break;
        end
    end

    if bFoundSW
        fmtOpts = data{iprev}.fmtOpts;
    else %--- Look for any word prior --- %
        bFoundPrior = 0; % Found same-word formant settings
    %     for iprev = length(data) : -1 : 1
        for iprev = fliplr(listTrialNums)
            if data{iprev}.status == 1
                bFoundPrior = 1;
                break;
            end        
        end

        if bFoundPrior
            fmtOpts = data{iprev}.fmtOpts;
        else
            fmtOpts = [];
        end
    end

end

%--- GUI to classify and track pitch and formants ---%
[hFig, hSpect, retVals] = SEQ_GUI(ysnd, fs, uihdls.recordTime, uihdls.audioMode, ...                                  
                                  uihdls, ...
                                  '--stimWord', data{ii}.stimWord, ...
                                  '--fmtOpts', fmtOpts, ...
                                  '--trialNum', ii, ...
                                  '--data', data{ii});

% uiwait;

tdata = load(uihdls.matFileName);

%         buttonVals{1}
%         buttonVals{2}
data{ii}.accuracy = retVals.buttonVals{1};
data{ii}.fluency = retVals.buttonVals{2};
data{ii}.accuracyLowConfid = retVals.accuracyLowConfid;
data{ii}.fluencyLowConfid = retVals.fluencyLowConfid;
data{ii}.bStarter = retVals.bStarter;

%--- Copy over pitch and formant information ---%
data{ii}.fmtOpts = tdata.data{ii}.fmtOpts;

data{ii}.f0_time = tdata.data{ii}.f0_time;
data{ii}.f0 = tdata.data{ii}.f0;
data{ii}.fmt_time = tdata.data{ii}.fmt_time;
data{ii}.f1 = tdata.data{ii}.f1;
data{ii}.f2 = tdata.data{ii}.f2;

clear('tdata');
%--- Copy over pitch and formant information ---%

try
    close(hFig);
end
try
    close(hSpect);
end
drawnow;

% if ~isempty(redoTrialN)
%     if bRedoCatOnly
%         return;
%     end
% end

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


winSize = round(fs * .0015);
Incr = round(fs * .001);
time = 0 : 1 / fs : (length(y) - 1) / fs;
%     noWins = length(winSize:Incr:(length(y)-winSize));
iter = 1;
I = [];
tm = [];
BegWin = 1;
EndWin = BegWin + winSize;
% 
while EndWin < length(y) %ii = 1:noWins
    dat = detrend(y(BegWin : EndWin, 1), 0);
    dat = convn(dat,[1;-.95]);
    dat = detrend(dat, 0);
    int = sum(dat.^2);
    I(iter) = 20*log10(int/.0015); %000015
    tm(iter) = time(BegWin);
%         if iter > uihdls.OnDur && speechOn == 0 && length(find(I(iter-uihdls.OnDur:iter) > uihdls.onThresh)) == length(I(iter-uihdls.OnDur:iter)) && tm(iter-uihdls.OnDur) > .09
% %                         disp('***');
%             speechOn = 1;
%             speechOnTime = tm(iter-uihdls.OnDur);
%             endTm = round(speechOnTime*fs);
%             EndWin = BegWin + round(fs * .010);
%         elseif iter > uihdls.OffDur && speechOn == 1 && isempty(find(I(iter-uihdls.OffDur:iter) > uihdls.offThresh)) == 1 && tm(iter-uihdls.OffDur) - speechOnTime > .40
% %                         disp('###');
%             speechOff = 1;
%             speechOffTime = tm(iter-uihdls.OffDur);
%             offTm = round(speechOffTime*fs);
%             winSize = round(fs * .0015);
%         end
% 
    BegWin = BegWin + Incr;
    EndWin = EndWin + Incr;
    iter = iter + 1;
end

%                     if speechOn == 1 && speechOff == 1
guidat.hfig = figure('Position', uihdls.pos);
%TOP PLOT-----------------------------------
guidat.hsp1 = subplot(3, 1, 1); plot(time, detrend(yvis, 0), 'k'); hold on;
%title(['Token is ' char(StimList(i)) '  < press spacebar to continue >']);
axis tight;
ax = axis;

%             if speechOn == 1 && speechOff == 1
%                 line([speechOnTime speechOnTime], [ax(3) ax(4)], 'Color', 'k', 'LineWidth', 2.0);
%                 line([speechOffTime speechOffTime], [ax(3) ax(4)], 'Color', 'k', 'LineWidth', 2.0);
%             end

%MIDDLE PLOT-----------------------------------
guidat.hsp2 = subplot(3, 1, 2); plot(tm, I, 'k'); hold on;
bx = axis;

%             if speechOn == 1 && speechOff == 1
%                 line([speechOnTime speechOnTime], [bx(3) bx(4)], 'Color', 'k', 'LineWidth', 2.0);
%                 line([speechOffTime speechOffTime], [bx(3) bx(4)], 'Color', 'k', 'LineWidth', 2.0);
%             end
axis([ax(1) ax(2) bx(3) bx(4)]);

%BOTTOM PLOT-----------------------------------
guidat.hsp3 = subplot(3, 1, 3); hold on;
nwin = 512; % samples
noverlap = 256; %samples
nfft = 512; %samples

plot(data{ii}.f0_time, data{ii}.f0, 'k-');
plot(data{ii}.fmt_time, [data{ii}.f1, data{ii}.f2], 'b-');

spectrogram(yvis, nwin, noverlap, nfft, fs, 'yaxis');
ylim([0, 4000]);

legend({'F0', 'F1 & F2'}, 'Location', 'Northeast');

% Show F0

guidat.hLineOn = [NaN, NaN, NaN];
guidat.hLineEnd = [NaN, NaN, NaN];
guidat.hLineStarter = [NaN, NaN, NaN];
guidat.dtwLines = [];
guidat.dtwTxt = [];
guidat.dtwInfoTxt = [];
guidat.dtwLinesMan = [];
guidat.dtwManLbl = [];
guidat.dtwManualOnset = [NaN, NaN, NaN];
guidat.dtwManualOnsetLbl = [];

guidat.hComment = [];

guidat = disp_label_dtw(guidat, uihdls, data, ii);

%% Display previous labeling and dtw results, if any
if data{ii}.accuracy == 2 || data{ii}.accuracy == 4 % Silence or Unusable (unrecognizable) --> no onset / offset labeling is necessary
    set(gcf, 'CurrentAxes', guidat.hsp1);
    title('No onset / offset labeling is needed since this trial is marked as silence or unusable', 'Color', 'k', 'FontSize', 14);
    drawnow;
    pause(2);
    title('', 'FontSize', 12, 'Color', 'k');

    data{ii}.times = [];
else
    while 1
        if ~isfield(data{ii}, 'times') || isempty(data{ii}.times)
            accept = 2; % Edit
        else
            accept = menu('Select', 'Take', 'Edit', 'Select & Play', ...
                          'Set manual DTW onset', 'Cancel manual DTW onset', ...
                          'Manually adjust DTW label', ...
                          'Remove manually adjusted DTW label', ...
                          'Add / edit comment');
        end
        
        switch accept
            case 1 % Take the current results and proceed                
                if ~isfield(data{ii}, 'times') || isempty(data{ii}.times)
                    if speechOn == 1 && speechOff == 1
                        data{ii}.times = [ii speechOnTime speechOffTime-speechOnTime];
                    else
                        data{ii}.times = [ii speechOnTime speechOffTime-speechOnTime];
                        fprintf(1, 'WARNING: data{%d}.times left empty because no automatically calculated or user entered time stamps are available.\n', ii);
                    end
                end
                break;

            case 2 % Label the onset and offset                
                bTimeLabelsOkay = 0;
                tmpHdls = [];
                while ~bTimeLabelsOkay
                    % Clean up the temporary displays
                    for k1 = 1 : length(tmpHdls)
                        if ~isnan(tmpHdls(k1))
                            delete(tmpHdls(k1));
                        end
                    end
                    tmpHdls = [];
                    
                    %input times
                    set(0, 'CurrentFigure', guidat.hfig);
                    set(gcf, 'CurrentAxes', guidat.hsp1);
                    ys = get(gca, 'YLim');

                    guidat = disp_label_dtw(guidat, uihdls, data, ii, '--clean-up-only');

                    % -- Optional: starter -- %                                            
                    if isfield(data{ii}, 'bStarter') && data{ii}.bStarter == 1
                        title('Set starter onset time...', 'Color', 'm', 'FontWeight', 'Bold'); drawnow;
                        coord1 = ginput(1);
                        tmpHdls(end + 1) = plot(repmat(coord1(1), 1, 2), ys, 'm--');
                        numResp_starter = coord1(1);
                    else
                        numResp_starter = NaN;
                    end

                    title('Set word onset time...', 'Color', 'b'); drawnow;
                    coord1 = ginput(1);
                    tmpHdls(end + 1) = plot(repmat(coord1(1), 1, 2), ys, 'b--');
                    numResp_on = coord1(1);

                    if ~calc_half
                        set(gcf, 'CurrentAxes', guidat.hsp1);
                        title('Set the offset time...', 'Color', 'b'); drawnow;
                        coord2 = ginput(1);
                        tmpHdls(end + 1) = plot(repmat(coord1(1), 1, 2), ys, 'b-');
                        numResp_end = coord2(1);
                    else
                        title('No offset since this is an unfinished trial.', 'Color', 'm'); drawnow;
                        pause(1.5);
                        title('', 'Color', 'b'); drawnow;
                        guidat.hLineEnd = [NaN, NaN, NaN];
                        numResp_end = NaN;
                    end

                    set(gcf, 'CurrentAxes', guidat.hsp1);
                    set(gca, 'YLim', ys);

                    if isfield(data{ii}, 'bStarter') && data{ii}.bStarter == 1
                        bTimeLabelsOkay = (numResp_end > numResp_on) && (numResp_on > numResp_starter) || calc_half;
                    else
                        bTimeLabelsOkay = (numResp_end > numResp_on) || calc_half;
                    end
                    if ~bTimeLabelsOkay
                        title('The onset and offset times you set are incorrect. Try again...', 'Color', 'r');
                        drawnow;
                        pause(1);
                    else
                        title('', 'Color', 'b'); drawnow;
                    end
                end
                
                %% Optional: starter
                if isfield(data{ii}, 'bStarter') && data{ii}.bStarter == 1
                    data{ii}.starterOnset = numResp_starter;
                end
                data{ii}.times = [ii numResp_on numResp_end];
                save(uihdls.matFileName, 'data');

                %%--- Perform dynamic time warping (dtw) ---%%
                warpAlign = dtw_wrapper(data{ii}.recordFile, uihdls.matFileName);

                data{ii}.warpAlign = warpAlign;                
                save(uihdls.matFileName, 'data');

                %-- Display labeling and dtw results --%
                % Clean up the temporary displays
                for k1 = 1 : length(tmpHdls)
                    if ~isnan(tmpHdls(k1))
                        delete(tmpHdls(k1));
                    end
                end
                tmpHdls = [];
                
                guidat.hLineOn = [NaN, NaN, NaN];
                guidat.hLineEnd = [NaN, NaN, NaN];
                guidat.hLineStarter = [NaN, NaN, NaN];
                guidat.dtwLines = [];
                guidat.dtwTxt = [];
                guidat.dtwInfoTxt = [];
                guidat.dtwLinesMan = [];
                guidat.dtwManLbl = [];
                guidat.dtwManualOnset = [NaN, NaN, NaN];
                guidat.dtwManualOnsetLbl = [];
                guidat.hComment = [];
                
                guidat = disp_label_dtw(guidat, uihdls, data, ii);
                
            case 3 % Select and play
                set(0, 'CurrentFigure', guidat.hfig);
                set(gcf, 'CurrentAxes', guidat.hsp1);
                ys = get(gca, 'YLim');

                green = [0, 0.5, 0];
                title('Set beginning of sound snipppet...', 'Color', green); drawnow;
                coord1 = ginput(1);
                set(gcf, 'CurrentAxes', guidat.hsp1);
                guidat.hPBLine0 = plot(repmat(coord1(1), 1, 2), ys, '--', 'Color', green);                                    
                drawnow;

                title('Set end of sound snippet...', 'Color', green); drawnow;
                coord2 = ginput(1);
                set(gcf, 'CurrentAxes', guidat.hsp1);
                guidat.hPBLine1 = plot(repmat(coord2(1), 1, 2), ys, '-', 'Color', green);

                drawnow;

                title('', 'Color', 'b'); drawnow;


                ysnip = ysnd(time >= coord1(1) & time < coord2(1));
%                                     if ~isempty(strfind(lower(getenv('OS')), 'windows'))
                if ~isempty(ysnip)
                    if isequal(uihdls.audioMode, 'soundsc')                                            
                        soundsc(ysnip, fs);
                    elseif isequal(uihdls.audioMode, 'wavplay')
                        wavplay(ysnip, fs);
                    else
                        ap = audioplayer(ysnip, fs);
                        play(ap, 1);
                    end
                else
                    fprintf(1, 'WARNING: the selected audio snippet appears to be empty. It will not be played.\n');
                end

%                                     soundsc(ysnip, fs);
                pause(0.5);

                delete(guidat.hPBLine0);
                delete(guidat.hPBLine1);
            case 4 % Set manual DTW onset
                if ~isfield(data{ii}, 'warpAlign') || isempty(data{ii}.warpAlign)
                    msgbox('Error: DTW has not been performed yet.', 'ERROR', 'error', 'modal');
                    continue;
                end
                
                bGood = 0;
                while ~bGood
                    title('Set manual DTW onset...', 'Color', 'b');
                    set(0, 'CurrentFigure', guidat.hfig);
                    set(gcf, 'CurrentAxes', guidat.hsp1);
                    
                    crd = ginput(1);
                    bGood = (crd(1) < data{ii}.times(3));
                    
                    if ~bGood
                        title('ERROR: manual DTW onset must be earlier than utterance offset. Please try again...', 'Color', 'r');
                        pause(2);
                        title('', 'Color', 'b');
                    end                   
                end
                title('', 'Color', 'b');
                
                data{ii}.manualDTWOnset = crd(1);
                save(uihdls.matFileName, 'data');
                warpAlign = dtw_wrapper(data{ii}.recordFile, uihdls.matFileName);

                data{ii}.warpAlign = warpAlign;
                save(uihdls.matFileName, 'data');
                
                guidat = disp_label_dtw(guidat, uihdls, data, ii);
                
            case 5 % Cancel manual DTW onset
                if ~isfield(data{ii}, 'warpAlign') || isempty(data{ii}.warpAlign)
                    msgbox('Error: DTW has not been performed yet.', 'ERROR', 'error', 'modal');
                    continue;
                end
                
                if ~isfield(data{ii}, 'manualDTWOnset') || isempty(data{ii}.manualDTWOnset) || isnan(data{ii}.manualDTWOnset)
                    msgbox('Error: no manual DTW onset was set previously', 'ERROR', 'error', 'modal');
                    continue;
                end
                
                data{ii} = rmfield(data{ii}, 'manualDTWOnset');
                save(uihdls.matFileName, 'data');
                warpAlign = dtw_wrapper(data{ii}.recordFile, uihdls.matFileName);
                
                data{ii}.warpAlign = warpAlign;
                save(uihdls.matFileName, 'data');
                
                guidat = disp_label_dtw(guidat, uihdls, data, ii);
                
            case 6 % Manually adjust DTW label
                if ~isfield(data{ii}, 'warpAlign') || isempty(data{ii}.warpAlign)
                    msgbox('Error: DTW has not been performed yet.', 'ERROR', 'error', 'modal');
                    continue;
                end
                
                %-- Prepare menu --%
                phnSelCmd = 'phnSel = menu(''Select label to adjust'', ';
                lblNames = cell(size(data{ii}.warpAlign.segNames));
                for i1 = 1 : length(data{ii}.warpAlign.segNames)
                    lblNames{i1} = strcat(data{ii}.warpAlign.segNames{i1}, '-onset');
                    phnSelCmd = strcat(phnSelCmd, '''', lblNames{i1}, ''', ');
                    if i1 == length(data{ii}.warpAlign.segNames)
                        lblNames{i1 + 1} = strcat(data{ii}.warpAlign.segNames{i1}, '-end');
                        phnSelCmd = strcat(phnSelCmd, sprintf('''%s-end'', ', data{ii}.warpAlign.segNames{i1}));
                    end
                end
                phnSelCmd = strcat(phnSelCmd(1 : end - 2), ''', ''Cancel'');');
                eval(phnSelCmd);
                
                if phnSel > length(lblNames)
                    continue; % Cancel
                end
                
                phnName = lblNames{phnSel};
                
                set(0, 'CurrentFigure', guidat.hfig);
                set(gcf, 'CurrentAxes', guidat.hsp1);
                title(sprintf('Click at the time of %s...', phnName));
                crd = ginput(1);
                
                if ~isfield(data{ii}.warpAlign, 'manTBeg')
                    data{ii}.warpAlign.manTBeg = nan(size(data{ii}.warpAlign.tBeg));
                    data{ii}.warpAlign.manTEnd = nan(size(data{ii}.warpAlign.tEnd));
                end
                title('');
                
                if phnSel == numel(lblNames) % Labeling the last element: end of the last phone
                    data{ii}.warpAlign.manTEnd(end) = crd(1);
                else
                    data{ii}.warpAlign.manTBeg(phnSel) = crd(1);
                end
                
                save(uihdls.matFileName, 'data');
                guidat = disp_label_dtw(guidat, uihdls, data, ii);
                
            case 7 % Cancel manually adjusted DTW label
                if ~isfield(data{ii}, 'warpAlign') || isempty(data{ii}.warpAlign)
                    msgbox('Error: DTW has not been performed yet.', 'ERROR', 'error', 'modal');
                    continue;
                end
                
                if ~isfield(data{ii}.warpAlign, 'manTBeg')
                    msgbox('Error: no manually adjusted DTW label was found.', 'error', 'modal');
                    continue;
                end
                
                %-- Prepare menu --%
                phnSelCmd = 'phnSel = menu(''Select label to delete'', ';
                lblNames = {};
                lblPos = [];
                for i1 = 1 : length(data{ii}.warpAlign.manTBeg)
                    if ~isnan(data{ii}.warpAlign.manTBeg(i1))
                        lblNames{end + 1} = strcat(data{ii}.warpAlign.segNames{i1}, '-onset');
                        lblPos(end + 1) = i1;
                        
                        phnSelCmd = strcat(phnSelCmd, '''', lblNames{end}, ''', ');
                    end
                end
                if ~isnan(data{ii}.warpAlign.manTEnd(end))
                    lblNames{end + 1} = strcat(data{ii}.warpAlign.segNames{end}, '-end');
                    lblPos(end + 1) = numel(data{ii}.warpAlign.manTEnd) + 1;
                    
                    phnSelCmd = strcat(phnSelCmd, '''', lblNames{end}, ''', ');
                end
                
                phnSelCmd = strcat(phnSelCmd, '''Cancel'');');
                eval(phnSelCmd);
                
                if phnSel > length(lblNames)
                    continue; % Cancel
                else
                    phnName = lblNames{phnSel};
                    if length(phnName) > 4 && isequal(phnName(end - 3 : end), '-end')
                        data{ii}.warpAlign.manTEnd(end) = NaN;
                    else
                        data{ii}.warpAlign.manTBeg(lblPos(phnSel)) = NaN;
                    end
                end
                
                save(uihdls.matFileName, 'data');
                guidat = disp_label_dtw(guidat, uihdls, data, ii);
                
            case 8 % Add / Edit comment
                if ~isfield(data{ii}, 'comment')
                    data{ii}.comment = '';
                end
                
                data{ii}.comment = inputdlg('Comment:', 'Comment', 1, {data{ii}.comment});
                if iscell(data{ii}.comment)
                    data{ii}.comment = data{ii}.comment{1};
                end
                
                save(uihdls.matFileName, 'data');
                guidat = disp_label_dtw(guidat, uihdls, data, ii);
        end
    end
end
%pause;

%% Check and update status
trialAcoustOkay = isfield(data{ii}, 'f0_time') && ~isempty(data{ii}.f0_time) ...
                    && isfield(data{ii}, 'f0') && ~isempty(data{ii}.f0) ...
                    && isfield(data{ii}, 'fmt_time') && ~isempty(data{ii}.fmt_time) ...
                    && isfield(data{ii}, 'f1') && ~isempty(data{ii}.f1) ...
                    && isfield(data{ii}, 'f2') && ~isempty(data{ii}.f2);
                
if ((~isnan(data{ii}.accuracy) && ~isnan(data{ii}.fluency) ...
     && ~isnan(data{ii}.accuracyLowConfid) && ~isnan(data{ii}.fluencyLowConfid) ...
     && ~isempty(data{ii}.times) ...
     && ~isnan(data{ii}.bStarter) ...
     && isfield(data{ii}, 'fmtOpts') ...
     && trialAcoustOkay) ...
     || (data{ii}.accuracy == 4 && ~isnan(data{ii}.fluency ...
         && ~isnan(data{ii}.accuracyLowConfid) && ~isnan(data{ii}.fluencyLowConfid) ...
         && isfield(data{ii}, 'fmtOpts') && trialAcoustOkay)))
    if (data{ii}.bStarter == 1 && ~isempty(data{ii}.starterOnset)) ...
       || data{ii}.bStarter == 0
        data{ii}.status = 1;
    else
        data{ii}.status = 0;
    end
else
    data{ii}.status = 0;
end

save(uihdls.matFileName, 'data');
fprintf(1, 'Saved updated data to file: %s\n', uihdls.matFileName);

close(guidat.hfig);

%% Update trial list
bFoundUnfinished = updateTrialList(uihdls, data);
drawnow;

%% Optional: keep going
if get(uihdls.rbKeepGoing, 'Value') == 1
%     % Find the next unfinished trial
%     init_ii = ii;
%     curr_ii = mod(ii, length(data)) + 1;
%     
%     bFoundUnfinished = 0;
%     while curr_ii ~= init_ii
%         if data{curr_ii}.status == 0
%             bFoundUnfinished = 1;
%             
%             set(uihdls.trialListBox, 'Value', curr_ii);
%             drawnow;
%             pause(0.25);
%             
%             break;
%         end
%         
%         curr_ii = mod(curr_ii, length(data)) + 1;
%     end
%     
%     if bFoundUnfinished == 0
%         fprintf(1, 'INFO: All trials have been processed');
%     else
%         cbkProcSingleTrial(src, [], uihdls);
%     end
    if bFoundUnfinished
        cbkProcSingleTrial(src, [], uihdls);
    end
    
end

return
