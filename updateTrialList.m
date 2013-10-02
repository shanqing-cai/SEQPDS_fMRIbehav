function bFoundUnfinished = updateTrialList(uihdls, data)
listItems = {};
for i1 = 1 : length(data)
    if data{i1}.status
        completionStr = 'X';
    else
        completionStr = '_';
    end
    
    listItems{i1} = sprintf('[%s] %.3d - %s', completionStr, i1, data{i1}.stimWord);
end

set(uihdls.trialListBox, 'string', listItems);

%% Set current focus to the next unfinished trial
ii = 1;
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
return