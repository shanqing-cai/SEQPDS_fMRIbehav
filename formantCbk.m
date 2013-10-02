function formantCbk(src, evntDat, y, fs, ui, uihdls)
%% CONFIG
fs0 = 16000;
downSampFact = 3;
rmsThresh = 0.00;
rmsRatioThresh = 0.0;

%--- Formant tracking parameters ---%
% nLPC = 19;
% fn1 = 500;
% fn2 = 1500;

% aFact         = 10;
bFact         = 0.8;
gFact         = 1;

frameLen = 32;

bAudapterPrompt = 0;

%% Get formant tracking parameters from UI
nLPCOpts = get(ui.pmNLPC, 'String');
nLPC = str2double(nLPCOpts{get(ui.pmNLPC, 'Value')});
aFact = str2double(get(ui.editAFact, 'String'));
fn1 = str2double(get(ui.editFN1, 'String'));
fn2 = str2double(get(ui.editFN2, 'String'));

fs1 = fs0 * 3;

Audapter('setParam', 'srate', fs0, bAudapterPrompt);
Audapter('setParam', 'downfact', downSampFact, bAudapterPrompt);
Audapter('setParam', 'framelen', frameLen, bAudapterPrompt);
Audapter('setParam', 'rmsthr', rmsThresh, bAudapterPrompt);
Audapter('setParam', 'rmsratio', rmsThresh, bAudapterPrompt);

Audapter('setParam', 'nlpc', nLPC, bAudapterPrompt);
Audapter('setParam', 'fn1', fn1, bAudapterPrompt);
Audapter('setParam', 'fn1', fn2, bAudapterPrompt);
Audapter('setParam', 'afact', aFact, bAudapterPrompt);
Audapter('setParam', 'bfact', bFact, bAudapterPrompt);
Audapter('setParam', 'gfact', gFact, bAudapterPrompt);
y1 = resample(y, fs1, fs);
sigInCell = makecell(y1, frameLen * downSampFact);

Audapter('reset');
for n = 1 : length(sigInCell)
%     tic;
    Audapter(5, sigInCell{n});
end

% dataOut = AudapterIO('getData');
[sig, datMat] = Audapter('getData');

frameDur = frameLen / fs0;
fmt_time = 0 : frameDur : frameDur * (size(datMat, 1) - 1);
f1 = datMat(:, 5);
f2 = datMat(:, 6);

%% Pitch tracking    
[f0_time, f0_value, SHR, f0_candidates] = shrp(y, fs, [50, 400]);
f0_time = f0_time / 1e3;

%% Visualization
set(0, 'CurrentFigure', ui.hSpect);
clf;
% ui.hSpect = figure('Visible', 'on', 'Menu','none', 'Name','Calculator', 'Resize','on', 'Position',[100 350 1000 200]);    
subplot('Position', [0.05, 0.2, 0.9, 0.775]);

show_spectrogram(y, fs, 'noFig');    
xlabel('Time (s)');
ylabel('Frequency (Hz)');

% Show F0 and formants
plot(f0_time, f0_value, 'k-');
plot(fmt_time, [f1, f2], 'b-');
drawnow;

%% 
tidx = get(uihdls.trialListBox, 'Value');
load(uihdls.matFileName);

data{tidx}.fmtOpts = struct;
data{tidx}.fmtOpts.nLPC = nLPC;
data{tidx}.fmtOpts.aFact = aFact;
data{tidx}.fmtOpts.bFact = bFact;
data{tidx}.fmtOpts.gFact = gFact;
data{tidx}.fmtOpts.fn1 = fn1;
data{tidx}.fmtOpts.fn2 = fn2;

data{tidx}.f0_time = f0_time;
data{tidx}.f0 = f0_value;
data{tidx}.fmt_time = fmt_time;
data{tidx}.f1 = f1;
data{tidx}.f2 = f2;

save(uihdls.matFileName, 'data');

return