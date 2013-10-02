function cbkProcSingleTrial(src, evntDat, uihdls, varargin)
%% Get trial number
ii = get(uihdls.trialListBox, 'Value');

%% Load data
assert(exist('data') == 0);
load(uihdls.matFileName);
assert(exist('data') == 1);

%% 
[y, fs] = wavread(data{ii}.recordFile);

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

%GUI to classify--------------------        
[hFig, hSpect, retVals] = SEQ_GUI(ysnd, fs, uihdls.recordTime, uihdls.audioMode);

% uiwait;

%         buttonVals{1}
%         buttonVals{2}
data{ii}.accuracy = retVals.buttonVals{1};
data{ii}.fluency = retVals.buttonVals{2};
data{ii}.accuracyLowConfid = retVals.accuracyLowConfid;
data{ii}.fluencyLowConfid = retVals.fluencyLowConfid;
data{ii}.bStarter = retVals.bStarter;

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
%                         spectrogram(y_orig, nwin, noverlap, nfft, fs, 'yaxis');
spectrogram(yvis, nwin, noverlap, nfft, fs, 'yaxis');
ylim([0 4000]);

guidat.hLineOn = [NaN, NaN, NaN];
guidat.hLineEnd = [NaN, NaN, NaN];
guidat.hLineStarter = [NaN, NaN, NaN];

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
            accept = menu('Select', 'Take', 'Edit', 'Select & Play');
        end
        
        
        
        switch accept
            case 1
                flagEndFound = 1;
                if ~isfield(data{ii}, 'times') || isempty(data{ii}.times)
                    if speechOn == 1 && speechOff == 1
                        data{ii}.times = [ii speechOnTime speechOffTime-speechOnTime];
                    else
                        data{ii}.times = [ii speechOnTime speechOffTime-speechOnTime];
                        fprintf(1, 'WARNING: data{%d}.times left empty because no automatically calculated or user entered time stamps are available.\n', ii);
                    end
                end
                break;

            case 2
                flagEndFound = 1;

                bTimeLabelsOkay = 0;

                while ~bTimeLabelsOkay
                    %input times
                    set(0, 'CurrentFigure', guidat.hfig);
                    set(gcf, 'CurrentAxes', guidat.hsp1);
                    ys = get(gca, 'YLim');

                    for j0 = 1 : length(guidat.hLineStarter)
                        if ~isnan(guidat.hLineStarter(j0))
                            delete(guidat.hLineStarter(j0));
                        end
                    end
                    for j0 = 1 : length(guidat.hLineOn)
                        if ~isnan(guidat.hLineOn(j0))
                            delete(guidat.hLineOn(j0));
                        end
                    end
                    for j0 = 1 : length(guidat.hLineEnd)
                        if ~isnan(guidat.hLineEnd(j0))
                            delete(guidat.hLineEnd(j0));
                        end
                    end

                    % -- Optional: starter -- %                                            
                    if isfield(data{ii}, 'bStarter') && data{ii}.bStarter == 1
                        title('Set starter onset time...', 'Color', 'm', 'FontWeight', 'Bold'); drawnow;
                        coord1 = ginput(1);

                        set(gcf, 'CurrentAxes', guidat.hsp1);
                        guidat.hLineStarter(1) = plot(repmat(coord1(1), 1, 2), get(gca, 'YLim'), 'm--');
                        set(gcf, 'CurrentAxes', guidat.hsp2);
                        guidat.hLineStarter(2) = plot(repmat(coord1(1), 1, 2), get(gca, 'YLim'), 'm--');
                        set(gcf, 'CurrentAxes', guidat.hsp3);
                        guidat.hLineStarter(3) = plot(repmat(coord1(1), 1, 2), get(gca, 'YLim'), 'm--');
                        set(gcf, 'CurrentAxes', guidat.hsp1);

                        numResp_starter = coord1(1);
                    else
                        numResp_starter = NaN;
                    end

                    title('Set word onset time...', 'Color', 'b'); drawnow;
                    coord1 = ginput(1);

                    set(gcf, 'CurrentAxes', guidat.hsp1);
                    guidat.hLineOn(1) = plot(repmat(coord1(1), 1, 2), get(gca, 'YLim'), 'b--');
                    set(gcf, 'CurrentAxes', guidat.hsp2);
                    guidat.hLineOn(2) = plot(repmat(coord1(1), 1, 2), get(gca, 'YLim'), 'b--');
                    set(gcf, 'CurrentAxes', guidat.hsp3);
                    guidat.hLineOn(3) = plot(repmat(coord1(1), 1, 2), get(gca, 'YLim'), 'b--');
                    set(gcf, 'CurrentAxes', guidat.hsp1);

                    numResp_on = coord1(1);

                    if ~calc_half
                        title('Set the offset time...', 'Color', 'b'); drawnow;
                        coord2 = ginput(1);

                        set(gcf, 'CurrentAxes', guidat.hsp1);
                        guidat.hLineEnd(1) = plot(repmat(coord2(1), 1, 2), get(gca, 'YLim'), 'b-');
                        set(gcf, 'CurrentAxes', guidat.hsp2);
                        guidat.hLineEnd(2) = plot(repmat(coord2(1), 1, 2), get(gca, 'YLim'), 'b-');
                        set(gcf, 'CurrentAxes', guidat.hsp3);
                        guidat.hLineEnd(3) = plot(repmat(coord2(1), 1, 2), get(gca, 'YLim'), 'b-');
                        set(gcf, 'CurrentAxes', guidat.hsp1);

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

%                                 strResp_on = input('Enter the onset time (in secs) and type Enter\n', 's');
%                                 strResp_end = input('Enter the offset time (in secs) and type Enter\n', 's');                               
%                                 numResp_on = str2double(strResp_on);
%                                 numResp_end = str2double(strResp_end);

                if isfield(data{ii}, 'bStarter') && data{ii}.bStarter == 1
                    data{ii}.starterOnset = numResp_starter;
                end
                data{ii}.times = [ii numResp_on numResp_end];
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
        end
    end
end
%pause;

%% Check and update status
if ~isnan(data{ii}.accuracy) && ~isnan(data{ii}.fluency) ...
   && ~isnan(data{ii}.accuracyLowConfid) && ~isnan(data{ii}.fluencyLowConfid) ...
   && ~isempty(data{ii}.times) ...
   && ~isnan(data{ii}.bStarter)
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
