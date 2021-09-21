function SA = struct2structArray(S,dim)
%Convert simple structure S with equal-sized fields, all numerical arrays, 
%to a structure-array SA, where 'dim' specifies which dimensions of the 
%arrays (fields) to keep in each structure-array item/cel: see 'num2cell'.

C = fieldnames(S);
nFields = length(C);

%If not specified, set dim to a trailing dimension.
%This means that all dimensions of each field are split.
if nargin < 2 
    dim = numel(size(S.(C{1})))+1; 
end

%Split the array of each field into a cell-array
C(:,2) = cell(nFields,1);
for f=1:nFields
    C{f,2} = num2cell(S.(C{f}),dim);
end
    
%Convert the cell-array to a structure array
C = C';
SA = struct(C{:});

end %[EoF]