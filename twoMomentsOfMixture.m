function [expectation, variance, SEM] = twoMomentsOfMixture(expectations, variances, weights, dim)
% Compute the expectation and variance of 1D mixture distributions over the 
% specified dimension 'dim'. By default dim=1, i.e. each column of the input
% matrices represents a mixture distribution. 
%
% https://en.wikipedia.org/wiki/Mixture_distribution#Moments
%
% Optionally, also compute the standard error of the mean (SEM), i.e. SE of
% the expectation. This computation applies Bessel's correction and uses 
% the effective sample size based on how evenly the weights are distributed
% across the mixture components. 
%
% http://seismo.berkeley.edu/~kirchner/Toolkits/Toolkit_12.pdf
%
% David Meijer
% 21-09-2023

if nargin < 4
    dim = 1;
end

% Check that all input variables have the same size
if ~isempty(variances)
    assert(isequal(size(expectations), size(variances)), 'All input variables must have equal size');
    assert(all(variances >= 0,'all'), 'All variances must be >= 0');
end
assert(isequal(size(expectations), size(weights)), 'All input variables must have equal size');
assert(all(weights >= 0,'all'), 'All weights must be >= 0');

% Catch annoying special case
if isempty(expectations)
    expectation = [];
    variance = [];
    SEM = [];
    return;
end

% Normalize the weights
sum_of_weights = sum(weights,dim);
assert(all(sum_of_weights >= 0,'all'), 'At least one of the weights in the mixture must be > 0');
weights = weights ./ sum_of_weights;

% Avoid 0*inf = NaN issues etc
expectations(weights == 0) = 0;

% Compute the weighted expectation
expectation = sum(weights.*expectations, dim);

% Also compute the weighted variance, if requested
if nargout >= 2
    
    %Assume zeros if variances are not supplied by user (i.e. compute variance of "expectations", n.b. without Bessel's correction)
    if isempty(variances)
        variances = zeros(size(expectations));
    end
    
    % Avoid 0*inf = NaN issues etc
    variances(weights == 0) = 0;
    
    % Compute the weighted variance
    variance = sum(weights.*(variances+expectations.^2), dim)-expectation.^2;
    
    % Correct for small numerical errors
    variance = max(variance,0);
end

% Also compute the standard error of the weighted mean (i.e. SE of expectation), if requested
if nargout >= 3
    
    % Following: http://seismo.berkeley.edu/~kirchner/Toolkits/Toolkit_12.pdf
    % See also: http://www.analyticalgroup.com/download/WEIGHTED_MEAN.pdf
    
    % Compute the effective sample size - Eq. 4
    n_eff = sum(weights,dim).^2 ./ sum(weights.^2,dim);                     
    
    % Apply Bessel's correction to the variance estimates (multiply by "n_eff./(n_eff-1)") - Eq. 5   
    % Then divide by n_eff to obtain the standard error of the mean - Eq. 6
    SEM = sqrt(variance ./ (n_eff-1));                                   
end

end %[EoF]
