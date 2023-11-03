function [m,v] = TNmeanvar_backup(a,b,mu,sd)
%Compute mean and variance of truncated normal distribution
%
%Implementation with care for numerical stability.
%Adapted from: https://github.com/cossio/TruncatedNormal.jl
%
%David Meijer
%28-06-2023
%
%NOTE: Deprecated because of the for-loop. In new version, I used 
%vectorization. That one is ~20x faster with identical results.

%Set default inputs
if (nargin < 1) || isempty(a)
    a = -inf;
end
if (nargin < 2) || isempty(b)
    b = inf;
end
if (nargin < 3) || isempty(mu)
    mu = 0;
end
if (nargin < 4) || isempty(sd)
    sd = 1;
end

%Use a for-loop for vectorized input
if any([numel(a),numel(b),numel(mu),numel(sd)] > 1)
    
    %Apply explicit expansion (see helper function below)
    [a,b,mu,sd] = explicitExpansion(a,b,mu,sd);
    
    %Initialize output arrays
    m = nan(size(a));
    if nargout > 1
        v = nan(size(a));
    end
    
    %Compute the mean and variance for each array entry
    for j=1:numel(a)
        if nargout == 1
            m(j) = TNmeanvar_backup(a(j),b(j),mu(j),sd(j));
        elseif nargout == 2
            [m(j),v(j)] = TNmeanvar_backup(a(j),b(j),mu(j),sd(j));
        end
    end
    
    %Return function
    return;
end

%Not a standard normal? Then z-normalise first and correct m and v
if (mu~=0) || (sd~=1)
    
    assert(sd > 0,'sd must be larger than zero, but sd=%d',sd);
    assert(~isinf(mu) && ~isnan(mu),'mu cannot be infinite or NaN, but mu=%d',mu);
    assert(~isinf(sd) && ~isnan(sd),'sd cannot be infinite or NaN, but sd=%d',sd);
    
    a = (a-mu) / sd;
    b = (b-mu) / sd;
    
    if nargout == 1
        m = TNmeanvar_backup(a,b);
    elseif nargout == 2
        [m,v] = TNmeanvar_backup(a,b); 
        v = v * sd^2;   %correct variance
    end    
    m = mu + m*sd;      %correct mean
    
    %Return function
    return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Standard normal input %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Special cases
if isnan(a) || isnan(b)
    m = NaN;
    v = NaN;
    warning('NaN returned because a or b is NaN: a=%d, b=%d',a,b);
elseif a > b
    m = NaN;
    v = NaN;
    warning('NaN returned because a > b: a=%d, b=%d',a,b);
elseif a == b
    m = a;
    v = 0;
elseif isinf(a) && isinf(b)
    m = 0;
    v = 1;
    
%Improve numerical stability    
elseif abs(a) > abs(b)
    if nargout == 1
        m = -TNmeanvar_backup(-b,-a);
    elseif nargout == 2
        [m,v] = TNmeanvar_backup(-b,-a); 
        m = -m;
    end

%Special case for variance only
elseif (nargout == 2) && isinf(b)
    
    %Compute mean (i.e. first moment of truncated normal)
    m = TNmeanvar_backup(a,b);
    
    %Compute second moment (m2) of truncated normal
    m2 = 1 + sqrt(2/pi) * a / erfcx(a / sqrt(2));
    
    %Convert second moment (m2) into variance (second central moment)
    m2 = sqrt(m2);
    v = (m2 - m) * (m2 + m);
    
%Default behaviour    
else
    
    %Compute mean (i.e. first moment of truncated normal)
    delta = (b-a) * .5*(a+b);

    if (a <= 0) && (0 <= b)
        m = sqrt(2/pi) * expm1(-delta) * exp(-a^2 / 2) / erfcDiff(a/sqrt(2),b/sqrt(2));   %see helper function below 
        
        %Compute second moment too?
        if nargout == 2
            
            ea = sqrt(pi/2) * erf(a / sqrt(2));
            eb = sqrt(pi/2) * erf(b / sqrt(2));
            fa = ea - a * exp(-a^2 / 2);
            fb = eb - b * exp(-b^2 / 2);
            m2 = (fb - fa) / (eb - ea);
            
            assert((fb >= fa) && (eb >= ea),'a=%d, b=%d',a,b);
            assert((0 <= m2) && (m2 <= 1),'a=%d, b=%d',a,b);
        end
        
    elseif (0 < a) && (a < b)
        z = exp(-delta) * erfcx(b/sqrt(2)) - erfcx(a/sqrt(2));
        if z == 0
            m = .5*(a+b);
        else
            m = sqrt(2/pi) * expm1(-delta) / z;
        end
        
        %Compute second moment too?
        if nargout == 2
            
            ex_delta = exp((a - b) * .5*(a+b));
            ea = sqrt(pi/2) * erfcx(a / sqrt(2));
            eb = sqrt(pi/2) * erfcx(b / sqrt(2));
            fa = ea + a;
            fb = eb + b;
            m2 = (fa - fb * ex_delta) / (ea - eb * ex_delta);
            
            assert((a^2 <= m2) && (m2 <= b^2),'a=%d, b=%d',a,b);
        end
    else
        error('invalid combination of a and b: a=%d, b=%d',a,b);
    end
    
    %minor correction for numerical issues on mean
    assert(~isinf(m) && ~isnan(m),'Mean of TN is inf or nan, a=%d, b=%d',a,b);
    m = min(max(m,a),b);
    
    %Compute variance too?
    if nargout == 2
        
        %Convert second moment (m2) into variance (second central moment)
        m2 = sqrt(m2);
        v = (m2 - m) * (m2 + m);
        
        %minor correction for numerical issues on variance
        assert(~isinf(v) && ~isnan(v),'Variance of TN is inf or nan, a=%d, b=%d',a,b);
        v = min(max(v,0),1);    
        %N.B. variance of truncated standard normal is always <= 1, see ...
        %https://mathoverflow.net/questions/200573/variance-of-truncated-normal-distribution
    end
    
end %end of if-statement special cases
    
end %[EoF]

%%%%%%%%%%%%%%%%%%%%%%%%
%%% Helper functions %%%
%%%%%%%%%%%%%%%%%%%%%%%%

%Compute erfc difference: erfc(y) - erfc(x)
function delta_erfc = erfcDiff(x,y)

%Make use of symmetry
if x > y
    delta_erfc = -erfcDiff(y,x);
elseif abs(x) > abs(y)
    delta_erfc = -erfcDiff(-x,-y);
elseif (x < 0) && (0 <= y)
    delta_erfc = erf(x) - erf(y);
elseif (0 <= x) && (x <= y)
    delta_erfc = erfc(y) - erfc(x);
else
    error('Unknown condition: unable to compute erfc difference');
end
    
end %[EoF]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

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
