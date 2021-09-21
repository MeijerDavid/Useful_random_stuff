function find_jumps_data = prepare2findJumps(data)
%Prepares for findJumps.m - this function only needs to be ran once


%%%% --> This function can be written more efficiently by doing all
%%%% channels at the same time instead of using the current for-loop

%%% Perhaps I can also set some kind of threshold to repair high-amplitude
%%% jumps automatically.. 

%%% The algorithm itself can also be tuned. While the median filter is
%%% useful for finding sudden long lasting jumps in amplitude (edges). 
%%% It is not especially effective at finding short jumps that return 
%%% quickly to baseline (transients with exponential decay). Perhaps the 
%%% whole thing can be speeded up by using another filter method instead. 

%%% New proposal to find sudden amplitude jumps: 
%%% 0. Make target width variable w (default to w = 10 ms in samples)
%%% 1. Compute difference with avg of neighbours.
%%% 2. Edge preserving median filter with 2*w+1 (20 ms) window (wide enough to flatten 50Hz high-amp noise fluctuations, small enough to pick up transient spikes of >10 ms duration). 

%%% 3. Compute the accumulated change in the difference signal x over a moving window with width 10 ms (f(x) - f(x-w)) 
%%% .  N.b. The distribution of difference changes per channel should be centred around 0, and approximately normal   
%%% 4. Compute the standard deviation of difference changes over the entire recording (a rough estimate that may be biased). 
%%% 5. Using 50 bins between -6 and +6 SD create a probability distribution (discretize).
%%% 6. Fit a Gaussian to the histogram to obtain a robust estimate of mean and SD (not influenced by outliers)    -->    Instead of this approach, it's probably faster to compute the biweight estimates (see daCruz 2018)
%%% 7. Compute Z values for each sample: (x-mean)/SD
%%% 8. Based on the absolute value of the Z values we can select outliers (e.g. with cut-off of 20, but this can be a parameter setting)     

%%% Repairing jumps can be improved too. Often (but not always), there is an exponential decay following the jump. 
%%% So we fit a jump + exponential decay function to the data; see: 
%%% https://uk.mathworks.com/matlabcentral/answers/384491-how-to-do-exponential-curve-fitting-like-y-a-exp-b-x-c and https://mathworld.wolfram.com/LeastSquaresFittingExponential.html  
%%% The length of the function (left and right) can be determined based on a maximum number of zero crossings in the z-values signal (e.g. max 10): i.e. due to exp decay there is a large but slow change in opposite direction. 

%%% Or we can fit a jump + exponential decay to the data? Ensure that the decay can also be flat, because sometimes the jump is not followed by an exponential decay    

%Initialize repaired_jumps cell-array structure
nr_of_channels = size(data.label,1);
repaired_jumps = cell(nr_of_channels,2);
repaired_jumps(:,1) = data.label(:,1);
for i=1:nr_of_channels
    repaired_jumps{i,2} = cell(3,2);
    repaired_jumps{i,2}{1,1} = 'Raw_samples';
    repaired_jumps{i,2}{2,1} = 'Corrected_heights';
    repaired_jumps{i,2}{3,1} = 'Fixed in data?';
end

%Initialize ignored_jumps
ignored_jumps = [];

%Initialize artifacts
artifacts = [];

%Create nearest neighbours structures
cfg = [];
cfg.method = 'tri';
cfg.elecfile = 'standard_1005.elc'; 
nearest_neighbours = ft_prepare_neighbours(cfg, data);

%Initialize z-value cell-array
nr_of_trials = size(data.trial,2);
absdiff = cell(1,nr_of_trials);
z_values = cell(1,nr_of_trials);
total_nr_of_samples = 0;
for i=1:nr_of_trials
    absdiff{1,i} = zeros(size(data.trial{1,i}));
    z_values{1,i} = zeros(size(data.trial{1,i}));
    total_nr_of_samples = total_nr_of_samples+size(data.trial{1,i},2);
end

%%%%%%%%%
%Calculate z-values
%%%%%%%%%

order = 129;        %Medfilt1 order (window size) (129 samples = 250 ms, with fsample 512 Hz)
                    %Take N odd, then Y(k) is the median of X( k-(N-1)/2 : k+(N-1)/2 ).

ft_progress('init', 'text', 'calculating z-values');
%for all channels
for i=1:nr_of_channels
    
    %show progress
    ft_progress(i/nr_of_channels,'calculating z-values channel %d from %d\n',i,nr_of_channels);
    
    %find channel numbers of neighbours
    nr_of_neighb_chan = size(nearest_neighbours(1,i).neighblabel,1);
    neighb_chan_nrs = zeros(nr_of_neighb_chan,1);
    for j=1:nr_of_neighb_chan
        neighb_chan_nrs(j) = strmatch(nearest_neighbours(1,i).neighblabel{j}, data.label, 'exact');
    end
    
    %for all series
    collect_absdiff = zeros(1,total_nr_of_samples);
    pointer=1;
    for j=1:nr_of_trials
        %calculate difference with mean of neighbours
        original = data.trial{1,j}(i,:);
        avg_neighb = mean(data.trial{1,j}(neighb_chan_nrs,:),1);
        diff_with_neighb = original - avg_neighb;
        
        %medfilt including padding at begin and end
        pad_begin = ones(1,(order-1)/2)*median(diff_with_neighb(1:(order-1)/2));
        pad_end = ones(1,(order-1)/2)*median(diff_with_neighb((end-(order-1)/2):end));
        med_filt = medfilt1([pad_begin diff_with_neighb pad_end],order);                
        
        %abs of first derivative of medfilt result 
        absdiff_temp = [0 abs(med_filt(2:end)-med_filt(1:end-1))];
        absdiff{1,j}(i,:) = absdiff_temp(((order-1)/2+1):(end-(order-1)/2));      %excl. padding
        collect_absdiff(pointer:(pointer+size(absdiff{1,j},2)-1)) = absdiff{1,j}(i,:);
        pointer = pointer+size(absdiff{1,j},2);
    end
    
    %calculate z-values
    overall_mean = mean(collect_absdiff);
    overall_std = std(collect_absdiff);
    for j=1:nr_of_trials
        for k=1:size(absdiff{1,j},2)
            z_values{1,j}(i,k) = abs(absdiff{1,j}(i,k)-overall_mean)/overall_std;
        end
    end
end
ft_progress('close');

%Set z-values at begin and end of the series to 0
for i=1:nr_of_trials
    z_values{1,i}(:,1) = 0;
    z_values{1,i}(:,end) = 0;
end

%Create output struct
find_jumps_data.repaired_jumps = repaired_jumps;
find_jumps_data.ignored_jumps = ignored_jumps;
find_jumps_data.artifacts = artifacts;
find_jumps_data.nearest_neightbours = nearest_neighbours;
find_jumps_data.absdiff = absdiff;
find_jumps_data.z_values = z_values;


