function [expTN,varTN] = twoMomentsOfTruncatedNormal(mu,sd,a,b)
%Expected value and variance of truncated Normal: see
%https://en.wikipedia.org/wiki/Truncated_normal_distribution#Two_sided_truncation[2]

alpha = (a-mu)./sd;
beta = (b-mu)./sd;

%Z = normcdf_quick(beta)-normcdf_quick(alpha);
Z = normcdf_quick(alpha,beta);

phi_alpha = normpdf(alpha);
phi_beta = normpdf(beta);

expTN = mu + sd.*(phi_alpha-phi_beta)./Z; 

if nargout > 1
    varTN = sd.^2 .* ( 1 + (alpha.*phi_alpha-beta.*phi_beta)./Z - ((phi_alpha-phi_beta)./Z).^2);
end

end %[EoF]