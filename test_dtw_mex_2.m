function test_dtw_mex_2
%% Config
% matFileName = 'SEQ03C01_behavioral\trials_prac1_scai.mat';
% matFileName = 'SEQ04P18_behavioral\trials_test1_scai2.mat';
% matFileName = 'SEQ04P18_behavioral\trials_test4_scai2.mat';
% matFileName = 'SEQ04P18_behavioral\trials_test8_scai2.mat';
% matFileName = 'SEQ03P13_behavioral\trials_test1_scai30.mat';
matFileName = 'C:\DATA\SEQPDS\SEQ03P13_behavioral\trials_test1_scai30.mat';

%--- SPLERST ---%
% trialNum1 = 1;
% trialNum1 = 86;

%--- VGAMSH ---%
% trialNum1 = 2;

%--- VTHASHP ---%
% trialNum1 = 3;

%--- PTACHST ---%
% trialNum1 = 4;

%--- GVAZF ---%
trialNum1 = 24;

%--- KLELTH ---%
% trialNum1 = 8;

%--- FREMP ---%
% trialNum1 = 10;
% trialNum1 = 11;

stimDir = './stim';

YMax = 5000;

%%
load(matFileName);

stimWord = data{trialNum1}.stimWord;

wavFN1 = data{trialNum1}.recordFile;
[w1, fs1] = wavread(wavFN1);

taxis1 = 0 : (1 / fs1) : (1 / fs1) * length(w1);
w1 = w1(taxis1 > data{trialNum1}.times(2) & taxis1 < data{trialNum1}.times(3));

%% Load the stim file
stimWC = fullfile(stimDir, ['*_', stimWord, '.wav']);
stimD = dir(stimWC);
segInfoMat = fullfile(stimDir, strrep(stimD(1).name, '.wav', '.mat'));

if length(stimD) ~= 1
    error('Not exactly one matching .wav file for stimulus word "%s" is found', stimWord);
end
stimFN = fullfile(stimDir, stimD(1).name);

[w0, fs0] = wavread(stimFN);
w0 = resample(w0, fs1, fs0);

%% Manual segmentation
if ~isfile(segInfoMat)
    soundsc(w0, fs1);
    hf = figure('Name', stimWord, 'Position', [50, 150, 1000, 400]);
    show_spectrogram(w0, fs1, 'noFig');
    xlabel('Time (s)');
    ylabel('Frequency (Hz)');
    title(sprintf('Template for %s', stimWord));
    
    nSegs = input('Number of segments: ');
    tBeg = nan(1, nSegs);
    tEnd = nan(1, nSegs);
    segNames = cell(1, nSegs);

    ts = nan(1, nSegs + 1);
    ys = get(gca, 'YLim');
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

    save(segInfoMat, 'segInfo');
    fprintf(1, 'segInfo saved to file: %s\n', segInfoMat);
else
    fprintf(1, 'Loading segInfo from file: %s\n', segInfoMat);
    load(segInfoMat);
    assert(exist('segInfo') == 1);
end

%% Compute spectrograms
[sp0, f0, t0] = spectrogram(w0, 256, 192, 1024, fs1);
sp0 = 20 * log10(abs(sp0));

[sp1, f1, t1] = spectrogram(w1, 256, 192, 1024, fs1);
sp1 = 20 * log10(abs(sp1));
% sp1 = 20 * log10(abs(spectrogram(w1, 256, 192, 1024, fs1)));

sp0 = sp0 - mean(sp0(:));
sp1 = sp1 - mean(sp1(:));

%%
% tic;
[minDists, optPath] = dtwMex(sp0, sp1);
% toc;

%% Compute distance matrix
% tic;
% dm = diff_matrix(sp1, sp2);
% toc;
% % dm(111, 200)
% 
% %% 
% [minDists, optPath] = dtw(dm);

pathMat = zeros(size(sp0, 2), size(sp1, 2));
for i1 = 1 : size(optPath)
    pathMat(optPath(i1, 1), optPath(i1, 2)) = 1;
end

% figure; imagesc(pathMat); axis xy;

%% Compute segment times
warpAlign.nSegs = segInfo.nSegs;
warpAlign.tBeg = nan(1, warpAlign.nSegs);
warpAlign.tEnd = nan(1, warpAlign.nSegs);

for i1 = 1 : segInfo.nSegs;
    idx_beg_0 = find(t0 >= segInfo.tBeg(i1), 1, 'first');
    idx_beg_1 = find(pathMat(idx_beg_0, :), 1, 'first');    
    warpAlign.tBeg(i1) = t1(idx_beg_1);
    
    idx_end_0 = find(t0 <= segInfo.tEnd(i1), 1, 'last');
    idx_end_1 = find(pathMat(idx_end_0, :), 1, 'last');
    warpAlign.tEnd(i1) = t1(idx_end_1);
end

%% Show results
figure;
for i1 = 1 : 2
    if i1 == 1
        sp = sp0;
        f = f0;
        t = t0;
        si = segInfo;
        ttl = sprintf('Template: %s', stimWord);
    else
        sp = sp1;
        f = f1;
        t = t1;
        si = warpAlign;
        ttl = sprintf('Input: %s', stimWord);
    end
    
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
        
end

soundsc(w0, fs1);
soundsc(w1, fs1);


return

