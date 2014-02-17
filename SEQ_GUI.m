function [hFig, hSpect, retVals] = SEQ_GUI(y, fs, recordTime, audioMode, uihdls, varargin)
    global buttonVals done    
    global accuracyLowConfid
    global fluencyLowConfid
    global bStarter
    global errorBtnGrp
    global fluentBtnGrp

recordTime = 3;

%% Configuration
NLPC_OPTIONS = [13, 15, 17, 19];
NLPC_DEFAULT = 17;
FN1_DEFAULT = 600;
FN2_DEFAULT = 1800;

ALPHA_DEFAULT = 1e5;
BETA_DEFAULT = 0.8;
GAMMA_DEFAULT = 1.0;

%% Formant tracking options
if ~isempty(fsic(varargin, '--fmtOpts'))
    fmtOpts = varargin{fsic(varargin, '--fmtOpts') + 1};
else
    fmtOpts = [];
end


%%
ui.hSpect = figure('Visible', 'on', 'Menu','none', 'Name','Calculator', 'Resize','on', 'Position',[100 350 1000 200]);
subplot('Position', [0.05, 0.2, 0.9, 0.775]);
movegui(ui.hSpect, 'northwest');
% show_spectrogram(y, fs, 'noFig');
% xlabel('Time (s)');
% ylabel('Frequency (Hz)');

% Show F0 and formants
% plot(f0_time, f0_value, 'k-');
% plot(fmt_time, [f1, f2], 'b-');

ui.hFig = figure('Visible','off', 'Menu','none', 'Name','Spectrogram', 'Resize','on', 'Position',[100 100 500 320]);    
movegui(ui.hFig, 'center');          %# Move the GUI to the center of the screen

if ~isempty(fsic(varargin, '--stimWord'))
    stimWord = varargin{fsic(varargin, '--stimWord') + 1};

    set(ui.hFig, 'Name', stimWord);
    set(ui.hSpect, 'Name', sprintf('Spectrogram: %s', stimWord));
end


if ~isempty(fsic(varargin, '--trialNum'))
    trialNum = varargin{fsic(varargin, '--trialNum') + 1};
end

errorBtnGrp = uibuttongroup('Position',[0 0.4 0.4 0.6], 'Units','Normalized','Title','ACCURACY');
errorBtns = nan(1, 5);
errorBtns(1) = uicontrol('Style','Radio', 'Parent',errorBtnGrp, 'HandleVisibility','off', 'Position',[15 150 135 30], 'String','Accurate', 'Tag','accurate');
errorBtns(2) = uicontrol('Style','Radio', 'Parent',errorBtnGrp, 'HandleVisibility','off', 'Position',[15 120 135 30], 'String','Silence', 'Tag','silence');
errorBtns(3) = uicontrol('Style','Radio', 'Parent',errorBtnGrp, 'HandleVisibility','off', 'Position',[15  90 135 30], 'String','Error, Use', 'Tag','error_use');
errorBtns(4) = uicontrol('Style','Radio', 'Parent',errorBtnGrp, 'HandleVisibility','off', 'Position',[15  60 135 30], 'String','Error, Unrecognizable', 'Tag','error_unrecog');
errorBtns(5) = uicontrol('Style','Radio', 'Parent',errorBtnGrp, 'HandleVisibility','off', 'Position',[15  30 135 30], 'String','Error, Unfinished', 'Tag','error_unfinish');

fluentBtnGrp = uibuttongroup('Position',[.4 0.4 0.4 0.6], 'Units','Normalized','Title','FLUENCY');
fluentBtns = nan(1, 5);
fluentBtns(1) = uicontrol('Style','Radio', 'Parent',fluentBtnGrp, 'HandleVisibility','off', 'Position',[15 150 135 30], 'String','Fluent', 'Tag','fluent');
fluentBtns(2) = uicontrol('Style','Radio', 'Parent',fluentBtnGrp, 'HandleVisibility','off', 'Position',[15 120 135 30], 'String','Stutter, Rep', 'Tag','st_rep');
fluentBtns(3) = uicontrol('Style','Radio', 'Parent',fluentBtnGrp, 'HandleVisibility','off', 'Position',[15  90 135 30], 'String','Stutter, Prolong', 'Tag','st_pro');
fluentBtns(4) = uicontrol('Style','Radio', 'Parent',fluentBtnGrp, 'HandleVisibility','off', 'Position',[15  60 135 30], 'String','Stutter, Mid-word block', 'Tag','st_block');
fluentBtns(5) = uicontrol('Style','Radio', 'Parent',fluentBtnGrp, 'HandleVisibility','off', 'Position',[15  30 135 30], 'String','Stutter, Cluster', 'Tag','st_clust');

confidenceGrp = uibuttongroup('Position',[0 0.2 0.8 0.2], 'Units','Normalized','Title','RATING CONFIDENCE');
cb_lowConfid_accuracy = ...
    uicontrol('Style', 'Checkbox', 'Parent', confidenceGrp, 'HandleVisibility', 'off', 'Position', [15 5 160 30], 'String', 'Accuracy - low confidence', 'Tag','fluent');
cb_lowConfid_fluency = ...
    uicontrol('Style', 'Checkbox', 'Parent', confidenceGrp, 'HandleVisibility', 'off', 'Position', [215 5 160 30], 'String', 'Fluency - low confidence', 'Tag','fluent');

starterGrp = uibuttongroup('Position',[0 0.0 0.8 0.2], 'Units','Normalized','Title','STARTER');
cb_starter = ...
    uicontrol('Style', 'Checkbox', 'Parent', starterGrp, 'HandleVisibility', 'off', 'Position', [15 5 160 30], 'String', 'Contains starter', 'Tag','fluent');

uicontrol('Style', 'pushbutton', 'String', 'Play', 'Position', [420 50 60 40], 'Callback', {@button2_callback, audioMode, y, fs});
uicontrol('Style', 'pushbutton', 'String', 'Submit', 'Position', [420 5 60 40], 'Callback', {@button_callback});

%% UI Controls for formant tracking
fmtTrackBtnGrp = uibuttongroup('Position',[0.8, 0.3, 0.195, 0.7], 'Units', 'Normalized', 'Title', 'Formants');

ui.lblNLPC = uicontrol('Style', 'text', 'Position', [420 290 60 20], ...
                       'HorizontalAlignment', 'left', ...
                       'String', 'LPC order: ');
ui.pmNLPC = uicontrol('Style', 'popupmenu', 'Position', [420 270 60 20], ...
                      'BackgroundColor', 'w');
strNLPC = cell(1, 0);
for i1 = 1 : numel(NLPC_OPTIONS);
    strNLPC{end + 1} = sprintf('%d', NLPC_OPTIONS(i1));
end
idxDef = find(NLPC_OPTIONS == NLPC_DEFAULT, 1);
set(ui.pmNLPC, 'String', strNLPC, 'Value', idxDef);

if ~isempty(fmtOpts)
    idx = find(NLPC_OPTIONS == fmtOpts.nLPC);
    set(ui.pmNLPC, 'Value', idx);
end

ui.lblAFact = uicontrol('Style', 'text', 'Position', [420 240 60 20], ...
                        'HorizontalAlignment', 'left', ...
                        'String', 'DP alpha: ');
ui.editAFact = uicontrol('Style', 'edit', 'Position', [420 220 60 20], ...
                         'BackgroundColor', 'w', ...
                         'HorizontalAlignment', 'left', ...
                         'String', sprintf('%.1f', ALPHA_DEFAULT));
if ~isempty(fmtOpts)
    set(ui.editAFact, 'String', sprintf('%.1f', fmtOpts.aFact));
end

ui.lblFN1 = uicontrol('Style', 'text', 'Position', [420 190 70 20], ...
                       'HorizontalAlignment', 'left', ...
                      'String', 'F1 Prior (Hz): ');
ui.editFN1 = uicontrol('Style', 'edit', 'Position', [420 170 60 20], ...
                       'BackgroundColor', 'w', ...
                       'HorizontalAlignment', 'left', ...
                       'String', sprintf('%.1f', FN1_DEFAULT));
if ~isempty(fmtOpts)
    set(ui.editFN1, 'String', sprintf('%.1f', fmtOpts.fn1));
end
                   
ui.lblFN2 = uicontrol('Style', 'text', 'Position', [420 140 70 20], ...\
                      'HorizontalAlignment', 'left', ...
                      'String', 'F2 Prior (Hz): ');
ui.editFN2= uicontrol('Style', 'edit', 'Position', [420 120 60 20], ...
                       'BackgroundColor', 'w', ...
                       'HorizontalAlignment', 'left', ...
                       'String', sprintf('%.1f', FN2_DEFAULT));
if ~isempty(fmtOpts)
    set(ui.editFN2, 'String', sprintf('%.1f', fmtOpts.fn2));
end

% Set callback functions
set(ui.pmNLPC, 'Callback', {@formantCbk, y, fs, ui, uihdls});
set(ui.editAFact, 'Callback', {@formantCbk, y, fs, ui, uihdls});
set(ui.editFN1, 'Callback', {@formantCbk, y, fs, ui, uihdls});
set(ui.editFN2, 'Callback', {@formantCbk, y, fs, ui, uihdls});

%% Display previous results
if ~isempty(fsic(varargin, '--data'))
    t_data = varargin{fsic(varargin, '--data') + 1};

    if isfield(t_data, 'accuracy') && ~isempty(t_data.accuracy) && ~isnan(t_data.accuracy)
        set(errorBtnGrp, 'SelectedObject', errorBtns(t_data.accuracy));
    end

    if isfield(t_data, 'fluency') && ~isempty(t_data.fluency) && ~isnan(t_data.fluency)
        set(fluentBtnGrp, 'SelectedObject', fluentBtns(t_data.fluency));
    end
    
    if isfield(t_data, 'accuracyLowConfid') && ~isempty(t_data.accuracyLowConfid) && ~isnan(t_data.accuracyLowConfid)
        set(cb_lowConfid_accuracy, 'Value', t_data.accuracyLowConfid);
    end
    
    if isfield(t_data, 'accuracyLowConfid') && ~isempty(t_data.fluencyLowConfid) && ~isnan(t_data.fluencyLowConfid)
        set(cb_lowConfid_fluency, 'Value', t_data.fluencyLowConfid);
    end
    
    if isfield(t_data, 'bStarter') && ~isempty(t_data.bStarter) && ~isnan(t_data.bStarter)
        set(cb_starter, 'Value', t_data.bStarter);
    end
    
    if isfield(t_data, 'fmtOpts')
        if isfield(t_data.fmtOpts, 'nLPC')
            set(ui.pmNLPC, 'Value', find(NLPC_OPTIONS == t_data.fmtOpts.nLPC, 1));
        end
        
        if isfield(t_data.fmtOpts, 'aFact')
            set(ui.editAFact, 'String', sprintf('%.1f', t_data.fmtOpts.aFact));
        end
        
        if isfield(t_data.fmtOpts, 'fn1')
            set(ui.editFN1, 'String', sprintf('%.1f', t_data.fmtOpts.fn1));
        end
        
        if isfield(t_data.fmtOpts, 'fn2')
            set(ui.editFN2, 'String', sprintf('%.1f', t_data.fmtOpts.fn2));
        end
    end
end

set(ui.hFig, 'Visible', 'on')        %# Make the GUI visible

%% Return values
hSpect = ui.hSpect;
hFig = ui.hFig;

%% Track formant (initial)
formantCbk([], [], y, fs, ui, uihdls);

%% Callback functions
function [returnVars] = button_callback(src, ev)
    %--- Write to image file ---%
    [tdir, tfn] = fileparts(uihdls.matFileName);
    imageDir = fullfile(tdir, 'images');
    if ~isdir(imageDir)
        mkdir(imageDir);
        info_log(sprintf('Created directory for images: %s', imageDir))
    end
    
    dateStr = datestr(now, 'yyyy-mm-ddTHH.MM.SS');
    imageFN = fullfile(imageDir, sprintf('%d_%s_%s.jpg', trialNum, stimWord, dateStr));
    
    set(0, 'CurrentFigure', ui.hSpect);
    saveas(gcf, imageFN, 'jpg');
    
    info_log(sprintf('Saved screenshot to image file: %s', imageFN));
    
    
    a = get(get(errorBtnGrp, 'SelectedObject'), 'Tag');
    b = get(get(fluentBtnGrp, 'SelectedObject'), 'Tag');    
    
    switch a
        case 'accurate'
            buttonVals{1} = 1;
        case 'silence'
            buttonVals{1} = 2;
        case 'error_use'
            buttonVals{1} = 3;
        case 'error_unrecog'
            buttonVals{1} = 4;
        case 'error_unfinish'
            buttonVals{1} = 5;
    end

    switch b
        case 'fluent'
            buttonVals{2} = 1;
        case 'st_rep'
            buttonVals{2} = 2;
        case 'st_pro'
            buttonVals{2} = 3;
        case 'st_block'
            buttonVals{2} = 4;
        case 'st_clust'
            buttonVals{2} = 5;
    end
    
    accuracyLowConfid = get(cb_lowConfid_accuracy, 'Value');
    fluencyLowConfid = get(cb_lowConfid_fluency, 'Value');
    bStarter = get(cb_starter, 'Value');

%     display('Submitting...');
%     done = 1;
    close(gcbf);
    
    
end


%% play sound
function [returnVars] = button2_callback(src, ev, audioMode, y, fs)
%         if ~isempty(strfind(lower(getenv('OS')), 'windows'))
    if isequal(audioMode, 'soundsc')
%         soundsc(y(1:round(recordTime*fs)), fs);
        soundsc(y, fs);
    elseif isequal(audioMode, 'wavplay')
%         wavplay(y(1:round(recordTime*fs)), fs);
        wavplay(y, fs);
    else
        ap = audioplayer(y(1:round(recordTime*fs)), fs);
        play(ap, 1);
    end
end

%%
uiwait;

%     global buttonVals done
%     global accuracyLowConfid
%     global fluencyLowConfid
%     global bStarter

retVals = struct;
retVals.buttonVals = buttonVals;
retVals.done = done;
retVals.accuracyLowConfid = accuracyLowConfid;
retVals.fluencyLowConfid = fluencyLowConfid;
retVals.bStarter = bStarter;



%%
end