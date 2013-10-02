function bFoundUnfinished = updateTrialList(uihdls, data)
listItems = {};
for i1 = 1 : length(data)
    if data{i1}.status
        completionStr = 'X';
    else
        completionStr = '_';
    end
        
    listItems{i1} = sprintf('[%s] %.3d - %s', completionStr, i1, data{i1}.stimWord);
    
    if data{i1}.fluency > 1
        listItems{i1} = [listItems{i1}, ' (Disfluency)'];
    end
    
    if data{i1}.accuracy > 1
        listItems{i1} = [listItems{i1}, ' (Inaccurate)'];
    end
    
    if isfield(data{i1}, 'fmtOpts') ...
       && isfield(data{i1}, 'f0_time') && ~isempty(data{i1}.f0_time) ...
       && isfield(data{i1}, 'f0') && ~isempty(data{i1}.f0) ...
       && isfield(data{i1}, 'fmt_time') && ~isempty(data{i1}.fmt_time) ...
       && isfield(data{i1}, 'f1') && ~isempty(data{i1}.f1) ...
       && isfield(data{i1}, 'f2') && ~isempty(data{i1}.f2);
        listItems{i1} = [listItems{i1}, ' [F0,Fmt done]'];
    end
end
set(uihdls.trialListBox, 'string', listItems);

%% Set current focus to the next unfinished trial
ii = get(uihdls.trialListBox, 'Value');
if data{ii}.status == 1
    if get(uihdls.rbKeepGoing, 'Value') == 1
        % Find the next unfinished trial
        init_ii = ii;
        curr_ii = mod(ii, length(data)) + 1;

        bFoundUnfinished = 0;
        while curr_ii ~= init_ii
            if data{curr_ii}.status == 0
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
end
return