function [avg,SE] = avgPrecisionWeighted(means,sds,dim)
%Compute the precision weighted average of the means with associated
%standard deviations (sds) over the desired dimension. Optionally, also 
%compute the standard errors of these weighted averages. 

if nargin < 3
    dim = 1;
end

weights = 1./(sds.^2);
weights = weights ./ sum(weights,dim);

avg = sum(weights.*means,dim);

if nargout >= 2
    
    %http://seismo.berkeley.edu/~kirchner/Toolkits/Toolkit_12.pdf
    n = size(means,dim);
    SE =  sqrt((sum(weights .* means.^2,dim) - avg.^2) ./ (n-1)); %Eq. 2-3
end

end %[EoF]
