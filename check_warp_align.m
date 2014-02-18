function bErr = check_warp_align(warpAlign)
ts = [warpAlign.tBeg, warpAlign.tEnd(end)];
if isfield(warpAlign, 'manTBeg')
    ts(~isnan(warpAlign.manTBeg)) = warpAlign.manTBeg(~isnan(warpAlign.manTBeg));
end
if isfield(warpAlign, 'manTEnd')
    if ~isnan(warpAlign.manTEnd(end))
        ts(end) = warpAlign.manTEnd(end);
    end
end

dts = diff(ts);
bErr = ~isempty(find(dts <= 0));

return