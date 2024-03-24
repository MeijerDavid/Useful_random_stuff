function lp = normlogcdf_quick(z)
%Approximate log(normcdf) quickly and avoid numerical inaccuracies

%Bowling, S. R., Khasawneh, M. T., Kaewkuekool, S. and Cho, B. R. (2009). A Logistic approximation to the cumulative normal distribution. Journal of Industrial Engineering and Management, 2(1), 114-127. 
%Absolute error for normcdf probability is maximally 0.0095 (but this method is consistently about two times faster relative to Matlab's build-in ercf method). 

%p = 1./(1+exp(-1.702*z));
lp = -log1p(exp(-1.702*z));

end %[EoF]
