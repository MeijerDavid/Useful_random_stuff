function y = pdfConvTruncatedNormalAndNormal(x,a_TN,b_TN,mu_TN,sd_TN,sd_N,log_flag)
%Computes the (log-) pdf at x for a convolution of a truncated normal 
%[parameters: a_TN,b_TN,mu_TN,sd_TN] and normal distribution (mu_N=0,sd_N). 

if nargin < 7
    log_flag = false;
end

%The formula is adopted from Turban 2010: 
%http://www.columbia.edu/~st2511/notes/Convolution%20of%20truncated%20normal%20and%20normal.pdf
var_TN = sd_TN.^2;
var_N = sd_N.^2;
alpha = var_N.*(x-mu_TN)./(var_TN+var_N);
beta = sqrt((var_TN.*var_N)./(var_TN+var_N));

if log_flag
    %Compute y=log(pdf)
    %log_gamma = log(sqrt(2*pi)*beta) - log(2*pi*sd_N.*sd_TN) - log(normcdf_quick((mu_TN-b_TN)./sd_TN, (mu_TN-a_TN)./sd_TN));
    %y = log_gamma - (x-mu_TN).^2./(2*(var_TN+var_N)) + log(normcdf_quick((x-b_TN-alpha)./beta, (x-a_TN-alpha)./beta));
    y = log(sqrt(2*pi)*beta) - log(2*pi*sd_N.*sd_TN) - log(normcdf_quick((mu_TN-b_TN)./sd_TN, (mu_TN-a_TN)./sd_TN)) - (x-mu_TN).^2./(2*(var_TN+var_N)) + log(normcdf_quick((x-b_TN-alpha)./beta, (x-a_TN-alpha)./beta));
else
    %gamma = sqrt(2*pi)*beta./(2*pi*sd_N.*sd_TN.*(normcdf_quick((mu_TN-a_TN)./sd_TN)-normcdf_quick((mu_TN-b_TN)./sd_TN)));
    %y = gamma.*exp(-(x-mu_TN).^2./(2*(var_TN+var_N))).*(normcdf_quick((x-a_TN-alpha)./beta)-normcdf_quick((x-b_TN-alpha)./beta));
    %gamma = sqrt(2*pi)*beta./(2*pi*sd_N.*sd_TN.*normcdf_quick((mu_TN-b_TN)./sd_TN, (mu_TN-a_TN)./sd_TN));
    %y = gamma.*exp(-(x-mu_TN).^2./(2*(var_TN+var_N))).*normcdf_quick((x-b_TN-alpha)./beta, (x-a_TN-alpha)./beta);
    y = (sqrt(2*pi)*beta./(2*pi*sd_N.*sd_TN.*normcdf_quick((mu_TN-b_TN)./sd_TN, (mu_TN-a_TN)./sd_TN))) .* exp(-(x-mu_TN).^2./(2*(var_TN+var_N))).*normcdf_quick((x-b_TN-alpha)./beta, (x-a_TN-alpha)./beta);
end

end %[EoF]