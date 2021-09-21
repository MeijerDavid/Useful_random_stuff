function [data, find_jumps_data] = repairJumps(data,find_jumps_data)

% repaired_jumps = find_jumps_data.repaired_jumps;
repaired_jumps = find_jumps_data;

% repaired_jumps(:,1) = 'Channels Labels';
% repaired_jumps{i,2}{1,2} = 'Raw_samples';
% repaired_jumps{i,2}{2,2} = 'Corrected_heights';
% repaired_jumps{i,2}{3,2} = 'Fixed in data?';

% nearest_neighbours = find_jumps_data.nearest_neightbours;
cfg = [];
cfg.method = 'tri';
cfg.elecfile = 'standard_1005.elc'; 
nearest_neighbours = ft_prepare_neighbours(cfg, data);      %Create nearest neighbours structures

%For all given channels - we repair all the unfixed jumps
for channr = 1:size(repaired_jumps,1)
    if ~isempty(repaired_jumps{channr,2}{1,2})              %if there are jumps to fix
        for i=1:size(repaired_jumps{channr,2}{1,2},1)           %for all jumps in this channel
            if repaired_jumps{channr,2}{3,2}(i) == 0                %if not fixed yet
                
                %find the position of the jump in trial_nr and sample_nrs (within the trial)
                raw_sample_begin = repaired_jumps{channr,2}{1,2}(i,1);
                raw_sample_end = repaired_jumps{channr,2}{1,2}(i,2);
                possible_begin_nrs = find(raw_sample_begin >= data.sampleinfo(:,1));
                possible_end_nrs = find(raw_sample_end <= data.sampleinfo(:,2));
                trial_nr = intersect(possible_begin_nrs,possible_end_nrs);
                sample_nrs = raw_sample_begin-data.sampleinfo(trial_nr,1)+1;
                sample_nrs = sample_nrs:(raw_sample_end-data.sampleinfo(trial_nr,1)+1);
                
                %Extra check of channels - just in case data.label does not agree anymore with the channels in repaired_jumps
                %chan is number of channel in data structure (channr is nr of channel in repaired_jumps)
                chan = strmatch(repaired_jumps{channr,1}, data.label, 'exact');                
                
                %find neighbours of channel
                neighb_chan_nrs = zeros(size(nearest_neighbours(1,channr).neighblabel,1),1);
                for j=1:size(nearest_neighbours(1,channr).neighblabel,1)
                    neighb_chan_nrs(j) = strmatch(nearest_neighbours(1,channr).neighblabel{j},data.label, 'exact');
                end
                
                %Correction Height
                if sample_nrs(1)~=1
                    begin_height = data.trial{1,trial_nr}(chan,sample_nrs(1)-1);
                else
                    begin_height = 0;
                end
                end_height = data.trial{1,trial_nr}(chan,sample_nrs(end));
                correction_height = end_height-begin_height;   
                repaired_jumps{channr,2}{2,2}(i) = correction_height;
                
                %Create repaired data for jump
                if sample_nrs(1)~=1
                    uncorrected_first_part = data.trial{1,trial_nr}(chan,1:(sample_nrs(1)-1));
                    interpolation_start_height = uncorrected_first_part(end);
                    beg_neighb = sample_nrs(1)-1;
                else
                    uncorrected_first_part = [];
                    interpolation_start_height = 0;
                    beg_neighb = sample_nrs(1);
                end
                if sample_nrs(end) ~= size(data.trial{1,trial_nr},2)
                    corrected_last_part = data.trial{1,trial_nr}(chan,(sample_nrs(end)+1):size(data.trial{1,trial_nr},2))-correction_height;
                    interpolation_end_height = corrected_last_part(1);
                    end_neighb = sample_nrs(end)+1;
                else
                    corrected_last_part = [];
                    interpolation_end_height = 0;
                    end_neighb = sample_nrs(end);
                end     
                lin_interpolation_broad = linspace(interpolation_start_height,interpolation_end_height,numel(sample_nrs)+2);
        
                neighb_interpolation = mean(data.trial{1,trial_nr}(neighb_chan_nrs, [beg_neighb sample_nrs end_neighb]),1);
                lin_neighb_interpolation = linspace(neighb_interpolation(1),neighb_interpolation(end),numel(sample_nrs)+2);
                neighb_interpolation_corrected = neighb_interpolation - lin_neighb_interpolation;       %begin and end are zero

                interpolation_broad = lin_interpolation_broad + neighb_interpolation_corrected;
                interpolation = interpolation_broad(2:end-1);
                
                repaired_full_trial = [uncorrected_first_part interpolation corrected_last_part];
                repaired_full_trial = ft_preproc_detrend(repaired_full_trial);

                %Do the repair and update structure
                data.trial{1,trial_nr}(chan,:) = repaired_full_trial;
                repaired_jumps{channr,2}{3,2}(i) = 1;
                    
            end
        end
    end
end

% find_jumps_data.repaired_jumps = repaired_jumps;
find_jumps_data = repaired_jumps;