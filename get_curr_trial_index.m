function [idx, listTrialNums] = get_curr_trial_index(trialListBox)
strs = get(trialListBox, 'String');
listTrialNums = nan(1, length(strs));

for i1 = 1 : length(strs)
    trialStr = strs{i1};

    assert(length(trialStr) > 7);
    assert(length(strfind(trialStr, ' ')) >= 3);
    assert(isequal(trialStr(1), '['));
    assert(isequal(trialStr(3), ']'));
    assert(isequal(trialStr(4), ' '));

    trialStrItems = splitstring(trialStr, ' ');
    listTrialNums(i1) = str2double(trialStrItems{2});
end

ii = get(trialListBox, 'Value');
idx = listTrialNums(ii);

return