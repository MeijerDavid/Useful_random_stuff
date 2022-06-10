function str_values = num2str_round(values,num_digid_above_zero,num_digid_below_zero)
% Convert numbers to strings, with a certain number of digids above zero and below zero.

% Find (maximum) number of digids above zero for the current input
max_value = max(values,[],'all');
counter = 1; 
while max_value >= 10^counter; counter = counter+1; end
num_digid_above_zero_current = counter;

% Set defaults
if nargin < 3
    num_digid_below_zero = 0;
else
    num_digid_below_zero = round(num_digid_below_zero);
end
if nargin < 2
    num_digid_above_zero = counter;
else
    num_digid_above_zero = max(counter,round(num_digid_above_zero));
end

% Support vectors or matrices as input --> return a cell array of equal size with one string per cell
if numel(values) > 1
    str_values = num2cell(values);
    str_values = cellfun(@(x) num2str_round(x,num_digid_above_zero,num_digid_below_zero),str_values,'UniformOutput',false);

% Default behavior for 1 scalar input    
else 
    value = round(values,num_digid_below_zero);
    zeros2add_before = num_digid_above_zero-num_digid_above_zero_current;
    str_values = [repmat('0',[1 zeros2add_before]) num2str(value)];
    if num_digid_below_zero > 0
        zeros2add_after = (num_digid_above_zero+num_digid_below_zero) - numel(str_values) +1;
        str_values = [str_values repmat('0',[1 zeros2add_after])];
    end
end

end %[EoF]

% %Test the function!
% values = [0.001234,0.012345,0.123456,1.234560,12.345600,123.456000];
% values = [values;values];
% str_values = num2str_round(values);
% str_values = num2str_round(values,5);
% str_values = num2str_round(values,4,5);
