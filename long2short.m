function long2short(longDir, shortDir, outDir)
%% 
% long2short: cut long wav files that correspond to runs into short wav
%             files that correspond to trials.

%% Constants
RMS_WIN = 0.020;    % Unit: s
SEG_DUR_THRESH = 2.0;     % Unit: s

%%
dl = dir(fullfile(longDir, '*_test*.wav'));
if isempty(dl)
    error('Cannot find test wav files in long directory: %s', longDir);
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
        if length(fnItems{i2}) > 4 && isequal(fnItems{i2}(1 : 4), 'test')
            runNum = str2double(strrep(fnItems{i2}, 'test', ''));
            break;
        end
    end
    assert(~isnan(runNum));
    
    dsh = dir(fullfile(shortDir, sprintf('test%d_*_*.wav', runNum)));
    
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
    nw = round(RMS_WIN * fs);
    r = st_rms(wl, nw);
    
    cla; hold on;
    tAxis = 0 : RMS_WIN : RMS_WIN * (length(r) - 1);
    plot(tAxis, r);
    set(gca, 'XLim', [tAxis(1), tAxis(end)]);
    
    coords = ginput(1);
    rthr = coords(2);
    plot([tAxis(1), tAxis(end)], repmat(rthr, 1, 2), 'r-');
    xlabel('Time in run(s)');   
    ylabel('Short-time RMS intensity');
    
    [t_on, t_off] = get_cont_stretches(r > rthr);
    assert(length(t_on) == length(t_off));
    int_lens = (t_off - t_on - 1) * RMS_WIN;
    
    iValidSegs = find(int_lens > SEG_DUR_THRESH);
    t_on = (t_on(iValidSegs) - 1) * RMS_WIN;
    t_off = (t_off(iValidSegs) - 1) * RMS_WIN;
    
    ys = get(gca, 'YLim');
    for i2 = 1 : numel(t_on)
        plot(repmat(t_on(i2), 1, 2), ys, 'm--');
        plot(repmat(t_off(i2), 1, 2), ys, 'm-');
    end
    drawnow;
    
    scanDurs = t_off - t_on;
    xs = get(gca, 'XLim'); ys = get(gca, 'YLim');
    text(xs(1) + 0.05 * range(xs), ys(2) - 0.05 * range(ys), ...
         sprintf('Found %d scans', length(t_on)));
	text(xs(1) + 0.05 * range(xs), ys(2) - 0.10 * range(ys), ...
         sprintf('Scan duration (s): mean=%.3f; min=%.3f; max=%.3f', ...
                 mean(scanDurs), min(scanDurs), max(scanDurs)));
             
    % -- Serially extract new short wav files -- %
    for i2 = 1 : numel(shtns)
        tn = shtns(i2);
        
        idx0 = find(tAxis > t_off(tn), 1);
        idx1 = max(find(tAxis < t_on(tn + 1)));
        idx0 = idx0 * nw + 1;
        idx1 = idx1 * nw;
        ws = wl(idx0 : idx1);
        
        fprintf(1, '%s: dur = %.3f s\n', shfns{i2}, length(ws) / fs);
        wavplay(ws, fs);
        
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
