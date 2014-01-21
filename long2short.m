function long2short(longDir, shortDir, outDir, in_runNum, shOnset, shDur, varargin)
%% 
% long2short: cut long wav files that correspond to runs into short wav
%             files that correspond to trials.

%% Constants
RMS_WIN = 0.020;    % Unit: s
SEG_DUR_THRESH = 2.0;     % Unit: s
SEG_DUR_THRESH_PRACT_TONE = 0.0064 * 2;
FILL_GAP_MAX_DUR = 0.0064 * 40;

fs_low = 10000; % Hz


PRAC_TONE_FREQ = 500;    % Hz
PRAC_TONE_FREQ_TOL = 0.05;   % Hz; single-sided
PRAC_TONE_DUR = 0.10; % s

TONE_IGAP_MAX_LEN = 2;
TONE_ILEN_THRESH = 15;

%% Optional arguments
if ~isempty(fsic(varargin, '--skip'))
    nSkip = varargin{fsic(varargin, '--skip') + 1};
else
    nSkip = 0;
end

if ~isempty(fsic(varargin, '--skip-trials'))
    if ~isempty(fsic(varargin, '--skip'))
        error('Options --skip and --skip-trials are not allowed to be used simultaneously')
    end
    
    skipTNs = varargin{fsic(varargin, '--skip-trials') + 1};
    assert(~isempty(skipTNs));
    
    if length(skipTNs) ~= length(unique(skipTNs))
        error('Skipped trial numbers are not unique');
    end
else
    skipTNs = [];
end

runType = 'test';
if ~isempty(fsic(varargin, '--run-type'))
    runType = varargin{fsic(varargin, '--run-type') + 1};
end

if ~isempty(fsic(varargin, '--add-t-on'))
    manAddTOn = varargin{fsic(varargin, '--add-t-on') + 1};
else
    manAddTOn = [];
end

if ~isempty(fsic(varargin, '--tone-ilen-thresh'))
    TONE_ILEN_THRESH = varargin{fsic(varargin, '--tone-ilen-thresh') + 1};
end

if ~isempty(fsic(varargin, '--tone-igap-max-len'))
    TONE_IGAP_MAX_LEN = varargin{fsic(varargin, '--tone-igap-max-len') + 1};
end

%%
dl = dir(fullfile(longDir, sprintf('*_%s*.wav', runType)));
if isempty(dl)
    error('Cannot find %s wav files in long directory: %s', runType, longDir);
end

if ~isdir(outDir)
    mkdir(outDir);
    fprintf(1, 'INFO: Created output directory: %s\n', outDir);
end

%%
figure('Position', [50, 150, 1200, 400]);
subplot('Position', [0.05, 0.1, 0.9, 0.85]);
for i1 = 1 : numel(dl)
    wlfn = fullfile(longDir, dl(i1).name);
    
    % -- Look for trials in the short directory -- %
    dfn = strrep(dl(i1).name, '_', '.');
    fnItems = splitstring(dfn, '.');
    runNum = NaN;
    for i2 = 1 : numel(fnItems)
        if length(fnItems{i2}) > 4 && isequal(fnItems{i2}(1 : 4), runType)
            runNum = str2double(strrep(fnItems{i2}, runType, ''));
            break;
        end
    end
    assert(~isnan(runNum));
    
    if runNum ~= in_runNum
        continue;
    end
    
    dsh = dir(fullfile(shortDir, sprintf('%s%d_*_*.wav', runType, runNum)));
    
    % -- Sort the short file names by trial number -- %
    shfns = {};
    shtns = [];
    for i2 = 1 : numel(dsh)
        tfn = strrep(dsh(i2).name, '.wav', '');
        assert(length(strfind(tfn, '_')) == 2);
        
        tItems = splitstring(tfn, '_');
        tn = str2double(tItems{2});
        
        shtns(end + 1) = tn;
        shfns{end + 1} = dsh(i2).name;
    end
    
    [shtns, idxsrt] = sort(shtns, 'ascend');
    shfns = shfns(idxsrt);
    
    % -- Read wav data and manually determine the RMS threshold -- %
    [wl, fs] = wavread(wlfn);    
    % DEBUG
%     wl = wl(1 : round(length(wl) / 10));
    % ~DEBUG
    
    
    if isequal(runType, 'prac')
        %-- Calculate zero crossings --%
        wl = wl - mean(wl);
        izc = find(wl(1 : end - 1) .* wl(2 : end) <= 0);
        if izc(end) == length(wl)
            izc = izc(1 : end - 1);
        end
        x0zc = wl(izc);
        x1zc = wl(izc + 1) - wl(izc);
        
%         clear('wl');    % DEBUG
        
        fzc = -x0zc ./ x1zc;
        izc = izc + fzc;
        tzc = izc / fs;
        dzc = diff(tzc);
        
        tonePer = 1 / PRAC_TONE_FREQ / 2;
        tonePerUB = tonePer * (1 + PRAC_TONE_FREQ_TOL);
        tonePerLB = tonePer * (1 - PRAC_TONE_FREQ_TOL);
        
        btone = (dzc > tonePerLB) & (dzc < tonePerUB);
        
%         [iton, itoff] = get_cont_stretches(btone);
        [iton, itoff] = fill_gaps(btone, TONE_IGAP_MAX_LEN);
        tint_lens = (itoff - iton - 1);
        iValidTSegs = find(tint_lens > TONE_ILEN_THRESH);
        iton = iton(iValidTSegs);
        itoff = itoff(iValidTSegs);
        
        vizc = izc(iton);   % Valid zero crossings
        pause(0);   % DEBUG
%         matFN = strrep(wlfn, '.wav', '_spec.mat');
%         if ~isfile(matFN)
%             fprintf(1, 'Detecting practice trigger tones...');
% 
%             wls = resample(wl, fs_low, fs);
% %             clear('wl');
% 
%             win = 256;
%             overlap = 192;
%             nfft = 512;
% 
%             segLen = win * 4e3;
%             a_tv = [];
%             for j1 = 1 : ceil(length(wls) / segLen)
%                 wls_seg = wls((j1 - 1) * segLen + 1 : min([j1 * segLen, length(wls)]));
%                 [s, f, t]=spectrogram(wls_seg, win, overlap, nfft, fs_low);
% 
%                 s = 20 * log10(abs(s));
%     %             s = s.';
% 
%                 t_diff = mean(s(14 : 2 : 254, :), 1) - mean(s(13 : 2 : 253, :), 1);
% 
%                 clear('s', 'f');
%                 a_tv = [a_tv, t_diff];
% 
%     %             fPeak = fPracTone * [1 : 10];
%     %             fTrough = fPracTone * [0.5 : 1.0 : 9.5];
%     %             
%     %             [fm, tm] = meshgrid(f, t.');
%     %             [fpm, tpm] = meshgrid(fPeak, t.');
%     %             [ftm, ttm] = meshgrid(fTrough, t.');
%     %             
%     %             sp = interp2(fm, tm, s, fpm, tpm);
%     %             st = interp2(fm, tm, s, ftm, ttm);
%     %             
%     %             clear('s', 'f');
%     %             t_diff = sum(sp, 2) - sum(st, 2);
%             end
%             dt = t(2) - t(1);
% 
%             fprintf(1, '\n');
% 
%             save(matFN, 'a_tv', 'dt');
%             fprintf(1, 'Saved spectral info to file %s\n', matFN);
%         else
%             load(matFN);
%             fprintf(1, 'Loaded spectral info to file %s\n', matFN);
%         end
    
    end
    
%     if isequal(runType, 'test')
        nw = round(RMS_WIN * fs);
        r = st_rms(wl, nw);
        tAxis = 0 : RMS_WIN : RMS_WIN * (length(r) - 1);
%     else
%         nw = round(dt * fs);
%         r = a_tv;
%         tAxis = 0 : dt : (length(r) - 1) * dt;
%     end

    cla; hold on;
    plot(tAxis, r);
    set(gca, 'XLim', [tAxis(1), tAxis(end)]);
    
    if isequal(runType, 'test')
        coords = ginput(1);
        rthr = coords(2);
        plot([tAxis(1), tAxis(end)], repmat(rthr, 1, 2), 'r-');
    end
    xlabel('Time in run(s)');   
    ylabel('Short-time RMS intensity');
    
    if isequal(runType, 'test')    
        [t_on, t_off] = get_cont_stretches(r > rthr);
        assert(length(t_on) == length(t_off));
    else
        t_on = vizc / fs;
    end
%     else
%         [t_on, t_off] = fill_gaps(r > rthr, round(FILL_GAP_MAX_DUR / dt));
%     end
    
    
    if isequal(runType, 'test')
        int_lens = (t_off - t_on - 1) * RMS_WIN;
        iValidSegs = find(int_lens > SEG_DUR_THRESH);
        t_on = (t_on(iValidSegs) - 1) * RMS_WIN;
        t_off = (t_off(iValidSegs) - 1) * RMS_WIN;
%     else
%         int_lens = (t_off - t_on + 1) * dt;
%         iValidSegs = find(int_lens > SEG_DUR_THRESH_PRACT_TONE);
%         t_on = (t_on(iValidSegs) - 1) * dt;
%         t_off = (t_off(iValidSegs) - 1) * dt;
    end
    
    ys = get(gca, 'YLim');
    for i2 = 1 : numel(t_on)
        if isequal(runType, 'test')
            plot(repmat(t_on(i2), 1, 2), ys, 'm--');
            plot(repmat(t_off(i2), 1, 2), ys, 'm-');
        else
            plot(repmat(t_on(i2), 1, 2), ys, 'm-');
        end
    end
    drawnow;
    
    xs = get(gca, 'XLim'); ys = get(gca, 'YLim');
    if isequal(runType, 'test')
        scanDurs = t_off - t_on;        
        text(xs(1) + 0.05 * range(xs), ys(2) - 0.05 * range(ys), ...
             sprintf('Found %d scans', length(t_on)));
    	text(xs(1) + 0.05 * range(xs), ys(2) - 0.10 * range(ys), ...
             sprintf('Scan duration (s): mean=%.3f; min=%.3f; max=%.3f', ...
                     mean(scanDurs), min(scanDurs), max(scanDurs)));
    	drawnow;
    else
        text(xs(1) + 0.05 * range(xs), ys(2) - 0.05 * range(ys), ...
             sprintf('Found %d scans', length(t_on)));
    end
    drawnow;
             
    % -- Serially extract new short wav files -- %
%     if ~isempty(skipTNs)
%         origLen = length(shtns);
%         shtns = setxor(shtns, skipTNs);
%         if length(shtns) ~= origLen - length(skipTNs)
%             error('Error during manual skipping of trials with the --skip-trials option. Either the trials numbers to be skipped are not unique, or they contain trial numbers that are not speech trials');
%         end
%     end
    
    if isequal(runType, 'prac') && ~isempty(manAddTOn)
%         mean_diff = mean(t_off - t_on);
        t_on = [t_on; manAddTOn];
%         t_off = [t_off, manAddTOn + mean_diff];
        
        t_on = sort(t_on);
%         t_off = sort(t_off);
    end

%     sidx = 1 + nSkip;
    cumSkip = 0;
    for i2 = 1 + nSkip : numel(shtns)                
%         if ~isempty(find(skipTNs == i2, 1))
%             sidx = sidx + 1;
%         end
        
        if nSkip == 0
            tn = shtns(i2);
        else
            tn = shtns(i2) - shtns(nSkip);
        end
        
        if ~isempty(find(skipTNs == tn, 1))
            cumSkip = cumSkip + 1;
        end
        tn = tn + cumSkip;
        
        if isequal(runType, 'test') && (tn + 1 > length(t_on))
            fprintf(1, 'Warning: skipping trial %s due to skipped trigger(s)\n', shfns{i2});
            continue;
        end
        
        if isequal(runType, 'test')
            idx0 = find(tAxis > t_off(tn) + shOnset, 1);
            idx1 = find(tAxis > t_off(tn) + shOnset + shDur, 1);
    
            idx0 = idx0 * nw + 1;
            idx1 = idx1 * nw;
        else            
            idx0 = round((t_on(tn) + PRAC_TONE_DUR + shOnset) * fs);
            idx1 = round((t_on(tn) + PRAC_TONE_DUR + shOnset + shDur) * fs);
        end
        ws = wl(idx0 : idx1);
        
        if isequal(runType, 'test')
            fprintf(1, '%s: dur = %.3f s --> %.3f s\n', shfns{i2}, ...
                    t_on(tn + 1) - t_off(tn), length(ws) / fs);
        else
            fprintf(1, '%s: dur = %.3f s --> %.3f s\n', shfns{i2}, ...
                    t_on(tn) + PRAC_TONE_DUR + shOnset, t_on(tn) + PRAC_TONE_DUR + shOnset + shDur);
        end
%         wavplay(ws, fs);
        
        outwfn = fullfile(outDir, shfns{i2});
        wavwrite(ws, fs, outwfn);
        
%         sidx = sidx + 1;
    end
end

return

%% Sobroutine for calculating the short-time RMS
function r = st_rms(x, n)
x = x - mean(x);
r = nan(floor(length(x) / n), 1);

for i1 = 1 : floor(length(x) / n)
    xx = x((i1 - 1) * n + 1 : i1 * n);
    r(i1) = sqrt(mean(xx .^ 2));
end
return
