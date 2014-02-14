function dtw_wrapper(inWavFN, procMatFN, varargin)
%% Config
TEMPLATE_DIR = 'stim';
YMax = 4000;

%% Process directory names
TEMPLATE_DIR = fullfile(pwd, TEMPLATE_DIR);
check_dir(TEMPLATE_DIR);

%% Determine the stimulus name
check_file(inWavFN);

[inWavDir, inWavF, ext] = fileparts(inWavFN);
fitems = splitstring(inWavF, '_');

if ~isequal(ext, '.wav') || ...
   length(strfind(inWavF, '_')) ~= 2 || ...
   length(fitems) ~= 3
   error('Unrecognized file name: %s', inWavF);
end

trialNum = str2double(fitems{2});
stim = fitems{3};

%% Load the time labels in procMat
check_file(procMatFN);

assert(exist('data', 'var') == 0);
load(procMatFN);
assert(exist('data', 'var') == 1);

if length(data) < trialNum || isempty(data{trialNum})
    error('Cannot find entry for trial %s in .mat file %s', inWavF, procMatFN);
end

datWavFN = data{trialNum}.recordFile;
[datWavDir, datWavF, datExt] = fileparts(datWavFN);
if ~isequal(datWavF, inWavF)
    error('Mismatch in .wav file name: %s <> %s', inWavF,datWavF);
end

if length(data{trialNum}.times) ~= 3
    error('Unexpected length in data{%d}.times, possibly due to incomplete preprocessing.', trialNum);
end
t0 = data{trialNum}.times(2);
t1 = data{trialNum}.times(3);

if t0 >= t1
    error('The time marks seems to be erroneous: t0 >= t1');
end

%% Load the template file and 
twc = dir(fullfile(TEMPLATE_DIR, sprintf('*%s.wav', stim)));
if length(twc) ~= 1
    error('Cannot find exactly 1 .wav file for stimulus: %s', stim);
end

tempWavFN = fullfile(TEMPLATE_DIR, twc(1).name);
check_file(tempWavFN);

%% Load the template segmentation file
segwc = dir(fullfile(TEMPLATE_DIR, sprintf('*%s.mat', stim)));
if length(twc) ~= 1
    error('Cannot find exactly 1 .mat template segmentation file for stimulus: %s', stim);
end

segFN = fullfile(TEMPLATE_DIR, segwc(1).name);
check_file(segFN);

assert(exist('segInfo', 'var') == 0);
load(segFN);
assert(exist('segInfo', 'var') == 1);

%% Load waveforms
[w, fs] = wavread(inWavFN);
[wt, fst] = wavread(tempWavFN);

%% Call core MEX
warpAlign = dtw(w, fs, t0, t1, wt, fst, segInfo);

warpAlign.tBeg = warpAlign.tBeg + t0;
warpAlign.tEnd = warpAlign.tEnd + t1;

%%
if ~isempty(fsic(varargin, '--show'))
    figure;
    for i1 = 1 : 2
        if i1 == 1
            t_w = wt;
            t_fs = fst;
            si = segInfo;
            ttl = sprintf('Template: %s', stim);
        else
            t_w = w;
            t_fs = fs;
            si = warpAlign;
            ttl = sprintf('Input: %s', stim);
        end
        
        [sp, f, t] = spectrogram(t_w, 256, 192, 1024, t_fs);
        sp = 10 * log10(abs(sp));

        subplot(2, 1, i1);
        hold on;
        imagesc(t, f, sp);
        set(gca, 'XLim', [t(1), t(end)], 'YLim', [f(1), YMax]);
        axis xy;

        xs = get(gca, 'XLim');
        ys = get(gca, 'YLim');

        for i2 = 1 : si.nSegs
            plot(repmat(si.tBeg(i2), 1, 2), ys, 'k-');

        end

        set(gca, 'XLim', xs, 'YLim', ys);

        xlabel('Time (s)');
        ylabel('Frequency (Hz)');
        title(ttl);
        
        if i1 == 2
            set(gca, 'XLim', [t0, t1]);
        end

    end
end

return