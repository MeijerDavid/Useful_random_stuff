function [expectation,variance] = twoMomentsOfMixture(expectations,variances,weights)
%Compute the expectation and variance of a mixture distribution based on
%vectors of expectations, variances and weights. If the input variables are
%matrices, then the expectation and variance of the mixture distributions
%are computed along the first dimension (each column of the input matrices
%represents a mixture distribution). 

assert(isequal(size(expectations),size(variances)),'expectations and variances must be same sized matrices');
assert(isequal(size(expectations),size(weights)),'expectations and weights must be same sized matrices');

%Ensure 2D matrices
original_size = size(expectations);
if numel(original_size) > 2
    [num_rows,num_cols] = size(expectations);
    expectations = reshape(expectations,[num_rows num_cols]);
    variances = reshape(variances,[num_rows num_cols]);
    weights = reshape(weights,[num_rows num_cols]);
end

%If vectors, ensure column vectors
if isrow(expectations)
    expectations = expectations';
    variances = variances';
    weights = weights';
end

%Compute the weighted expectation
expectation = sum(weights.*expectations,1);

%Compute the weighted variance
variance = sqrt(sum(weights.*(variances+expectations.^2),1)-expectation.^2);

%Rehsape the output to match the input
if numel(original_size) > 2
    new_size = [1 original_size(2:end)];
    expectation = reshape(expectation,new_size);
    variance = reshape(variance,new_size);
end

end %[EoF]
