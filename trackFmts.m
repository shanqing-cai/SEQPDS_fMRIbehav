function [fmt_time, f1, f2] = trackFmts(y, fs)
%% CONFIG
fs0 = 16000;
downSampFact = 3;
rmsThresh = 0.00;
rmsRatioThresh = 0.0;

%--- Formant tracking parameters ---%
nLPC = 19;
fn1 = 500;
fn2 = 1500;

aFact         = 10;
bFact         = 0.8;
gFact         = 1;

frameLen = 32;

bAudapterPrompt = 0;

%% 
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
return