function y_conv = convGauss(y,deltaX,sigma,alpha)
%convolve a signal "y" with a gaussian kernel. Signal y must be based on a
%regular grid with stepsize "deltaX". The Gaussian kernel will have an SD
%equal to "sigma". The width/order of the kernel is further defined by 
%"alpha", which is the maximally allowed value in terms of +/-SD. 

%Set defaults
if nargin < 2
    deltaX = 1;    
end
if nargin < 3
    sigma = 1;    
end
if nargin < 4
    alpha = 2.5;    %equal to the default of "gausswin"
end

%Ensure row vector y
if size(y,1) > 1
    y = y';
end
nY = size(y,2);

%Create a Gaussian kernel with the correct width 
xTmp = deltaX:deltaX:(alpha*sigma);                                         %Kernel order is defined by alpha*sigma relative to deltaX
xTmp = [fliplr(xTmp) 0 xTmp];                                               %Minimum kernel order is 1 (if deltaX > alpha*sigma) and it's always an odd integer
kernelOrder = numel(xTmp);
gaussKernel = normpdf(xTmp,0,sigma);
gaussKernel = gaussKernel/sum(gaussKernel);                                 %Normalize pdf to probabilities

%Pad the input signal 
nPad = (kernelOrder-1)/2;                                                   
if nY > nPad
    y_pad = [y((1+nPad):-1:2), y, y((nY-1):-1:(nY-nPad))];                  %Reflection padding (least disturbance to signal) --> default
elseif nY > 1
    nPad1 = nY-1;
    nPad2 = nPad-nPad1;
    y_pad = [zeros(1,nPad2), y((1+nPad1):-1:2), y, y((nY-1):-1:(nY-nPad1)),zeros(1,nPad2)]; %Partial reflection padding and zeros padding
else
    y_pad = [y*ones(1,nPad), y, y*ones(1,nPad)];                            %Replication padding if signal consists of only one value (not a very sensible convolution..)
end
%y_pad = [y(1)*ones(1,nPad), y, y(end)*ones(1,nPad)];                       %Replication padding (gives greater weight to values at the edges)  
%y_pad = [zeros(1,nPad), y, zeros(1,nPad)];                                 %Zero padding (gives less weight to values at the edges)  

%Perform the convolution using the standard Matlab function
y_conv = conv(y_pad,gaussKernel,'valid');

end %[EoF]