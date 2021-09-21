function Cout = catCellContent(Cin,dim)
%Concatenate the content of each cell in the cell-array Cin along the
%cell-array dimension specified by 'dim' (default = first non-singleton D).
%The content within each cell will be concatenated in a new dimension.

%Get the number of dimensions of the cell-array
sizIn = size(Cin);
nDimsIn = numel(sizIn);

% By default concatenate along the first non-singleton dimension of the cell-array   
if nargin < 2; dim = find(sizIn~=1,1); end    

%Change the order of the dimensions of Cin, such that 'dim' is the last dimension
otherDims = setdiff(1:nDimsIn,dim);
Cin = permute(Cin,[otherDims dim]);

%Concatenate the content of each cell across the last dimension of the cell-array   
Cin = reshape(Cin,[prod(sizIn(otherDims)) sizIn(dim)]);
Cout = cell(prod(sizIn(otherDims)),1);
for i=1:prod(sizIn(otherDims))
    %Concatenate into an additional dimension --> note that only the
    %contents of the cells over which we concatenate need to have the same
    %size (i.e. content in Cout cells can have different sizes). 
    catDim = numel(size(Cin{i,1}))+1;
    Cout{i,1} = cat(catDim,Cin{i,:});
end
Cout = reshape(Cout,[sizIn(otherDims) 1]);

%Return the order of the dimensions as it was in Cin (where 'dim' is now a singleton dimension)  
Cout = ipermute(Cout,[otherDims dim]);  

end %[EoF]