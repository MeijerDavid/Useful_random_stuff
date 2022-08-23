function pMat2D = numIntegrAndInterp2D(pMat3D,x1Mat3D,x2Mat3D,x1Vec,x2Vec,precisionFactor)
%Numerically integrate 3D probability bins pMat3D on accompanying irregular
%and unsorted grids x1Mat3D and x2Mat3D, and interpolate to form a 2D 
%probability distribution with the basis vectors x1Vec and x2Vec (strictly
%ascending and regularly spaced). 
%"numIntegrAndInterp2D" integrates by means of a Riemann Sum over the plane
%given by x1Vec and x2Vec. The probabilities in pMat3D are divided across
%all [x1Vec x x2Vec] bins that are covered by the original x1Mat3D and 
%x2Mat3D bins. The precision of this probability division can be set
%by precisionFactor (default = 5; scalar: increase for greater precision).
%Ensure that precisionFactor is a positive integer. 
%Division of the probability bins is performed in the third dimension.
%Hence, numerical integration is also performed over the third dimension. 
%Output pMat2D is a 2D matrix with bin probabilities corresponding to the
%combination of values in x1Vec and x2Vec.

%Set Defaults
if nargin < 6
    precisionFactor = 5;                %Larger factors increase precision of interpolation but take slightly longer to compute and require more memory. 
end                             

%Determine size of input and output matrix
input_sz = size(pMat3D);
output_sz = [length(x1Vec),length(x2Vec)];

%Check that the third dimension, over which we integrate, is non-singleton
if size(pMat3D,3) == 1
    pMat2D = zeros(output_sz);          %Return an integral of zeros (similar to 'trapz')
    return
end

%Create a reference matrix for the small/precise pMat2D bins to the larger/output pMat2D bins
num_bins = output_sz*precisionFactor;
baseMat = repmat(1:output_sz(1),[precisionFactor 1]);
baseVec = repmat((0:(output_sz(2)-1))*output_sz(1),[precisionFactor 1]);
small2big = repmat(baseMat(:),[1 num_bins(2)]) + baseVec(:)';

%Discretize x1Mat3D and x2Mat3D onto the bins of x1Vec and x2Vec, respectively   
%Easy and fast, making use of the regular grids in x1Vec and x2Vec
bin_spacing_x1 = ((x1Vec(end)-x1Vec(1))/(output_sz(1)-1))/precisionFactor;
bin_spacing_x2 = ((x2Vec(end)-x2Vec(1))/(output_sz(2)-1))/precisionFactor;
bin_idx_x1 = min(num_bins(1),max(1,round((x1Mat3D-x1Vec(1))/bin_spacing_x1)+1)); 
bin_idx_x2 = min(num_bins(2),max(1,round((x2Mat3D-x2Vec(1))/bin_spacing_x2)+1)); 

%How many bins are covered with each xMat step?
bins_cov_x1 = abs(diff(bin_idx_x1,1,3))+1;
bins_cov_x2 = abs(diff(bin_idx_x2,1,3))+1;
bins_cov_tot = bins_cov_x1.*bins_cov_x2;

%Find minimum and maximum bin indices for each xMat step
min_bin_idx_x1 = min(bin_idx_x1(:,:,1:(input_sz(3)-1)),bin_idx_x1(:,:,2:input_sz(3)));
min_bin_idx_x2 = min(bin_idx_x2(:,:,1:(input_sz(3)-1)),bin_idx_x2(:,:,2:input_sz(3)));
max_bin_idx_x1 = min_bin_idx_x1 + bins_cov_x1 - 1;
max_bin_idx_x2 = min_bin_idx_x2 + bins_cov_x2 - 1;

%Prepare to distribute the pMat probabilities across each of the bins
pMat3D = filter([0.5 0.5],1,pMat3D,[],3);                                   %Moving average filter of width 2: i.e. pNew(i) = 0.5*(pOld(i-1)+pOld(i))
pBins = pMat3D(:,:,2:input_sz(3))./bins_cov_tot;                            %Note: half the probs at each edge went 'missing' (similar to 'trapz')
    
%Sum the probabilities for each of the small bins using a simple FOR loop and subsequent CUMSUM   
%See (for reference): https://uk.mathworks.com/matlabcentral/answers/69413-how-many-times-does-each-number-appear (Jan Simon) 
probs_list = zeros(1,prod(num_bins)+1);
for i=1:numel(pBins)
    idx_x2 = min_bin_idx_x2(i):max_bin_idx_x2(i);                           %variable in length - hence difficult to get rid of this for-loop
    idx_offsets_by_x2 = (idx_x2-1)*num_bins(1);
    idx_starts = idx_offsets_by_x2 + min_bin_idx_x1(i);
    idx_after_ends = idx_offsets_by_x2 + max_bin_idx_x1(i) + 1;
    probs_list(idx_starts) = probs_list(idx_starts) + pBins(i);
    probs_list(idx_after_ends) = probs_list(idx_after_ends) - pBins(i);
end
probs_list(end) = [];
probs_list = cumsum(probs_list);

%Sum probabilities of the small bins that belong to one large bin and reshape the output   
pMat2D = reshape(accumarray(small2big(:),probs_list,[prod(output_sz) 1]),output_sz); 

end %[EoF]
