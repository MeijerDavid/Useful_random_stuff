function Y = randsamplePDF(sizeN,pdf,xpdf,minmax)
%Sample an array of sizeN random numbers between minmax from a discrete pdf 
%defined at grid xpdf using the method of inversion sampling. This function
%applies linear interpolation using 'interp1'. 

%N.B. Use this line for sampling from a discrete probablity distribution:
%Y = discretize(rand(sizeN),[0; cumsum(probs(:))]);

%Check minmax
if nargin < 4
    minmax = xpdf([1 end]);
else
    if (minmax(1) > xpdf(1)) || (minmax(2) < xpdf(end))
        error('The MINMAX boundaries must not exceed the range of XPDF');
    end
end

%Sample random numbers from standard uniform
rp = rand(sizeN);

%Special case
if numel(xpdf) == 1
    Y = minmax(1)+diff(minmax)*rp;

%Default behaviour
else
    %Determine the bin bounds
    xpdf = filter([0.5 0.5],1,xpdf(:));  %Moving average filter of width 2
    xbounds = [minmax(1); xpdf(2:end); minmax(2)];
    
    %Compute cumulative probability distribution
    pdf = pdf./sum(pdf);
    cdf = [0; cumsum(pdf(:))];
    
    %Use the inverse cdf to interpolate the random samples and convert to Y 
    Y = interp1(cdf,xbounds,rp);
end

end %[EoF]
