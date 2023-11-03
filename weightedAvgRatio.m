function [r,SE] = weightedAvgRatio(numerators,denominators,weights,dim)
%Compute a weighted average ratio of the ratios: numerators / denominators.
%Optionally, also compute a standard error of the ratio estimates

if nargin < 4
    dim = 1;
end

if nargin < 3
    weights = ones(size(numerators)) ./ size(numerators,dim);
end

r = sum(sign(denominators).*weights.*numerators,dim) ./ sum(sign(denominators).*weights.*denominators,dim);

if nargout >= 2
    
    % Following: http://seismo.berkeley.edu/~kirchner/Toolkits/Toolkit_12.pdf
    % See also: http://www.analyticalgroup.com/download/WEIGHTED_MEAN.pdf
    
    weights = weights ./ sum(weights,dim);
    
    mean_numerator = sum(sign(denominators).*weights.*numerators,dim);
    mean_denominator = sum(sign(denominators).*weights.*denominators,dim);
    
    var_numerator = sum(weights.* (sign(denominators).*numerators - mean_numerator).^2,dim);
    n_eff = 1 ./ sum(weights.^2,dim);                           %Eq. 4
    SE = sqrt(var_numerator ./ (n_eff-1));                      %Eq. 5-6
    
    SE = SE ./ mean_denominator;
end

end %[EoF]

%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Tester code below %%%
%%%%%%%%%%%%%%%%%%%%%%%%%

% cla;
% 
% ratios_true = logspace(-1,1,100);
% x = linspace(.1,10,100);
% 
% plot(x,ratios_true); hold on; plot(x([1 end]),ratios_true([1 100]),'k:');
% 
% denominators = x + randn(1,100);
% numerators = ratios_true.*x + 2*randn(1,100);
% 
% ratio_data = numerators./denominators;
% plot(denominators,ratio_data,'ro');
% 
% r = nan(1,100);
% for i=1:100
%     w = normpdf(denominators,denominators(i),1);
%     w = w ./ sum(w);
%     r(i) = sum(sign(denominators).*w.*numerators) ./ sum(sign(denominators).*w.*denominators);
% end
% 
% [d1,i1] = sort(denominators);
% plot(d1,r(i1),'r--');
% 
% xlim([min(d1)-.5, max(d1)+.5]); 
% ylim([min(ratio_data)-.5, max(ratio_data)+.5]);