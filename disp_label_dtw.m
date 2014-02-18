function guidat = disp_label_dtw(guidat, uihdls, data, ii, varargin)
%% Config
dtwClr = [1, 0, 1];


%% Clean up display
for j0 = 1 : length(guidat.hLineStarter)
    if ~isnan(guidat.hLineStarter(j0))
        delete(guidat.hLineStarter(j0));
    end
end
for j0 = 1 : length(guidat.hLineOn)
    if ~isnan(guidat.hLineOn(j0))
        delete(guidat.hLineOn(j0));
    end
end
for j0 = 1 : length(guidat.hLineEnd)
    if ~isnan(guidat.hLineEnd(j0))
        delete(guidat.hLineEnd(j0));
    end
end
for j0 = 1 : numel(guidat.dtwLines)
    if ~isnan(guidat.dtwLines(j0))
        delete(guidat.dtwLines(j0));
    end
end
for j0 = 1 : numel(guidat.dtwTxt)
    if ~isnan(guidat.dtwTxt(j0))
        delete(guidat.dtwTxt(j0));
    end
end
if ~isempty(guidat.dtwInfoTxt) && ~isnan(guidat.dtwInfoTxt)
    delete(guidat.dtwInfoTxt);
end

for j0 = 1 : numel(guidat.dtwManualOnset)
    if ~isnan(guidat.dtwManualOnset(j0))
        delete(guidat.dtwManualOnset(j0));
    end
end
if ~isempty(guidat.dtwManualOnsetLbl) && ~isnan(guidat.dtwManualOnsetLbl)
    delete(guidat.dtwManualOnsetLbl);
end

if ~isempty(fsic(varargin, '--clean-up-only'))
    guidat.hLineOn = [NaN, NaN, NaN];
    guidat.hLineEnd = [NaN, NaN, NaN];
    guidat.hLineStarter = [NaN, NaN, NaN];

    guidat.dtwLines = [];
    guidat.dtwTxt = [];
    guidat.dtwInfoTxt = [];
    
    guidat.dtwManualOnset = [NaN, NaN, NaN];
    guidat.dtwManualOnsetLbl = NaN;
    
    return;
end

%% Display labels 
if length(data{ii}.times) == 3
    if isfield(data{ii}, 'bStarter') && data{ii}.bStarter == 1    
        set(0, 'CurrentFigure', guidat.hfig);
        set(gcf, 'CurrentAxes', guidat.hsp1);
        guidat.hLineStarter(1) = plot(repmat(data{ii}.starterOnset, 1, 2), get(gca, 'YLim'), 'm--');
        set(gcf, 'CurrentAxes', guidat.hsp2);
        guidat.hLineStarter(2) = plot(repmat(data{ii}.starterOnset, 1, 2), get(gca, 'YLim'), 'm--');
        set(gcf, 'CurrentAxes', guidat.hsp3);
        guidat.hLineStarter(3) = plot(repmat(data{ii}.starterOnset, 1, 2), get(gca, 'YLim'), 'm--');    
    end
    
    set(0, 'CurrentFigure', guidat.hfig);
    set(gcf, 'CurrentAxes', guidat.hsp1);
    guidat.hLineOn(1) = plot(repmat(data{ii}.times(2), 1, 2), get(gca, 'YLim'), 'b--');
    set(gcf, 'CurrentAxes', guidat.hsp2);
    guidat.hLineOn(2) = plot(repmat(data{ii}.times(2), 1, 2), get(gca, 'YLim'), 'b--');
    set(gcf, 'CurrentAxes', guidat.hsp3);
    guidat.hLineOn(3) = plot(repmat(data{ii}.times(2), 1, 2), get(gca, 'YLim'), 'b--');
    set(gcf, 'CurrentAxes', guidat.hsp1);
    
    set(gcf, 'CurrentAxes', guidat.hsp1);
    guidat.hLineEnd(1) = plot(repmat(data{ii}.times(3), 1, 2), get(gca, 'YLim'), 'b-');
    set(gcf, 'CurrentAxes', guidat.hsp2);
    guidat.hLineEnd(2) = plot(repmat(data{ii}.times(3), 1, 2), get(gca, 'YLim'), 'b-');
    set(gcf, 'CurrentAxes', guidat.hsp3);
    guidat.hLineEnd(3) = plot(repmat(data{ii}.times(3), 1, 2), get(gca, 'YLim'), 'b-');
    set(gcf, 'CurrentAxes', guidat.hsp1);
end

%% Display dtw results
if isfield(data{ii}, 'warpAlign') && isfield(data{ii}.warpAlign, 'segNames') ...
    && ~isempty(data{ii}.warpAlign.segNames) ...
    && ~isempty(data{ii}.warpAlign.tBeg) && ~isempty(data{ii}.warpAlign.tEnd)

    dtwInfoStr = sprintf('DTW template generated on %s at %s', ...
                         data{ii}.warpAlign.segHostName, data{ii}.warpAlign.segTimeStamp);

    guidat.dtwLines = nan(3, length(data{ii}.warpAlign.tBeg) + 1);
    guidat.dtwTxt = nan(3, length(data{ii}.warpAlign.tBeg));
                     
    set(0, 'CurrentFigure', guidat.hfig);
    for i0 = 1 : 3
        if i0 == 1
            set(gcf, 'CurrentAxes', guidat.hsp1);
        elseif i0 == 2
            set(gcf, 'CurrentAxes', guidat.hsp2);
        else
            set(gcf, 'CurrentAxes', guidat.hsp3);
        end

        xs = get(gca, 'XLim'); ys = get(gca, 'YLim');
        
        % Draw DTW manual onset 
        if isfield(data{ii}, 'manualDTWOnset')
            guidat.dtwManualOnset(i0) = plot(repmat(data{ii}.manualDTWOnset, 1, 2), ...
                                             ys, '--', 'Color', dtwClr);
            if i0 == 1
                guidat.dtwManualOnsetLbl = text(data{ii}.manualDTWOnset, ys(2) + 0.05 * (ys(2) - ys(1)), ...
                                                'Manual DTW onset', 'Color', dtwClr, 'FontWeight', 'bold');
            end
        end
        
        for i1 = 1 : length(data{ii}.warpAlign.segNames)
            guidat.dtwLines(i0, i1) = ...
                plot(repmat(data{ii}.warpAlign.tBeg(i1), 1, 2), ...
                     ys, '-', 'Color', dtwClr);
            tFrac = 0.5;
            guidat.dtwTxt(i0, i1) = ...
                text(data{ii}.warpAlign.tBeg(i1) * tFrac + data{ii}.warpAlign.tEnd(i1) * (1 - tFrac), ...
                     ys(2) - 0.05 * (ys(2) - ys(1)), data{ii}.warpAlign.segNames{i1}, ...
                     'Color', dtwClr);

             if i1 == length(data{ii}.warpAlign.segNames)
                guidat.dtwLines(i0, end) = ...
                    plot(repmat(data{ii}.warpAlign.tEnd(i1), 1, 2), ...
                         ys, '-', 'Color', dtwClr);
             end
        end

        if i0 == 1
            guidat.dtwInfoTxt = text(xs(1) + 0.01 * (xs(2) - xs(1)), ...
                                     ys(1) + 0.05 * (ys(2) - ys(1)), ...
                                     dtwInfoStr, 'Color', dtwClr);
        end
        set(gca, 'XLim', xs, 'YLim', ys);
    end
end
drawnow;


return