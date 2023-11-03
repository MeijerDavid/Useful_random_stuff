function y = pdfConvUniformAndNormal(x,a,b,sd,log_flag)
%Computes the (log-) pdf at x for a convolution of a uniform [a,b] and a 
%normal distribution (mu=0,sd). 

if nargin < 5
    log_flag = false;
end

if log_flag
    %Compute y=log(pdf)
    y = log(normcdf_diff((x-b)./sd, (x-a)./sd)) - log(b-a);
else
    y = 1./(b-a).*normcdf_diff((x-b)./sd, (x-a)./sd);
end

end %[EoF]
