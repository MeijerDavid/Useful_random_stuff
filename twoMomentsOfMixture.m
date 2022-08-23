function [expectation,variance] = twoMomentsOfMixture(expectations,variances,weights,dim)
%Compute the expectation and variance of 1D mixture distributions over the 
%specified dimension 'dim'. By default dim=1, i.e. each column of the input
%matrices represents a mixture distribution. 

if nargin < 4
    dim = 1;
end

%Check that all input variables have the same size
assert(isequal(size(expectations),size(variances)),'All input variables must have equal size');
assert(isequal(size(expectations),size(weights)),'All input variables must have equal size');

%Compute the weighted expectation
expectation = sum(weights.*expectations,dim);

%Also compute the weighted variance if requested
if nargout >= 2
    variance = sum(weights.*(variances+expectations.^2),dim)-expectation.^2;
end

end %[EoF]
