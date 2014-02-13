function warpAlign = dtw(w, fs, t0, t1, wt, fst, segInfo)
%% Input arguments
% w :   input waveform
% fs :  input sampling rate (Hz)
% t0 :  onset time of the segment to be warped (s)
% t1 :  offset time of the segment to be warped (s)
% wt :  template waveform
% fst : template sampling rate (Hz)

%% Set path to dtwMex
dmPath = which('dtwMex');
if isempty(dmPath)
    error('Cannot find path to dtwMex');
end

%%
tAxis = 0 : (1 / fs) : (1 / fs) * length(w);
wi = w(tAxis > t0 & tAxis < t1);

wt = resample(wt, fs, fst);

%% Compute spectrograms
[sp, f, t] = spectrogram(wi, 256, 192, 1024, fs);
sp = 20 * log10(abs(sp));

[spt, ft, tt] = spectrogram(wt, 256, 192, 1024, fs);
spt = 20 * log10(abs(spt));

sp = sp - mean(sp(:));
spt = spt - mean(spt(:));

%% Call the core MEX
[minDists, optPath] = dtwMex(spt, sp);

pathMat = zeros(size(spt, 2), size(sp, 2));
for i1 = 1 : size(optPath)
    pathMat(optPath(i1, 1), optPath(i1, 2)) = 1;
end

%% Compute segment times
warpAlign.nSegs = segInfo.nSegs;
warpAlign.tBeg = nan(1, warpAlign.nSegs);
warpAlign.tEnd = nan(1, warpAlign.nSegs);

for i1 = 1 : segInfo.nSegs;
    idx_beg_0 = find(tt >= segInfo.tBeg(i1), 1, 'first');
    idx_beg_1 = find(pathMat(idx_beg_0, :), 1, 'first');    
    warpAlign.tBeg(i1) = t(idx_beg_1);
    
    idx_end_0 = find(tt <= segInfo.tEnd(i1), 1, 'last');
    idx_end_1 = find(pathMat(idx_end_0, :), 1, 'last');
    warpAlign.tEnd(i1) = t(idx_end_1);
end


return