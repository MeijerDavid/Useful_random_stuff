function Y = downsampleByMean(X,N,DIM)
%Donwsample array X by computing the mean over every N samples in the DIM
%dimension.

if nargin < 3
    DIM = 1;
end

%Assert that we downsample over the first dimension. If it is requested 
%over another dimension, then make that dimension the first dimension.   
num_dims = numel(size(X));
if DIM~=1
    permute_order = [DIM setdiff(1:num_dims,DIM)];
    X = permute(X,permute_order);                     
end

%Assure that the length of the first dimension is a multiple of N
%Otherwise split the matrix into X and its leftover samples..
dim_sizes = size(X);
n1 = dim_sizes(1);
n2 = dim_sizes(2:end);
n3 = floor(n1/N);
n4 = N*floor(n1/N);
if n4 < n1
    leftover_X = X((n4+1):n1,:);
    X = X(1:n4,:);
    leftover_flag = true;
    n5 = n3+1;
else
    leftover_flag = false;
    n5 = n3;
end

%Do the actual downsampling
Y = mean(reshape(X,[N n3 n2]),1);

%Attach leftover mean (from all remaining samples < N)
if leftover_flag
    Y = cat(2,Y,mean(reshape(leftover_X,[n1-n4 1 n2]),1));
end

%Return to original dimensions
Y = reshape(Y,[n5 n2]);

%Inverse permute the dimensions if necessary
if DIM~=1
    Y = ipermute(Y,permute_order);
end

end %[EoF]
