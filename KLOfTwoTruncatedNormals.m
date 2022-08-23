function KLdivergence = KLOfTwoTruncatedNormals(mu1,sd1,mu2,sd2,a,b)
%Kullback-Leibler divergence between two truncated normal distributions with same boundaries [a,b]
%Reference: Nielsen 2022; https://doi.org/10.3390/e24030421, Eq. 111

if nargin < 5
    
    %Two normal distributions
    KLdivergence = log(sd2./sd1) + (sd1.^2+(mu1-mu2).^2)./(2*sd2.^2)-.5;    %See Eq. 112 in Nielsen 2022, but there are many other sources, e.g. http://allisons.org/ll/MML/KL/Normal/
    
else
    
    %Two truncated normal distributions with the same boundaries [a,b]
    alpha_1 = (a-mu1)./sd1;                                      
    beta_1 = (b-mu1)./sd1;
    phi_alpha_1 = normpdf(alpha_1);
    phi_beta_1 = normpdf(beta_1);
    Z_1 = normcdf_quick(alpha_1,beta_1);                                    %normcdf(beta_1)-normcdf(alpha_1) --> similar to Eq. 98, but without multiplying with sd*sqrt(2*pi). 
                                                                            %The sqrt(2*pi) term will drop out in the fraction of Eq. 111
    var1 = sd1.*sd1; 
    var2 = sd2.*sd2;

    eta1 = mu1 - sd1 .* (phi_beta_1-phi_alpha_1) ./ Z_1;                                                                                            %Eq. 109 (expectation of first truncated normal)
    eta2 = var1 .* ( 1 - (beta_1.*phi_beta_1-alpha_1.*phi_alpha_1)./Z_1 - ((phi_beta_1-phi_alpha_1)./Z_1).^2) + eta1.^2;                            %Eq. 110 (variance + mean_squared of first truncated normal)

    KLdivergence = .5*(mu2.^2./var2 - mu1.^2./var1) + log((sd2.*normcdf_quick((a-mu2)./sd2,(b-mu2)./sd2))) - log((sd1.*Z_1)) - (mu2./var2 - mu1./var1).*eta1 - .5*(1./var1 - 1./var2).*eta2;  %Eq. 111 
    %Note that there was an error in Eq. 111. The first two numerators should be squared (i.e. mu2^2 and mu1^2). This is correct now. 
    
end

end %[EoF]
