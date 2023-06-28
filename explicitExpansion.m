function varargout = explicitExpansion(varargin)
%Replicate input arrays so that their sizes match (c.f. implicit expansion)

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
