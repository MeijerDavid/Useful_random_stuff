function [backSettings,varargout] = rotateDims2first(dim_or_backSettings,varargin)
% Rotate the dimensions such that 'dim' becomes the first dimension and so
% that all other dimensions are concatenated into the second dimension. 
% Subsequently, use the first output to return to the original dimensions.
%
% Example (imagine a more complex function instead of 'sum'): 
% a1 = randn(3,7,4,1,5);
% b1 = randn(3,7,4,1,5);
% dim = 3;
% [backSettings,c1,d1] = rotateDims2first(dim,a1,b1);
% c2 = sum(c1,1); d2 = sum(d1,1); 
% [~,a2,b2] = rotateDims2first(backSettings,c2,d2);
% isequal(sum(a1,dim),a2) && isequal(sum(b1,dim),b2)

%% Determine direction
if isstruct(dim_or_backSettings)
    direction = 'back';
    backSettings = dim_or_backSettings;
else
    direction = 'forward';
    dim = dim_or_backSettings;
end

%% Forward rotation (make 'dim' the first dimenion)
if strcmp(direction,'forward')
    
    num_vars = numel(varargin);
    assert(num_vars >= 1,'No input variables were provided');

    %Check that all input variables have the same size
    for i=1:num_vars
        assert(isequal(size(varargin{1}),size(varargin{i})),'All input variables must have equal size');
    end
    original_size = size(varargin{1});
    num_dims = numel(original_size);

    %If operation is requested over non-first dimension, then make that dimension the first dimension   
    if dim~=1
        other_dims = setdiff(1:num_dims,dim);     
        new_dim_order = [dim other_dims];
        for i=1:num_vars
            varargin{i} = permute(varargin{i},new_dim_order);
        end
        original_size = original_size(new_dim_order);
    end

    %Ensure 2D matrices (reshape if necessary - i.e. concatenate all dimensions > 2 into the second dimension)
    if num_dims > 2
        [num_rows,num_cols] = size(varargin{i});
        for i=1:num_vars
            varargin{i} = reshape(varargin{i},[num_rows num_cols]);
        end
    end

    %Assign output
    backSettings.dim = dim;
    backSettings.original_size = original_size;
    varargout = varargin;

%% Back rotation (move the first dimension into the 'dim' dimenion)
elseif strcmp(direction,'back')
    
    dim = backSettings.dim;
    original_size = backSettings.original_size;
    
    num_vars = numel(varargin);
    assert(num_vars >= 1,'No input variables were provided');

    %Re-expand the second dimension if it was previously concatenated
    num_dims = numel(original_size);
    if num_dims > 2
        new_first_dim_size = size(varargin{1},1);
        new_size = [new_first_dim_size original_size(2:end)];
        for i=1:num_vars
            varargin{i} = reshape(varargin{i},new_size);
        end
    end

    %If operation was requested over non-first dimension, then return to the original dimension order  
    if dim~=1
        other_dims = setdiff(1:num_dims,dim);     
        new_dim_order = [dim other_dims];
        for i=1:num_vars
            varargin{i} = ipermute(varargin{i},new_dim_order);
        end
    end

    %Assign output
    backSettings.new_size = size(varargin{1});
    varargout = varargin;

%% Throw an error if an unknown direction was given as input     
else
    error('Unknown function direction. Use either "forward" or "back".');
end

end %[EoF]
