function [data, find_jumps_data] = findJumps(data,find_jumps_data)
%Inspect and repair jumps - this function can be run several times (if you want to do it in stages)

% %%%%%%%%%%%%%%%
% % Make sure to first run find_jumps_data = prepare2findJumps(data) - before you run this file (only once)
% find_jumps_data = prepare2findJumps(data);


%%%%%%%%%%%%%%%
%Call inspectJumps2 GUI - this does not yet change the data, you only define the jumps
find_jumps_data = inspectJumps2(data, find_jumps_data);

%Repair the jumps that were found
%If some jumps were already repaired earlier, then nothing will happen (they are not repaired twice)
[data, find_jumps_data] = repairJumps(data, find_jumps_data);


% %%%%%%%%%%%%%%%
% % If you have a new dataset and none of the jumps have been repaired yet...
% % ... Then first reset the fixed repairs in ' repaired_jumps'
% for i=1:size(data.label,1)
%     find_jumps_data.repaired_jumps{i,2}{3,2} = zeros(numel(find_jumps_data.repaired_jumps{i,2}{2,2}),1);    
% end   
% % ... And only then call repairJumps.m
% [data, find_jumps_data] = repairJumps(data, find_jumps_data);