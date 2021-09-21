function y = bsxfun_triangpdf(x,mu,sigma)
%BSXFUN_TRIANGPDF Vectorized probability density function (pdf) of
%symmetrical triangular distribution. 
%   Y = BSXFUN_TRIANGPDF(X,MU,SIGMA) returns the pdf of the symmetrical
%   triangular distribution with mean MU. Its width is defined relative to 
%   width parameter SIGMA such that the interval MU +/- SIGMA contains ~68%
%   of its mass (similar to a normal distribution with same mu and sigma).
%   Dimensions of X, MU, and SIGMA must either match, or be equal to one. 
%   Computation of the pdf is performed with singleton expansion enabled 
%   via BSXFUN. The size of Y is the size of the input arguments (expanded
%   to non-singleton dimensions).
%
%   All elements of SIGMA are assumed to be non-negative (no checks).
%
%   Adapted from BSXFUN_NORMPDF by Luigi Acerbi.

if nargin<3
    error('bmp:bsxfun_triangpdf:TooFewInputs','Input argument X, MU or SIGMA are undefined.');
end

widthFactor = 2.29; %--> Create a symmetrical triangular pdf where 68% of its mass falls within the interval that would also contain 68% of the normal distribution's mass (i.e. interval is mu +/- SD)
                         %This also means that 97.8% of the gaussian mass is captured within the interval of the triangular pdf (outside that interval pdf = 0 for triangular, and pdf = small for gaussian)   

%y = ((widthFactor*sigma)-abs(mu-x))/((widthFactor*sigma)^2)
try
    if isscalar(mu)
        y = bsxfun(@rdivide,bsxfun(@minus,(widthFactor*sigma),abs(mu-x)),(widthFactor*sigma).^2);        
    elseif isscalar(sigma)
        y = ((widthFactor*sigma)-abs(bsxfun(@minus,mu,x)))/((widthFactor*sigma)^2);
    else
        y = bsxfun(@rdivide,bsxfun(@minus,(widthFactor*sigma),abs(bsxfun(@minus,mu,x))),(widthFactor*sigma).^2);
    end
catch
    error('bmp:bsxfun_normpdf:InputSizeMismatch',...
          'Non-singleton dimensions must match in size.');
end

y = max(y,0);       %This is significantly (!) faster than y(y<0) = 0;

end %[EoF]