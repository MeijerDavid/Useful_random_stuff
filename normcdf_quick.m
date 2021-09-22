function p = normcdf_quick(z1,z2)
%P = NORMCDF_QUICK(Z) computes cumulative probabilities P of the standard 
%normal distribution at input values Z.
%P = NORMCDF_QUICK(Z1,Z2) robustly computes the definite integral of the
%standard normal distribution between Z1 and Z2: normcdf(z2)-normcdf(z1). 
%Care is taken for numerical stability when both Z1 and Z2 are large.

if nargin == 1
    %Implementation of normcdf is adopted from Matlab's 'normcdf':
    %"Use complementary error function, rather than .5*(1+erf(z/sqrt(2))),
    %to produce accurate near-zero results for large negative z."
    p = 0.5 * erfc(-z1 ./ sqrt(2));
    
else
    %Avoid numerical inaccuracies that occur when both z are large, i.e.
    %both p would be near one and the difference would falsely return zero.
    z_cut_off = 6;
    both_large = z1>z_cut_off & z2>z_cut_off;
    if any(both_large,'all')
        z1_both_large = z1(both_large);
        z1(both_large) = -z2(both_large);
        z2(both_large) = -z1_both_large;
    end

    %Compute the definite integral of the standard normal distribution.
    %p = normcdf_quick(z2)-normcdf_quick(z1);
    p = 0.5 * (erfc(-z2 ./ sqrt(2)) - erfc(-z1 ./ sqrt(2)));
end

end %[EoF]