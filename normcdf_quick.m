function p = normcdf_quick(z1,z2,method)
%P = NORMCDF_QUICK(Z) computes cumulative probabilities P of the standard 
%normal distribution at input values Z. 
%P = NORMCDF_QUICK(Z1,Z2) robustly computes the definite integral of the
%standard normal distribution between Z1 and Z2: normcdf(z2)-normcdf(z1). 
%Care is taken for numerical stability when both Z1 and Z2 are large.
%
%By David Meijer on 20-06-2022

if nargin < 3
    method = 4;     %Default (logistic approximation) is fastest method (see below)
end                 
if nargin < 2
    z2 = [];
end

%Perform the computations
if isempty(z2)
    
    switch method
       
        case 1
            
            %W. J. Cody, Rational Chebyshev Approximations for the Error Function, Math. Comp., 1969, pp. 631--637.
            %Implementation is adopted from Matlab's 'normcdf': "Use complementary error function, rather than .5*(1+erf(z/sqrt(2))), to produce accurate near-zero results for large negative z."
            p = 0.5 * erfc(-z1 ./ sqrt(2));
            
        case 2
            
            %P. O. Borjesson and C. E. Sundberg. Simple approximations of the error function Q(x) for communications applications. IEEE Trans. Commun., COM-27(3):639–643, March 1979.
            %See https://en.wikipedia.org/wiki/Q-function#Bounds_and_approximations and https://stats.stackexchange.com/questions/7200/evaluate-definite-interval-of-normal-distribution
            %Unfortunately, the error is rather large for small Z, and p does not equal 0.5 for Z=0, so we use method 1 for all Z smaller than 1.1124 (at this value methods 1 and 2 give the same value). 
            %For Z>1.1124 the error is always positive, but never greater than 0.0001 as compared to method 1. 
            %Although the formula for this approximation appears simple, the speed-up compared to Matlab's build-in erfc is negligible (actually, this method is twice slower than Matlab's normcdf).
            
            %Initialize outcome (memory declaration)
            p = zeros(size(z1));
            
            %Compute the small Z with Matlab's build-in erfc function (method 1)   
            i_z_small = abs(z1) < 1.1124;
            p(i_z_small) = normcdf_quick(z1(i_z_small),[],1);
            
            %Compute all other Z with the approximation by Borjesson and Sundberg
            z_large = z1(~i_z_small);
            
            %The approximation only works for positive z1, so we multiply the negative values by -1   
            pos_z_large = z_large > 0;                                                       
            rectifier = 2*pos_z_large-1;     
            z_large = rectifier.*z_large;                                                     

            %Compute the Q function and transform to cdf probabilities
            a = 0.339;
            b = 5.510;
            p(~i_z_small) = pos_z_large - rectifier .* normpdf(z_large) ./ ((1-a)*z_large + a*sqrt(z_large.*z_large+b));
            
        case 3
            
            %A. Hanandeh and O Eidous. A New One-term Approximation to the Standard Normal Distribution. Pak.j.stat.oper.res. Vol.17 No. 2 2021 pp 381-385. https://doi.org/10.18187/pjsor.v17i2.3556   
            %Absolute error is maximally 0.0016. The speed-up compared to Matlab's build-in erfc (method 1) depends on the value of Z, but mostly computation times are simply quite similar. 
            
            %The approximation only works for negative z1, so we multiply the positive values by -1   
            neg_z1 = z1 < 0;                                                       
            rectifier = 2*neg_z1-1;     
            z1 = rectifier.*z1;                                                     
            
            %Compute the Q function and transform to cdf probabilities
            p = neg_z1 - rectifier .* (.5*(1+sqrt(1-exp((-81/130)*z1.*z1))));
            
        case 4
            
            %Bowling, S. R., Khasawneh, M. T., Kaewkuekool, S. and Cho, B. R. (2009). A Logistic approximation to the cumulative normal distribution. Journal of Industrial Engineering and Management, 2(1), 114-127. 
            %Absolute error is maximally 0.0095 (a factor of 6 worse than method 3, but this method is consistently about two times faster relative to Matlab's build-in ercf method, #1 above). 
            p = 1./(1+exp(-1.702*z1));
            
        otherwise
          error('Unknown method for normcdf_quick');
    end
    
else
    
    %Avoid numerical inaccuracies that occur when both z are large, i.e. both p would be near one and the difference would falsely return zero.
    z_cut_off = 6;  
    both_large = z1>z_cut_off & z2>z_cut_off;
    if any(both_large,'all')
        %Avoid the use of indexing because it's slow: i.e. don't use z1(both_large) and z2(both_large)
        z1_copy = z1;
        z1 = ~both_large.*z1_copy - both_large.*z2;                         %Keep z1 or use -z2 instead
        z2 = ~both_large.*z2 - both_large.*z1_copy;                         %Keep z2 or use -z1 instead
    end

    %Compute the definite integral of the standard normal distribution.
    p = normcdf_quick(z2,[],method)-normcdf_quick(z1,[],method);

end

end %[EoF]

%%%%%%%%%%%%%%%%%%%
%%% Tester code %%%
%%%%%%%%%%%%%%%%%%%

% x = linspace(-10,10,1000);
% [z1,z2] = meshgrid(x,x);
% 
% f1 = @() normcdf_quick(z1,z2,1);
% f2 = @() normcdf_quick(z1,z2,2);
% f3 = @() normcdf_quick(z1,z2,3);
% f4 = @() normcdf_quick(z1,z2,4);
% 
% timeit(f1)
% timeit(f2)
% timeit(f3)
% timeit(f4)
% 
% p1 = normcdf_quick(x,[],1);
% p2 = normcdf_quick(x,[],2);
% p3 = normcdf_quick(x,[],3);
% p4 = normcdf_quick(x,[],4);
% 
% plot(x,p1,'b-',x,p2,'r--',x,p3,'m:',x,p4,'c.-'); legend; xlim([-3 3]);
% 
% p5 = normcdf_quick(z1,z2,1);
% p6 = normcdf_quick(z1,z2,2);
% p7 = normcdf_quick(z1,z2,3);
% p8 = normcdf_quick(z1,z2,4);
% 
% p0 = normcdf(z2)-normcdf(z1);
% 
% p08 = p0-p8;
% max(p08(:))
% min(p08(:))
% 
% method = 4;
% profile on
% for i=1:100
%     normcdf_quick(z1,z2,method); 
% end
% profile viewer
