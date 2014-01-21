function [ion, ioff, varargout] = fill_gaps(x, maxGap)
if ~isequal(unique(x(:)), [0; 1])
    error('Input sequence consists of elements other than 0 and 1');
end

ion = find(x(1 : end - 1) == 0 & x(2 : end) == 1) + 1;  % Onset indices
ioff = find(x(1 : end - 1) == 1 & x(2 : end) == 0); % Offset indices

assert(ioff(1) >= ion(1));
assert(ioff(end) >= ion(end));
assert(length(ion) == length(ioff));

%%
n = length(ion);
for i1 = 1 : n - 1
    if ion(i1 + 1) - ioff(i1) <= maxGap
        ion(i1 + 1) = NaN;
        ioff(i1) = NaN;
    end
end

ion = ion(~isnan(ion));
ioff = ioff(~isnan(ioff));

assert(length(ion) == length(ioff));

if nargout == 3
    y = zeros(size(x));
    
    for i1 = 1 : length(ion)
        y(ion(i1) : ioff(i1)) = 1;
    end
    
    varargout{1} = y;
end

return