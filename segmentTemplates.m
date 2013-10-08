function segmentTemplates(varargin)
%% Constants
stimDir = './stim';
excludeTokens = {'beep'};

%%
if ~isdir(stimDir)
    error('Cannot find the directory that contains the template wav files: %s', stimDir);
end

[~, hostName] = system('hostname');

uidat = struct;
uidat.hostName = hostName;
uidat.stimDir = stimDir;
uidat.excludeTokens = excludeTokens;

%% Generate the GUI
uidat.fig = figure('Position', [80, 180, 1200, 400], 'Name', 'Template segmentation');

uidat.list = uicontrol('Parent', uidat.fig, 'Style', 'listbox', ...
                        'Unit', 'Normalized', 'Position', [0.05, 0.2, 0.2, 0.75], ...
                        'BackgroundColor', 'w', 'FontName', 'Fixedwidth');

uidat.segButton = uicontrol('Parent', uidat.fig, 'Style', 'pushbutton', ...
                             'Unit', 'Normalized', 'Position', [0.05, 0.05, 0.2, 0.1], ...
                             'String', 'Segment');
uidat.redoButton = uicontrol('Parent', uidat.fig, 'Style', 'pushbutton', ...
                             'Unit', 'Normalized', 'Position', [0.75, 0.05, 0.2, 0.1], ...
                             'String', 'Redo segment');
                         
uidat.selPlayButton = uicontrol('Parent', uidat.fig, 'Style', 'pushbutton', ...
                                'Unit', 'Normalized', 'Position', [0.325, 0.05, 0.2, 0.075], ...
                                'String', 'Select and Play');
                            
uidat.axes = axes('Parent', uidat.fig, ...
                  'Unit', 'Normalized', 'Position', [0.325, 0.2, 0.625, 0.75]);

%% Set callback functions
set(uidat.segButton, 'Callback', {@segmentCbk, uidat});
set(uidat.redoButton, 'Callback', {@segmentCbk, uidat});
set(uidat.selPlayButton, 'Callback', {@selPlayCbk, uidat});

set(uidat.selPlayButton, 'Enable', 'off');
set(uidat.redoButton, 'enable', 'off');

refreshList(uidat);

return

function stat = getStat(uidat)
%% Get the list of template files
d = dir(fullfile(uidat.stimDir, '*.wav'));

stat.words = {};
for i1 = 1 : numel(d)
    t_word = strrep(d(i1).name, '.wav', '');
    if ~isempty(fsic(uidat.excludeTokens, t_word)) || isempty(t_word)
        continue;
    end
    stat.words{i1} = t_word;
end

%% Get the status of the segmentation
stat.segDone = zeros(size(stat.words));

for i1 = 1 : numel(stat.words)
    t_mat = fullfile(uidat.stimDir, sprintf('%s.mat', stat.words{i1}));
    if isfile(t_mat)
        stat.segDone(i1) = 1;
    end
end
return

function selPlayCbk(src, evnt, uidat)
stat = getStat(uidat);

set(0, 'CurrentFigure', uidat.fig);
set(gcf, 'CurrentAxes', uidat.axes);

ttl = strrep(get(get(gca, 'Title'), 'String'), '\_', '_');
if isempty(ttl)
    info_log('Cannot determine the template word', '-warn');
end

word = strrep(ttl, 'Template for ', '');
wavFN = fullfile(uidat.stimDir, sprintf('%s.wav', word));
[w, fs] = wavread(wavFN);

crds = ginput(2);
ts = sort(crds(:, 1));

tAxis = 0 : (1 / fs) : (1 / fs) * (length(w) - 1);
wseg = w(tAxis >= ts(1) & tAxis < ts(2));

ys = get(gca, 'YLim');
hpatch = patch([ts(1), ts(2), ts(2), ts(1)], [ys(1), ys(1), ys(2), ys(2)], [1, 0.5, 0.5], ...
               'FaceAlpha', 0.5);
drawnow;

soundsc(wseg, fs);
pause(0.2);

delete(hpatch);

return

function refreshList(uidat)
stat = getStat(uidat);

statList = cell(size(stat.words));
for i1 = 1 : numel(stat.words)
    if stat.segDone(i1)
        statStr = '[V]';
    else
        statStr = '[_]';
    end
    
    statList{i1} = sprintf('%s %s', statStr, stat.words{i1});
end

set(uidat.list, 'String', statList);

return

function showSeg(uidat, segInfo, w, fs, word, varargin)
set(uidat.selPlayButton, 'Enable', 'off');
set(uidat.redoButton, 'enable', 'off');

set(0, 'CurrentFigure', uidat.fig);
set(gcf, 'CurrentAxes', uidat.axes);
cla;

show_spectrogram(w, fs, 'noFig');
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title(sprintf('Template for %s', strrep(word, '_', '\_')));

xs = get(gca, 'XLim');
ys = get(gca, 'YLim');

soundsc(w, fs);

if isempty(segInfo)
    nSegs = input('Number of segments: ');
    tBeg = nan(1, nSegs);
    tEnd = nan(1, nSegs);
    segNames = cell(1, nSegs);

    ts = nan(1, nSegs + 1);
    
    for i1 = 1 : nSegs + 1
        crd = ginput(1);  

        plot(repmat(crd(1), 1, 2), ys, 'k-');

        ts(i1) = crd(1);
    end

    for i1 = 1 : nSegs
        tBeg(i1) = ts(i1);
        tEnd(i1) = ts(i1 + 1);
        segNames{i1} = input(sprintf('Name of segment #%d: ', i1), 's');

        text(0.5 * (tBeg(i1) + tEnd(i1)), ys(2) - 0.1 * range(ys), segNames{i1});
    end

    segInfo = struct;
    segInfo.nSegs = nSegs;
    segInfo.tBeg = tBeg;
    segInfo.tEnd = tEnd;
    segInfo.segNames = segNames;
    
    %--- Signature information ---%
    segInfo.hostName = uidat.hostName;
    segInfo.timeStamp = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
    
    segInfoMat = fullfile(uidat.stimDir, sprintf('%s.mat', word));
    save(segInfoMat, 'segInfo');
    fprintf(1, 'segInfo saved to file: %s\n', segInfoMat);
    
    set(uidat.redoButton, 'enable', 'on');
else    
    for i1 = 1 : segInfo.nSegs
        plot(repmat(segInfo.tBeg(i1), 1, 2), ys, 'k-');
        text(0.5 * (segInfo.tBeg(i1) + segInfo.tEnd(i1)), ...
             ys(2) - 0.1 * range(ys), segInfo.segNames{i1});
    end
    plot(repmat(segInfo.tEnd(end), 1, 2), ys, 'k-');
    
    signStr = strrep(sprintf('Segmented on %s @ %s', segInfo.hostName, segInfo.timeStamp), '_', '\_');
    
    text(xs(1) + 0.05 * range(xs), ys(1) + 0.075 * range(ys), ...
         signStr);
     
    set(uidat.redoButton, 'enable', 'on');
end

set(uidat.selPlayButton, 'Enable', 'on');

return

function segmentCbk(src, evnt, uidat)
val = get(uidat.list, 'Value');
stat = getStat(uidat);
word = stat.words{val};

wavFN = fullfile(uidat.stimDir, sprintf('%s.wav', word));
[w, fs] = wavread(wavFN);

matFN = fullfile(uidat.stimDir, sprintf('%s.mat', word));

%% Confirm overwrite
if src == uidat.redoButton
    assert(exist('segInfo') ~= 1);
    load(matFN);
    assert(exist('segInfo') == 1);
    
    questStr = sprintf('Do you want to overwrite the segment results from %s @ %s?', ...
                       segInfo.hostName, segInfo.timeStamp);
    a = questdlg(questStr, 'Confirm overwrite', 'Yes', 'No', 'No');
    
    if isequal(lower(a), 'no') || isempty(a)
        return
    else
        delete(matFN);
        stat.segDone(val) = 0;
    end
end

%%
if stat.segDone(val) == 1
    clear('segInfo');
    
    assert(exist('segInfo') ~= 1);
    load(matFN);
    assert(exist('segInfo') == 1);
else
    segInfo = [];    
end

showSeg(uidat, segInfo, w, fs, word);

refreshList(uidat);

return