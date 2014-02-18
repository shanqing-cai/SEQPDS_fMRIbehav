function guidat = disp_label_dtw(guidat, uihdls, data, ii, varargin)
%% Config
dtwClr = [1, 0, 1];
errClr = [1, 0, 0];
tFrac = 0.5;
fontSize = 12;

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
for j0 = 1 : numel(guidat.dtwLinesMan)
    if ~isnan(guidat.dtwLinesMan(j0))
        delete(guidat.dtwLinesMan(j0));
    end
end
for j0 = 1 : numel(guidat.dtwManLbl)
    if ~isnan(guidat.dtwManLbl(j0))
        delete(guidat.dtwManLbl(j0));
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

if ~isempty(guidat.hComment)
    delete(guidat.hComment);
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
    
    %-- Set specified zoom --%
    if guidat.zoomStatus == 0 % Entire trial 
        set(gcf, 'CurrentAxes', guidat.hsp1);
        set(gca, 'XLim', guidat.xLim);
        set(gcf, 'CurrentAxes', guidat.hsp2);
        set(gca, 'XLim', guidat.xLim);
        set(gcf, 'CurrentAxes', guidat.hsp3);
        set(gca, 'XLim', guidat.xLim);
    else
        if isfield(data{ii}, 'bStarter') && data{ii}.bStarter == 1
            t0 = data{ii}.starterOnset;
        else
            t0 = data{ii}.times(2);
        end
        t1 = data{ii}.times(3);
        
        t0 = max([guidat.xLim(1), t0 - 0.1]);
        t1 = min([guidat.xLim(2), t1 + 0.1]);
        
        set(gcf, 'CurrentAxes', guidat.hsp1);
        set(gca, 'XLim', [t0, t1]);
        set(gcf, 'CurrentAxes', guidat.hsp2);
        set(gca, 'XLim', [t0, t1]);
        set(gcf, 'CurrentAxes', guidat.hsp3);
        set(gca, 'XLim', [t0, t1]);
    end
end

%% Display dtw results
if isfield(data{ii}, 'warpAlign') && isfield(data{ii}.warpAlign, 'segNames') ...
    && ~isempty(data{ii}.warpAlign.segNames) ...
    && ~isempty(data{ii}.warpAlign.tBeg) && ~isempty(data{ii}.warpAlign.tEnd)

    dtwInfoStr = sprintf('DTW template generated on %s at %s', ...
                         data{ii}.warpAlign.segHostName, data{ii}.warpAlign.segTimeStamp);
                     
    if (isfield(data{ii}.warpAlign, 'manTBeg') && isfield(data{ii}.warpAlign, 'manTEnd') ...
        && (~isempty(find(~isnan(data{ii}.warpAlign.manTBeg), 1)) || ...
            ~isempty(find(~isnan(data{ii}.warpAlign.manTEnd), 1)))) ...
       || (isfield(data{ii}, 'manualDTWOnset') && ~isnan(data{ii}.manualDTWOnset))
        dtwInfoStr = strcat(dtwInfoStr, ' (contains manual adjustment)');
    end

    guidat.dtwLines = nan(3, length(data{ii}.warpAlign.tBeg) + 1);
    guidat.dtwTxt = nan(3, length(data{ii}.warpAlign.tBeg));
    
    guidat.dtwLinesMan = [];
    guidat.dtwManLbl = [];        
                     
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
        
        if i0 == 1 && isfield(data{ii}, 'comment') && ~isempty(data{ii}.comment) % Show comment
            xs = get(gca, 'XLim'); ys = get(gca, 'YLim');
            guidat.hComment = text(xs(1) + 0.01 * (xs(2) - xs(1)), ...
                                   ys(1) + 0.15 * (ys(2) - ys(1)), ...
                                   sprintf('Comments: "%s"', data{ii}.comment), 'Color', 'b', 'FontSize', fontSize);
        else
            guidat.hComment = [];
        end
        
        % Draw DTW manual onset 
        if isfield(data{ii}, 'manualDTWOnset')
            guidat.dtwManualOnset(i0) = plot(repmat(data{ii}.manualDTWOnset, 1, 2), ...
                                             ys, '--', 'Color', dtwClr);
            if i0 == 1
                guidat.dtwManualOnsetLbl = text(data{ii}.manualDTWOnset, ys(2) + 0.05 * (ys(2) - ys(1)), ...
                                                'Manual DTW onset', 'Color', dtwClr, 'FontWeight', 'bold');
            end
        else
            guidat.dtwManualOnset = nan(size(guidat.dtwManualOnset));
            guidat.dtwManualOnsetLbl = nan(size(guidat.dtwManualOnsetLbl));
        end
        
        for i1 = 1 : length(data{ii}.warpAlign.segNames) + 1
            if i1 <= length(data{ii}.warpAlign.segNames)
                auto_t = data{ii}.warpAlign.tBeg(i1);
                if ~isfield(data{ii}.warpAlign, 'manTBeg')
                    man_t = NaN;
                else
                    man_t = data{ii}.warpAlign.manTBeg(i1);
                end
            else
                auto_t = data{ii}.warpAlign.tEnd(end);
                if ~isfield(data{ii}.warpAlign, 'manTEnd')
                    man_t = NaN;
                else
                    man_t = data{ii}.warpAlign.manTEnd(end);
                end
            end
            if ~isnan(man_t)
                lta = '--';
                if i1 <= length(data{ii}.warpAlign.tEnd)
                    txtX = man_t * tFrac + data{ii}.warpAlign.tEnd(i1) * (1 - tFrac);
                end
                %-- Draw the manually adjusted label --%
                guidat.dtwLinesMan(end + 1) = plot(repmat(man_t, 1, 2), ys, '-', 'Color', dtwClr);
                guidat.dtwLinesMan(end + 1) = plot([auto_t, man_t], repmat(ys(2) - 0.1 * (ys(2) - ys(1)), 1, 2), '-', 'Color', dtwClr);
                guidat.dtwManLbl(end + 1) = text(man_t, ys(1) - 0.05 * (ys(2) - ys(1)), 'M', ...
                                                 'Color', dtwClr, 'FontWeight', 'Bold');
            else
                lta = '-';
                if i1 <= length(data{ii}.warpAlign.tEnd)
                    txtX = auto_t * tFrac + data{ii}.warpAlign.tEnd(i1) * (1 - tFrac);
                end
            end
            
            guidat.dtwLines(i0, i1) = ...
                plot(repmat(auto_t, 1, 2), ...
                     ys, lta, 'Color', dtwClr);
                 
            if i1 <= length(data{ii}.warpAlign.tEnd)
                guidat.dtwTxt(i0, i1) = ...
                        text(txtX, ys(2) - 0.05 * (ys(2) - ys(1)), data{ii}.warpAlign.segNames{i1}, ...
                             'Color', dtwClr);
            end
            
%              if i1 == length(data{ii}.warpAlign.segNames)
%                 guidat.dtwLines(i0, end) = ...
%                     plot(repmat(data{ii}.warpAlign.tEnd(i1), 1, 2), ...
%                          ys, '-', 'Color', dtwClr);
%              end
        end

        if i0 == 1
            guidat.dtwInfoTxt = text(xs(1) + 0.01 * (xs(2) - xs(1)), ...
                                     ys(1) + 0.05 * (ys(2) - ys(1)), ...
                                     dtwInfoStr, 'Color', dtwClr, 'FontSize', fontSize);
        end
        set(gca, 'XLim', xs, 'YLim', ys);
        
        if i0 == 1 % Check dtw results 
            if check_warp_align(data{ii}.warpAlign)
                title('WARNING: The order of the DTW labels appears erroneous. Please check.', ...
                      'Color', errClr);
            else
                title('', 'Color', 'b');
            end
        end
        
    end
    
    
end
drawnow;


return