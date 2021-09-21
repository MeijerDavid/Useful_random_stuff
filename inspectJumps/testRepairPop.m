addpath('E:\Matlab Toolboxes\fieldtrip-master');
ft_defaults;

dataPath = 'E:\4. My Plan\EEG Masterclass\eeg_data_subj1\eeg';
fileName = 'David_for_master_class1.vhdr';
dataFile = [dataPath filesep fileName];

%Load the data
cfg = [];
cfg.dataset = dataFile;
data_eeg = ft_preprocessing(cfg);
data_eeg = rmfield(data_eeg,'cfg');

%Obtain 3D electrode locations, neighbours structure, and 2D layout
elec = ft_read_sens('easycap-M1.txt');                                                          %read default elec file
ref_chan = {'FCz'};                                                                             %reference channel
i_present = cellfun(@(str) sum(strcmp(str,[data_eeg.label; ref_chan])),elec.label);             %check which channels are present in eeg.label (incl. ref)
fields = {'chanpos';'chantype';'chanunit';'elecpos';'label'};                                   %standard fields in elec structure        
for i=1:length(fields); elec.(fields{i}) = elec.(fields{i})(logical(i_present),:); end          %save only info of channels that are present

cfg_neigh.method = 'template'; cfg_neigh.template = 'easycapM1_neighb';                         %read default neighbours file
neighbours = ft_prepare_neighbours(cfg_neigh);
C_temp_neigh = struct2cell(neighbours');                                                        %check which channels are present in eeg.label (incl. ref)
i_present = cellfun(@(str) sum(strcmp(str,[data_eeg.label; ref_chan])),C_temp_neigh(1,:));      %the channel order in 'elec' and 'neighbours' is not the same
neighbours = neighbours(logical(i_present));                                                    %save only info of channels that are present

cfg_lay.elec = elec; layout = ft_prepare_layout(cfg_lay);                                       %create a 2D layout file for these electrodes

%Get the triggers / events
cfg.trialdef.eventtype = '?';
dummy = ft_definetrial(cfg);
event = dummy.event; 

%Save only data within the experimental blocks (exclude breaks)     --->    Instead of deleting the data, we can just mark it as artifact! (but let's leave it here to work with fieldtrip trial structure).          
cfg.trialdef.eventtype = 'Stimulus';
cfg.trialdef.eventvalue = {'S  9'};
dummy = ft_definetrial(cfg);
begsamples = dummy.trl(:,1);

cfg.trialdef.eventvalue = {'S 10'};
dummy = ft_definetrial(cfg);
endsamples = dummy.trl(:,1);

nBlocks = length(begsamples);
data_eeg.sampleinfo = [begsamples endsamples];
data_eeg.trialinfo = 9*ones(nBlocks,1); %9 for "block"
for i=nBlocks:-1:1
    data_eeg.time{i} = ((begsamples(i):endsamples(i))-begsamples(i))/data_eeg.fsample;  %Time in seconds (beginning at 0)
    data_eeg.trial{i} = data_eeg.trial{1}(:,begsamples(i):endsamples(i));
end

%Have a look at the data and mark some real high-amplitude artifacts as such   
cfg = []; 
cfg.continuous = 'yes';
cfg.viewmode = 'butterfly';
cfg_viewed = ft_databrowser(cfg, data_eeg);
artifacts = cfg_viewed.artfctdef.visual.artifact;                                               %contains a list of the manually annotated artifact samples [begsample , endsample]

%% Here we can try to 'clean' the data using the RepairPop scheme... 

% input_arguments are "data_eeg" and "artifacts"

