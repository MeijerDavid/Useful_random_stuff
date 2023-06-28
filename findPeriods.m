function [start_idx, end_idx] = findPeriods(binary_vector)
%Find periods of "1" within the binary input vector (only 1's and 0's).
%Returns two column vectors of equal length for start and end indices.

%Catch empty input - because function would throw an error
if isempty(binary_vector)
    start_idx = [];
    end_idx = [];
    return
end

%Throw error with NaNs - because function would return erroneous result
assert(~any(isnan(binary_vector)));

%Find periods of ones (ensure inclusion of first start and last end)   
start_and_ends = [double(binary_vector(1)); diff([binary_vector(:); 0])];
start_idx = find(start_and_ends == 1);              %changes from 0 to 1
end_idx = find(start_and_ends == -1)-1;             %changes from 1 to 0

end %[EoF]
