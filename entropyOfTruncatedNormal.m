function entropy = entropyOfTruncatedNormal(mu,sd,a,b)
%Compute entropy of normal or truncated normal distribution analytically

if nargin < 3
    
    %Normal distribution
    entropy = .5*log(2*pi*sd.^2)+.5;
    
else
    
    %Truncated normal distribution
    alpha = (a-mu)./sd;                                         
    beta = (b-mu)./sd;
    Z = normcdf_quick(alpha,beta);
    entropy = log(sqrt(2*pi*exp(1))*sd.*Z)+(alpha.*normpdf(alpha)-beta.*normpdf(beta))./(2*Z); 

end