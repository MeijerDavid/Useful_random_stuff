function pVec = numIntegrAndInterp(xMat,pMat,xVec,interpDim,precisionFactor,xVecRegSpacing)
%Numerically integrate probability bins pMat on accompanying irregular and 
%unsorted grid xMat, and interpolate to form a probability distribution on
%the strictly ascending vector xVec. Both xMat and pMat may be matrices: 
%the operational dimension over which integration and interpolation take 
%place can be specified with interpDim (default = 1). 
%"numIntegrAndInterp" integrates by means of a Riemann Sum over xVec: The 
%probability (pMat) is divided across all xVec bins that are covered by the
%original xMat bins. The precision of this probability division can be set
%by precisionFactor (default = 10; scalar: increase for greater precision). 
%A small speed-up can be achieved if xVec is regularly spaced. If so,
%specify the xVec bin-width with xVecRegSpacing (scalar; default = false,
%meaning that xVec is assumed to have irregular intervals). 

%Set Defaults
if nargin < 4
    interpDim = 1;              %Direction of binning and interpolation on xMat and pMat
end                            
if nargin < 5
    precisionFactor = 10;       %Larger factors increase precision of interpolation but take slightly longer to compute and require more memory. Ensure that precisionFactor is a positive integer.
end                             
if nargin < 6                   
    xVecRegSpacing = false;     %Set to non-false if xVec is regularly spaced, where xVecRegSpacing is the regular 'bin-width'. Providing this information leads to a small speed-up but is not necessary.
end                             %Default assumes that xVec is not regularly spaced ('0')

%Check that the dimension over which to integrate is non-singleton
if size(xMat,interpDim) == 1
    pVec = 0*xVec;              %Return an integral of zeros (similar to 'trapz')
    return
end

%Interpolation and integration is performed over the first dimension of xMat
%If it is requested over another dimension, then make that dimension the first dimension   
nDims = numel(size(xMat));
if interpDim~=1
    if nDims <= 2
        xMat = permute(xMat,[2 1]);                     %Simple transpose
        pMat = permute(pMat,[2 1]);
    elseif nDims > 2
        OtherDims = setdiff(1:nDims,interpDim);         
        xMat = permute(xMat,[interpDim OtherDims]);
        pMat = permute(pMat,[interpDim OtherDims]);
    end
end

%Ensure 2D matrices for xMat and pMat (reshape if necessary - i.e. concatenate all dimensions > 2 into the second dimension)
[nRows,nCols] = size(xMat);
if nDims > 2
    xMat = reshape(xMat,[nRows nCols]);
    pMat = reshape(pMat,[nRows nCols]);
end

%Ensure column vector for xVec
if isrow(xVec)
    xVec = xVec';       
    xVecRowBool = 1;
else
    xVecRowBool = 0;
end
nGrid = length(xVec);

%Create a reference vector for the small xVec bins to the larger original xVec bins
nBins = nGrid*precisionFactor;
if precisionFactor ~= 1
    small2big = zeros(nBins,1);
    small2big(1:precisionFactor:end) = 1;
    small2big = cumsum(small2big);                                          %To be used in call to accumarray further below
end

%Discretize xMat
if xVecRegSpacing
    xVecRegSpacing = xVecRegSpacing/precisionFactor;
    iBins = min(nBins,max(1,round((xMat-xVec(1))/xVecRegSpacing)+1));       %Easy and fast, making use of the regular grid with binWidths defined by xSpacing
else                                                                        
    %Use Matlab's 'discretize' function
    if nGrid == 1
        xVec_edges = [xVec(1)-1; xVec(1)+1];                                %If xVec only has one value, then assume arbitrary stepsize of 1 (choice does not matter)
    else    
        xVec_edges = [xVec(1)-diff(xVec(1:2))/2; xVec(1:(nGrid-1))+diff(xVec)/2; xVec(nGrid)+diff(xVec((nGrid-1):nGrid))/2];
    end
    if precisionFactor ~= 1
        xVec_edges = lininterp1(1:(nGrid+1),xVec_edges,linspace(1,nGrid+1,nBins+1)',NaN,1);   %Break each bin into precisionFactor number of equally sized smaller bins     
    end
    xVec_edges([1 end]) = [-inf inf];                                       %Ensure that the bins at the edges cover all xMat values
    iBins = discretize(xMat,xVec_edges);
end

%How many bins are covered with each xMat step?
bins_cov = reshape(abs(diff(iBins))+1,[(nRows-1)*nCols 1]);

%Find minimum and maximum bin indices for each xMat step (prepare for a simple cumsum further below)
iBin_min = reshape(min(iBins(1:(nRows-1),:),iBins(2:nRows,:)),[(nRows-1)*nCols 1]);
iBin_max = iBin_min + bins_cov - 1;

%Prepare to distribute the pMat probabilities across each of the xVec bins
pMat = filter([0.5 0.5],1,pMat);                                            %Moving average filter of width 2: i.e. pNew(i) = 0.5*(pOld(i-1)+pOld(i))
pBins = reshape(pMat(2:nRows,:),[(nRows-1)*nCols 1])./bins_cov;             %Note: half the probs at each edge went 'missing' (similar to 'trapz')
    
%The suggestion for the following crucial line came from: https://uk.mathworks.com/matlabcentral/answers/69413-how-many-times-does-each-number-appear (Teja Muppirala)      
pVec = cumsum(accumarray(iBin_min,pBins,[nBins+1 1]) + accumarray(iBin_max+1,-pBins,[nBins+1 1]));
pVec(nBins+1) = []; 

%Sum probabilities of the small bins that belong to one large bin
if precisionFactor ~= 1
    pVec = accumarray(small2big,pVec,[nGrid 1]); 
end

%Ensure output vector has same dimension as input vector
if xVecRowBool
    pVec = pVec';
end

end %[EoF]

%%%%%%%%%%%%%%%%%%%%%%%
%%% Helper function %%%
%%%%%%%%%%%%%%%%%%%%%%%

function Vout = lininterp1(X,V,Xq,extrap,deltaX)
%Simple 1D linear interpolation on a regular ascending grid.
%Inputs X, V and Xq must be vectors. 
%Output Vout is a column vector.

%This function is a simplified version of the lininterp1 function that was
%originally written by Luigi Acerbi: https://github.com/lacerbi/lautils-mat
%While Luigi's version supports matrices as inputs, this simplified
%version is about 4x faster, and nearly 10x faster than Matlab's interp1.

%Determine length of the given grid 
%Note that X is allowed to be given as X = [min max];
nGrid = length(V);

%Ensure Xq is not empty and a column vector
if isempty(Xq)
    Vout = [];
    return
else
    Xq = Xq(:);
end

%Set default extrapolation: NaN
if nargin < 4
    extrap = NaN;
end

%Determine deltaX from X if not already supplied
if nargin < 5
    deltaX = (X(end)-X(1))/(nGrid-1);
end

%Find Xq out of bounds
flag1 = Xq < X(1);
flag2 = Xq > X(end);
flag3 = isnan(Xq);

%Transform Xq as if X was given as 1:length(X)
Xq = (Xq-X(1))/deltaX + 1;                                                                          
                                
%Indices of nearest lower neighbour X
Xqi = floor(Xq);
Xqi(flag1 | flag2 | flag3) = 1;     %temp --> will be overwritten below

%Distance from Xqi
delta = Xq - Xqi; 

%Expand to avoid Xqi==numel(V) errors when asking for Xqi+1 index below
V = [V(:); 0];

%Distance-weighted average (i.e. linear interpolation)   
Vout = (1-delta).*V(Xqi) + delta.*V(Xqi+1);

%Set values outside of X (extrapolation)
if ~isnan(extrap)
    %If extrap is set to empty: Xq outside X get V values of nearest edge.
    if isempty(extrap)                      
        Vout(flag1) = V(1);
        Vout(flag2) = V(nGrid);
    %If extrap is set to any scalar: Xq outside X get that specified value.
    else
        Vout(flag1 | flag2) = extrap;
    end
end
Vout(flag3) = NaN; 

end %[EoF]
