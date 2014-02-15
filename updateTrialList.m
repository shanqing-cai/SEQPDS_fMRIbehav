function bFoundUnfinished = updateTrialList(uihdls, data)
listItems = {};
listTrialNums = [];
for i1 = 1 : length(data)
    if isempty(data{i1})
        continue;
    end
    
    if isfield(data{i1}, 'status') && data{i1}.status
        completionStr = 'X';
    else
        completionStr = '_';
    end
        
    if isfield(data{i1}, 'stimWord')
        listItems{end + 1} = sprintf('[%s] %.3d - %s', completionStr, i1, data{i1}.stimWord);
        listTrialNums(end + 1) = i1;
    end
    
    if isfield(data{i1}, 'fluency') && data{i1}.fluency > 1
        listItems{end} = [listItems{end}, ' (Disfluency)'];
    end
    
    if isfield(data{i1}, 'accuracy') && data{i1}.accuracy > 1
        listItems{end} = [listItems{end}, ' (Inaccurate)'];
    end
    
    if isfield(data{i1}, 'fmtOpts') ...
       && isfield(data{i1}, 'f0_time') && ~isempty(data{i1}.f0_time) ...
       && isfield(data{i1}, 'f0') && ~isempty(data{i1}.f0) ...
       && isfield(data{i1}, 'fmt_time') && ~isempty(data{i1}.fmt_time) ...
       && isfield(data{i1}, 'f1') && ~isempty(data{i1}.f1) ...
       && isfield(data{i1}, 'f2') && ~isempty(data{i1}.f2);
        listItems{end} = [listItems{end}, ' [F0,Fmt done]'];
    end
    
    if isfield(data{i1}, 'warpAlign') ...
        && isfield(data{i1}.warpAlign, 'segNames') && isfield(data{i1}.warpAlign, 'tBeg') ...
        && isfield(data{i1}.warpAlign, 'tEnd') && isfield(data{i1}.warpAlign, 'segHostName') ...
        && isfield(data{i1}.warpAlign, 'segTimeStamp')
        listItems{end} = [listItems{end}, ' [dtw done]'];
    end
    
end
set(uihdls.trialListBox, 'string', listItems);

%% Set current focus to the next unfinished trial
% ii = get(uihdls.trialListBox, 'Value');
[ii, listTrialNums] = get_curr_trial_index(uihdls.trialListBox);

if isfield(uihdls, 'matFileName');
    data = load(uihdls.matFileName);
    data = data.data;
end

if data{ii}.status == 1
    if get(uihdls.rbKeepGoing, 'Value') == 1
        % Find the next unfinished trial
        init_ii = find(listTrialNums == ii, 1);
        curr_ii = mod(init_ii, length(listTrialNums)) + 1;

        bFoundUnfinished = 0;
        while (curr_ii ~= init_ii) && (ii < length(listTrialNums))
            if data{listTrialNums(curr_ii)}.status == 0
                bFoundUnfinished = 1;

                set(uihdls.trialListBox, 'Value', curr_ii);
    %             drawnow;
    %             pause(0.25);

                break;
            end

            curr_ii = mod(curr_ii, length(data)) + 1;
        end

        if bFoundUnfinished == 0
            fprintf(1, 'INFO: All trials have been processed');
        end

    else
        bFoundUnfinished = NaN;
    end
else
    bFoundUnfinished = 1;
end
return