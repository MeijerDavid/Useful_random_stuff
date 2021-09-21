function SA = cell2structArray(C)
%Create a structArray from all structs in the cell-array (i.e. concatenate)
%We assume that all structures in the cells have the same fields etc.

s = size(C);
SA = [C{:}];
SA = reshape(SA,s);

end %[EoF]