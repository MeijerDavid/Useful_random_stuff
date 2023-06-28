function p = normcdf_diff(z1,z2)
%Precisely compute p = normcdf(z2)-normcdf(z1), avoids false p=0 returns.
%With (implicit) expansion support, but slower because it's explicit.
%
%Input arrays z1 and z2 contain z-normalized values. 
%normcdf is the standard normal cumulative distribution function.
%
%Implementation with care for numerical stability.
%Adapted from: https://github.com/cossio/TruncatedNormal.jl
%
%David Meijer, 28-6-2023

x = -z1/sqrt(2);
y = -z2/sqrt(2);

%Apply explicit expansion (see helper function below)
[x,y] = explicitExpansion(x,y);

%initialize output
p = nan(size(x));

%first condition
i1 = x > y;
if any(i1,'all')
    %Switch x and y, then multiply output by -1
    %Avoid indexing because it can be slow
    x_copy = x;
    x = ~i1.*x + i1.*y;
    y = ~i1.*y + i1.*x_copy;
end
i1_mask = 2*double(~i1)-1;    %-1 for i1, 1 for ~i1

%second condition
i2 = abs(x) > abs(y);
if any(i2,'all')
    %Multiply x and y by -1, then multiply output by -1
    %Avoid indexing because it can be slow
    x = ~i2.*x - i2.*x;
    y = ~i2.*y - i2.*y;
end
i2_mask = 2*double(~i2)-1;    %-1 for i2, 1 for ~i2

%Use erf or erfc for stability
i3 = (x < 0) & (0 <= y);
%Fastest to use indexing and vectorization here
p(i3) = .5 * (erf(x(i3)) - erf(y(i3)));
p(~i3) = .5 * (erfc(y(~i3)) - erfc(x(~i3)));

%Apply corrections for first and second conditions
p = p .* i1_mask .* i2_mask;

end %[EoF]


%%%%%%%%%%%%%%%%%%%%%%%
%%% Helper function %%%
%%%%%%%%%%%%%%%%%%%%%%%

%Replicate input arrays so that their sizes match (c.f. implicit expansion)
function varargout = explicitExpansion(varargin)

if nargin == 1
    %Special case
    varargout{1} = varargin{1};
    return;
else
    %Initialize output    
    n_var = nargin;
    varargout = cell(1,n_var);
end

%Determine maximum number of dimensions in input arrays
num_dims = nan(n_var,1);
for j=1:n_var
    num_dims(j) = numel(size(varargin{j}));
end
max_dims = max(2,max(num_dims));

%Determine size of input arrays
array_sizes = ones(n_var,max_dims);
for j=1:n_var
    array_sizes(j,1:num_dims(j)) = size(varargin{j});
end

%Determine the maximum size in each dimension across input
max_size = repmat(max(array_sizes),[n_var 1]);

%Check whether input sizes either match the maximum size or are 1
i_max = (array_sizes == max_size);
i_one = (array_sizes == 1);
assert(all(i_max | i_one,'all'), 'Input size issues');

%Expand the matrices
for j=1:n_var
    expand_vector = nan(1,max_dims);
    expand_vector(i_max(j,:)) = ones(1,sum(i_max(j,:)));
    expand_vector(i_one(j,:)) = max_size(j,i_one(j,:));
    varargout{j} = repmat(varargin{j},expand_vector);
end
    
end %[EoF]


%%%%%%%%%%%%%%%%%%%%
%%% Testing code %%%
%%%%%%%%%%%%%%%%%%%%
% 
% z1 = 100 * randn([100 1 100]);
% z2 = 100 * randn([100 100 1]);
% tic; p1 = normcdf(z2)-normcdf(z1); toc
% tic; p2 = normcdf_diff(z1,z2); toc
% num_diffs = sum(p1 ~= p2,'all')
% p1_tmp = p1(:,1,1); p2_tmp = p2(:,1,1); 
% p3 = [p1_tmp, p2_tmp, p1_tmp~=p2_tmp];    %Have a look at p3
