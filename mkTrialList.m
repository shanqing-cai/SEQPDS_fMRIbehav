function uihdls = mkTrialList(data, subjName, testName)
%% Figure base
uihdls.figTrialList = figure('Position', [20, 60, 500, 400], ...
                             'Name', sprintf('Trial list of %s - %s', subjName, testName), ...
                             'NumberTitle', 'off', ...
                             'MenuBar', 'none', 'ToolBar', 'none');

%% Trial list
uihdls.trialListBox = uicontrol('Parent', uihdls.figTrialList, 'Style', 'listbox', ...
                                'Unit', 'Normalized', 'Position', [0.05, 0.25, 0.9, 0.7], ...
                                'BackgroundColor', 'w', 'FontName', 'FixedWidth');


%% Radio buttons
uihdls.rbKeepGoing = uicontrol('Parent', uihdls.figTrialList, 'Style', 'radiobutton', ...
                               'Unit', 'Normalized', 'Position',  [0.05, 0.14, 0.275, 0.1], ...
                               'String', 'Keep going');
set(uihdls.rbKeepGoing, 'Value', 1);

%% Buttons
btnW = 0.275;
btnH = 0.075;

uihdls.btnProc = uicontrol('Parent', uihdls.figTrialList, 'Style', 'pushbutton', ...
                           'Unit', 'Normalized', 'Position', [0.05, 0.05, btnW, btnH], ...
                           'String', 'Process');
                       
updateTrialList(uihdls, data);

return