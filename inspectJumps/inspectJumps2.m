function varargout = inspectJumps2(varargin)
% INSPECTJUMPS2 MATLAB code for inspectJumps2.fig
%      INSPECTJUMPS2, by itself, creates a new INSPECTJUMPS2 or raises the existing
%      singleton*.f
%
%      H = INSPECTJUMPS2 returns the handle to a new INSPECTJUMPS2 or the handle to
%      the existing singleton*.
%
%      INSPECTJUMPS2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in INSPECTJUMPS2.M with the given input arguments.
%
%      INSPECTJUMPS2('Property','Value',...) creates a new INSPECTJUMPS2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before inspectJumps2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to inspectJumps2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help inspectJumps2

% Last Modified by GUIDE v2.5 18-Apr-2014 13:45:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @inspectJumps2_OpeningFcn, ...
                   'gui_OutputFcn',  @inspectJumps2_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before inspectJumps is made visible.
function inspectJumps2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to inspectJumps (see VARARGIN)
handles.data = varargin{1};
find_jumps_data = varargin{2};

handles.repaired_jumps = find_jumps_data.repaired_jumps;
handles.ignored_jumps = find_jumps_data.ignored_jumps;
handles.artifacts = find_jumps_data.artifacts;
handles.nearest_neighbours = find_jumps_data.nearest_neightbours;
handles.absdiff = find_jumps_data.absdiff;
handles.z_values = find_jumps_data.z_values;

%Initialize nr_of_trials and total_nr_of_samples
handles.nr_of_channels = size(handles.data.label,1);
handles.nr_of_trials = size(handles.data.trial,2);
handles.total_nr_of_samples = 0;
for i=1:handles.nr_of_trials
    handles.total_nr_of_samples = handles.total_nr_of_samples+size(handles.data.trial{1,i},2);
end

handles.jumpPointer = 1;

handles.stick2Chan = 0;
set(handles.buttonReady,'Enable','off');
set(handles.buttonPreviousJump,'Enable','off');
set(handles.buttonNextJump,'Enable','off');

%Find maximum z-values per channel and record in which trial it was found
handles.max_z_per_channel = zeros(1,handles.nr_of_channels);
handles.max_z_trialnr_per_channel = ones(1,handles.nr_of_channels);
for i=1:handles.nr_of_channels
    for j=1:handles.nr_of_trials
        max_in_trial = max(handles.z_values{1,j}(i,:));
        if max_in_trial > handles.max_z_per_channel(i)
            handles.max_z_per_channel(i) = max_in_trial;
            handles.max_z_trialnr_per_channel(i) = j;
        end
    end
end

%Begin GUI
handles = updateZvalues(handles);
handles = updateJump(handles);

% Choose default command line output for inspectJumps
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
% UIWAIT makes inspectJumps wait for user response (see UIRESUME)
uiwait(handles.figureInspectJumps);

% --- Outputs from this function are returned to the command line.
function varargout = inspectJumps2_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);

%Create output struct
find_jumps_data.repaired_jumps = handles.repaired_jumps;
find_jumps_data.ignored_jumps = handles.ignored_jumps;
find_jumps_data.artifacts = handles.artifacts;
find_jumps_data.nearest_neightbours = handles.nearest_neighbours;
find_jumps_data.absdiff = handles.absdiff;
find_jumps_data.z_values = handles.z_values;

% Get default command line output from handles structure
varargout{1} = find_jumps_data;

close(handles.figureInspectJumps);

% --- Executes after inserting value and pressing 'Enter'
function editTextSetThreshold_Callback(hObject, eventdata, handles)
% get new threshold value
handles.threshold = str2double(get(hObject,'String'));

% We keep looking in this channel untill 'ready' is pressed
handles.stick2Chan = 1;
set(handles.buttonReady,'Enable','on');
set(handles.buttonPreviousJump,'Enable','on');
set(handles.buttonNextJump,'Enable','on');

handles = updateZvalues(handles);
handles = updateJump(handles);
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function editTextSetThreshold_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function editTextSetChannel_Callback(hObject, eventdata, handles)
% go to new channel nr
new_channel_nr = str2double(get(hObject,'String')); 
if isempty(new_channel_nr)
    set(handles.editTextSetChannel,'String',num2str(handles.chan_nr));
else
    handles.chan_nr = new_channel_nr;
    handles.threshold = handles.max_z_per_channel(new_channel_nr)-0.01;

    % We keep looking in this channel untill 'ready' is pressed
    handles.stick2Chan = 1;
    set(handles.buttonReady,'Enable','on');
    set(handles.buttonPreviousJump,'Enable','on');
    set(handles.buttonNextJump,'Enable','on');

    handles = updateZvalues(handles);
    handles = updateJump(handles); 
end
guidata(hObject, handles);

% --- Executes on button press in buttonNextChannel.
function buttonNextChannel_Callback(hObject, eventdata, handles)
% go to next channel nr
if handles.chan_nr < handles.nr_of_channels
    handles.chan_nr = handles.chan_nr+1;
    handles.threshold = handles.max_z_per_channel(handles.chan_nr)-0.01;

    % We keep looking in this channel untill 'ready' is pressed
    handles.stick2Chan = 1;
    set(handles.buttonReady,'Enable','on');
    set(handles.buttonPreviousJump,'Enable','on');
    set(handles.buttonNextJump,'Enable','on');

    handles = updateZvalues(handles);
    handles = updateJump(handles); 
end
guidata(hObject, handles);


% --- Executes on button press in buttonPreviousChannel.
function buttonPreviousChannel_Callback(hObject, eventdata, handles)
% go to previous channel nr
if handles.chan_nr > 1
    handles.chan_nr = handles.chan_nr-1;
    handles.threshold = handles.max_z_per_channel(handles.chan_nr)-0.01;

    % We keep looking in this channel untill 'ready' is pressed
    handles.stick2Chan = 1;
    set(handles.buttonReady,'Enable','on');
    set(handles.buttonPreviousJump,'Enable','on');
    set(handles.buttonNextJump,'Enable','on');

    handles = updateZvalues(handles);
    handles = updateJump(handles); 
end
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function editTextSetChannel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in buttonNextJump.
function buttonNextJump_Callback(hObject, eventdata, handles)
% Go to next jump
jumpPointer_new = handles.jumpPointer+1;
if jumpPointer_new > size(handles.list_of_jumps,1);
    jumpPointer_new = 1;
end
if jumpPointer_new ~= handles.jumpPointer
    handles.jumpPointer = jumpPointer_new;
    handles = updateZvalues(handles);
    handles = updateJump(handles);
    guidata(hObject, handles);
end

% --- Executes on button press in buttonPreviousJump.
function buttonPreviousJump_Callback(hObject, eventdata, handles)
% Go to previous jump
jumpPointer_new = handles.jumpPointer-1;
if jumpPointer_new < 1
    jumpPointer_new = size(handles.list_of_jumps,1);
end
if jumpPointer_new ~= handles.jumpPointer
    handles.jumpPointer = jumpPointer_new;
    handles = updateZvalues(handles);
    handles = updateJump(handles);
    guidata(hObject, handles);
end

% --- Executes on button press in buttonWidthAfterMore.
function buttonWidthAfterMore_Callback(hObject, eventdata, handles)
% Increase width of jump on right side with 1
raw_sample_begin = handles.list_of_jumps(handles.jumpPointer,1);
raw_sample_end = handles.list_of_jumps(handles.jumpPointer,2);
possible_begin_nrs = find(raw_sample_begin >= handles.data.sampleinfo(:,1));
possible_end_nrs = find(raw_sample_end <= handles.data.sampleinfo(:,2));
trial_nr = intersect(possible_begin_nrs,possible_end_nrs);

if handles.data.sampleinfo(trial_nr,2) > handles.list_of_jumps(handles.jumpPointer,2)
    handles.list_of_jumps(handles.jumpPointer,2) = handles.list_of_jumps(handles.jumpPointer,2)+1;
    handles = updateJump(handles);
    guidata(hObject, handles);
end

% --- Executes on button press in buttonAfterMore10.
function buttonAfterMore10_Callback(hObject, eventdata, handles)
% Increase width of jump on right side with 10
raw_sample_begin = handles.list_of_jumps(handles.jumpPointer,1);
raw_sample_end = handles.list_of_jumps(handles.jumpPointer,2);
possible_begin_nrs = find(raw_sample_begin >= handles.data.sampleinfo(:,1));
possible_end_nrs = find(raw_sample_end <= handles.data.sampleinfo(:,2));
trial_nr = intersect(possible_begin_nrs,possible_end_nrs);

if handles.data.sampleinfo(trial_nr,2) > handles.list_of_jumps(handles.jumpPointer,2)+9
    handles.list_of_jumps(handles.jumpPointer,2) = handles.list_of_jumps(handles.jumpPointer,2)+10;
    handles = updateJump(handles);
    guidata(hObject, handles);
end

% --- Executes on button press in buttonWidthAfterLess.
function buttonWidthAfterLess_Callback(hObject, eventdata, handles)
% Decrease width of jump on right side with 1
if handles.width_of_jump > 1
    handles.list_of_jumps(handles.jumpPointer,2) = handles.list_of_jumps(handles.jumpPointer,2)-1;
    handles = updateJump(handles);
    guidata(hObject, handles);
end

% --- Executes on button press in buttonAfterLess10.
function buttonAfterLess10_Callback(hObject, eventdata, handles)
% Decrease width of jump on right side with 10
if handles.width_of_jump > 10
    handles.list_of_jumps(handles.jumpPointer,2) = handles.list_of_jumps(handles.jumpPointer,2)-10;
    handles = updateJump(handles);
    guidata(hObject, handles);
end

% --- Executes on button press in buttonWidthBeforeMore.
function buttonWidthBeforeMore_Callback(hObject, eventdata, handles)
% Increase width of jump on left side with 1
raw_sample_begin = handles.list_of_jumps(handles.jumpPointer,1);
raw_sample_end = handles.list_of_jumps(handles.jumpPointer,2);
possible_begin_nrs = find(raw_sample_begin >= handles.data.sampleinfo(:,1));
possible_end_nrs = find(raw_sample_end <= handles.data.sampleinfo(:,2));
trial_nr = intersect(possible_begin_nrs,possible_end_nrs);

if handles.data.sampleinfo(trial_nr,1) < handles.list_of_jumps(handles.jumpPointer,1)
    handles.list_of_jumps(handles.jumpPointer,1) = handles.list_of_jumps(handles.jumpPointer,1)-1;
    handles = updateJump(handles);
    guidata(hObject, handles);
end

% --- Executes on button press in buttonBeforeMore10.
function buttonBeforeMore10_Callback(hObject, eventdata, handles)
% Increase width of jump on left side with 10
raw_sample_begin = handles.list_of_jumps(handles.jumpPointer,1);
raw_sample_end = handles.list_of_jumps(handles.jumpPointer,2);
possible_begin_nrs = find(raw_sample_begin >= handles.data.sampleinfo(:,1));
possible_end_nrs = find(raw_sample_end <= handles.data.sampleinfo(:,2));
trial_nr = intersect(possible_begin_nrs,possible_end_nrs);

if handles.data.sampleinfo(trial_nr,1)+9 < handles.list_of_jumps(handles.jumpPointer,1)
    handles.list_of_jumps(handles.jumpPointer,1) = handles.list_of_jumps(handles.jumpPointer,1)-10;
    handles = updateJump(handles);
    guidata(hObject, handles);
end

% --- Executes on button press in buttonWidthBeforeLess.
function buttonWidthBeforeLess_Callback(hObject, eventdata, handles)
% Decrease width of jump on left side with 1
if handles.width_of_jump > 1
    handles.list_of_jumps(handles.jumpPointer,1) = handles.list_of_jumps(handles.jumpPointer,1)+1;
    handles = updateJump(handles);
    guidata(hObject, handles);
end

% --- Executes on button press in buttonBeforeLess10.
function buttonBeforeLess10_Callback(hObject, eventdata, handles)
% Decrease width of jump on left side with 10
if handles.width_of_jump > 10
    handles.list_of_jumps(handles.jumpPointer,1) = handles.list_of_jumps(handles.jumpPointer,1)+10;
    handles = updateJump(handles);
    guidata(hObject, handles);
end

% --- Executes on button press in buttonIgnore.
function buttonIgnore_Callback(hObject, eventdata, handles)
% Ignore the current jump - reset its z-values to zero

%find the position of the jump in trial_nr and sample_nrs
raw_sample_begin = handles.list_of_jumps(handles.jumpPointer,1);
raw_sample_end = handles.list_of_jumps(handles.jumpPointer,2);
possible_begin_nrs = find(raw_sample_begin >= handles.data.sampleinfo(:,1));
possible_end_nrs = find(raw_sample_end <= handles.data.sampleinfo(:,2));
trial_nr = intersect(possible_begin_nrs,possible_end_nrs);
sample_nrs = handles.list_of_jumps(handles.jumpPointer,1)-handles.data.sampleinfo(trial_nr,1)+1;
sample_nrs = sample_nrs:(handles.list_of_jumps(handles.jumpPointer,2)-handles.data.sampleinfo(trial_nr,1)+1);

%Set zValues to zero with a maximum of 25 samples around the jump
if sample_nrs(1) > 25
    sample_nrs = (sample_nrs(1)-25):sample_nrs(end);
else
    sample_nrs = [1:(sample_nrs(1)-1) sample_nrs];
end
if sample_nrs(end)+25 > size(handles.z_values{1,trial_nr},2)
    sample_nrs = sample_nrs(1):size(handles.z_values{1,trial_nr},2);
else
    sample_nrs = [sample_nrs (sample_nrs(end)+1):(sample_nrs(end)+25)];
end
handles.z_values{1,trial_nr}(handles.chan_nr, sample_nrs) = 0;

%find new maximum of channel if we changed something in the trial that contained the maximum z-value
if sum(trial_nr == handles.max_z_trialnr_per_channel(handles.chan_nr))
    handles.max_z_per_channel(handles.chan_nr) = 0;
    for j=1:handles.nr_of_trials
        max_in_trial = max(handles.z_values{1,j}(handles.chan_nr,:));
        if max_in_trial > handles.max_z_per_channel(handles.chan_nr)
            handles.max_z_per_channel(handles.chan_nr) = max_in_trial;
            handles.max_z_trialnr_per_channel(handles.chan_nr) = j;
        end
    end
end

%Add new ignored_jump to existing ignored_jumps and sort them according to raw_chan_nr        
raw_sample_nrs = [sample_nrs(1) sample_nrs(end)]+handles.data.sampleinfo(trial_nr,1)-1;
handles.ignored_jumps = [handles.ignored_jumps; raw_sample_nrs handles.chan_nr];
[handles.ignored_jumps(:,3), orig_indices] = sort(handles.ignored_jumps(:,3)); 
handles.ignored_jumps(:,1) = handles.ignored_jumps(orig_indices,1);
handles.ignored_jumps(:,2) = handles.ignored_jumps(orig_indices,2);
%check for overlap
if size(handles.ignored_jumps,1)>1
    for i=size(handles.ignored_jumps,1):-1:2
        if handles.ignored_jumps(i,3) == handles.ignored_jumps(i-1,3)       %if previous is in the same channel
            ignored_jump_starts = handles.ignored_jumps([i-1 i],1);
            ignored_jump_ends = handles.ignored_jumps([i-1 i],2);
            if ignored_jump_starts(2) <= ignored_jump_ends(1)+1                 %if beginning starts before the previous has ended
                ignored_jump_starts(2) = [];
                if ignored_jump_ends(1) <= ignored_jump_ends(2)                    %if end is bigger than the previous end
                    ignored_jump_ends(1) = [];                                          %connect them
                else                                                                %if the previous end is later in time
                    ignored_jump_ends(2) = [];                                          %then delete this one completely and leave the previous
                end
                handles.ignored_jumps(i,:) = [];
                handles.ignored_jumps(i-1,1) = ignored_jump_starts;
                handles.ignored_jumps(i-1,2) = ignored_jump_ends;
            end    
        end
    end
end

%go to next jump
handles = updateZvalues(handles);
handles = updateJump(handles);
guidata(hObject, handles);

% --- Executes on button press in buttonSaveAsArtifact.
function buttonSaveAsArtifact_Callback(hObject, eventdata, handles)
% Save the current jump as artifact - reset its z-values to zero in all channels

%find the position of the jump in trial_nr and sample_nrs
raw_sample_begin = handles.list_of_jumps(handles.jumpPointer,1);
raw_sample_end = handles.list_of_jumps(handles.jumpPointer,2);
possible_begin_nrs = find(raw_sample_begin >= handles.data.sampleinfo(:,1));
possible_end_nrs = find(raw_sample_end <= handles.data.sampleinfo(:,2));
trial_nr = intersect(possible_begin_nrs,possible_end_nrs);
sample_nrs = handles.list_of_jumps(handles.jumpPointer,1)-handles.data.sampleinfo(trial_nr,1)+1;
sample_nrs = sample_nrs:(handles.list_of_jumps(handles.jumpPointer,2)-handles.data.sampleinfo(trial_nr,1)+1);

%Set zValues to zero with a maximum of 25 samples around the artifact in all channels
if sample_nrs(1) > 25
    sample_nrs = (sample_nrs(1)-25):sample_nrs(end);
else
    sample_nrs = [1:(sample_nrs(1)-1) sample_nrs];
end
if sample_nrs(end)+25 > size(handles.z_values{1,trial_nr},2)
    sample_nrs = sample_nrs(1):size(handles.z_values{1,trial_nr},2);
else
    sample_nrs = [sample_nrs (sample_nrs(end)+1):(sample_nrs(end)+25)];
end
handles.z_values{1,trial_nr}(:, sample_nrs) = 0;

%Find new maximum of channels if we changed something in the trial that contained the maximum z-value
for i=1:handles.nr_of_channels    
    if sum(trial_nr == handles.max_z_trialnr_per_channel(i)) %if something changed in the trial that contained maximum z-value
        %find new maximum of channel
        handles.max_z_per_channel(i) = 0;
        for j=1:handles.nr_of_trials
            max_in_trial = max(handles.z_values{1,j}(i,:));
            if max_in_trial > handles.max_z_per_channel(i)
                handles.max_z_per_channel(i) = max_in_trial;
                handles.max_z_trialnr_per_channel(i) = j;
            end
        end
    end
end

%Add new artifact to existing artifacts and sort them according to raw_start_samples
raw_sample_nrs = [sample_nrs(1) sample_nrs(end)]+handles.data.sampleinfo(trial_nr,1)-1;
handles.artifacts = [handles.artifacts; raw_sample_nrs];
[handles.artifacts(:,1), orig_indices] = sort(handles.artifacts(:,1)); 
handles.artifacts(:,2) = handles.artifacts(orig_indices,2);
%check for overlap
if size(handles.artifacts,1)>1
    artifact_starts = handles.artifacts(:,1);
    artifact_ends = handles.artifacts(:,2);
    for i=numel(artifact_starts):-1:2
        if artifact_starts(i) <= artifact_ends(i-1)+1         %if beginning starts before the previous artifact has ended
            artifact_starts(i) = [];
            if artifact_ends(i-1) <= artifact_ends(i)              %if end is bigger than the previous end
                artifact_ends(i-1) = [];                                  %connect them
            else                                                   %if the previous end is later in time
                artifact_ends(i) = [];                                    %then delete this artifact and leave the previous
            end
        end
    end
    handles.artifacts = [artifact_starts artifact_ends];
end

%go to next jump
handles = updateZvalues(handles);
handles = updateJump(handles);
guidata(hObject, handles);

% --- Executes on button press in buttonAcceptRepair.
function buttonAcceptRepair_Callback(hObject, eventdata, handles)
% Save the current jump - reset its z-values to zero

%find the position of the jump in trial_nr and sample_nrs
raw_sample_begin = handles.list_of_jumps(handles.jumpPointer,1);
raw_sample_end = handles.list_of_jumps(handles.jumpPointer,2);
possible_begin_nrs = find(raw_sample_begin >= handles.data.sampleinfo(:,1));
possible_end_nrs = find(raw_sample_end <= handles.data.sampleinfo(:,2));
trial_nr = intersect(possible_begin_nrs,possible_end_nrs);
sample_nrs = handles.list_of_jumps(handles.jumpPointer,1)-handles.data.sampleinfo(trial_nr,1)+1;
sample_nrs = sample_nrs:(handles.list_of_jumps(handles.jumpPointer,2)-handles.data.sampleinfo(trial_nr,1)+1);

%Set zValues to zero
if sample_nrs(1) > 25
    sample_nrs = (sample_nrs(1)-25):sample_nrs(end);
else
    sample_nrs = [1:(sample_nrs(1)-1) sample_nrs];
end
if sample_nrs(end)+25 > size(handles.z_values{1,trial_nr},2)
    sample_nrs = sample_nrs(1):size(handles.z_values{1,trial_nr},2);
else
    sample_nrs = [sample_nrs (sample_nrs(end)+1):(sample_nrs(end)+25)];
end
handles.z_values{1,trial_nr}(handles.chan_nr, sample_nrs) = 0;

%find new maximum of channel if we changed something in the trial that contained the maximum z-value
chan_nr = handles.chan_nr;
if sum(trial_nr == handles.max_z_trialnr_per_channel(chan_nr))
    handles.max_z_per_channel(chan_nr) = 0;
    for j=1:handles.nr_of_trials
        max_in_trial = max(handles.z_values{1,j}(chan_nr,:));
        if max_in_trial > handles.max_z_per_channel(chan_nr)
            handles.max_z_per_channel(chan_nr) = max_in_trial;
            handles.max_z_trialnr_per_channel(chan_nr) = j;
        end
    end
end

%update data for internal use
handles.data.trial{1,trial_nr}(chan_nr, :) = handles.repaired_full_trial;

%update z-values of its neighbours
neighb_chan_nrs = zeros(size(handles.nearest_neighbours(1,chan_nr).neighblabel,1),1);
for i=1:size(handles.nearest_neighbours(1,chan_nr).neighblabel,1)
    neighb_chan_nrs(i) = strmatch(handles.nearest_neighbours(1,chan_nr).neighblabel{i},handles.data.label, 'exact');
end
handles = updateZValuesAll(handles,neighb_chan_nrs,trial_nr);

%add new jump to repaired_jumps and sort them according to raw_start_samples    
new_jump = handles.list_of_jumps(handles.jumpPointer,:);
handles.repaired_jumps{chan_nr,2}{1,2} = [handles.repaired_jumps{chan_nr,2}{1,2}; new_jump];                     %'Raw_samples'
[handles.repaired_jumps{chan_nr,2}{1,2}(:,1), orig_indices] = sort(handles.repaired_jumps{chan_nr,2}{1,2}(:,1));      
handles.repaired_jumps{chan_nr,2}{1,2}(:,2) = handles.repaired_jumps{chan_nr,2}{1,2}(orig_indices,2);                 
handles.repaired_jumps{chan_nr,2}{2,2} = [handles.repaired_jumps{chan_nr,2}{2,2}; 0];                            %'Corrected_heights'
handles.repaired_jumps{chan_nr,2}{2,2} = handles.repaired_jumps{chan_nr,2}{2,2}(orig_indices);
handles.repaired_jumps{chan_nr,2}{3,2} = [handles.repaired_jumps{chan_nr,2}{3,2}; 0];                            %'Fixed?'
handles.repaired_jumps{chan_nr,2}{3,2} = handles.repaired_jumps{chan_nr,2}{3,2}(orig_indices);

%go to next jump
handles = updateZvalues(handles);
handles = updateJump(handles);
guidata(hObject, handles);

% --- Executes on button press in buttonReady.
function buttonReady_Callback(hObject, eventdata, handles)
% Ready with this channel - find next highest jump in all channels
handles.stick2Chan = 0;
set(handles.buttonReady,'Enable','off');
set(handles.buttonPreviousJump,'Enable','off');
set(handles.buttonNextJump,'Enable','off');

handles = updateZvalues(handles);
handles = updateJump(handles);
guidata(hObject, handles);

% --- Executes on button press in buttonStop.
function buttonStop_Callback(hObject, eventdata, handles)
% Stop finding Jumps - close the GUI
guidata(hObject, handles);
uiresume(handles.figureInspectJumps);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function handles = updateZvalues(handles)

set(handles.buttonWidthBeforeMore,'Enable','on');
set(handles.buttonWidthBeforeLess,'Enable','on');
set(handles.buttonWidthAfterMore,'Enable','on');
set(handles.buttonWidthAfterLess,'Enable','on');
set(handles.buttonIgnore,'Enable','on');
set(handles.buttonAcceptRepair,'Enable','on');
set(handles.buttonSaveAsArtifact,'Enable','on');

%Find highest z-value in all channels and change the current channel to that one
if handles.stick2Chan == 0
    handles.chan_nr = find(handles.max_z_per_channel == max(handles.max_z_per_channel),1,'first');
    handles.threshold = max(handles.max_z_per_channel)-0.01;
end
set(handles.editTextSetChannel,'String',num2str(handles.chan_nr));
set(handles.editTextSetThreshold,'String',num2str(round(handles.threshold)));
set(handles.uipanelInspectJumps,'Title',[handles.data.label{handles.chan_nr}]);

%Update List_of_Jumps
handles.list_of_jumps = [];
for i=1:handles.nr_of_trials
    raw_samplenrs = [handles.data.sampleinfo(i,1):handles.data.sampleinfo(i,2)]';
    samplenrs = find(handles.z_values{1,i}(handles.chan_nr,:) > handles.threshold);
    if ~isempty(samplenrs)
        pointer = 1;
        start_samples = samplenrs(1);
        end_samples = [];
        while pointer < numel(samplenrs)
            if samplenrs(pointer+1) ~= samplenrs(pointer)+1             %if next samplenr>threshold is not connecting
                end_samples = [end_samples; samplenrs(pointer)];
                start_samples = [start_samples; samplenrs(pointer+1)];
            end
            pointer = pointer+1;
        end
        end_samples = [end_samples; samplenrs(end)];
        handles.list_of_jumps = [handles.list_of_jumps; raw_samplenrs(start_samples) raw_samplenrs(end_samples)];
    end  
end

%Update ZvalueMaxes
zValueMaxes = [];
zValueMaxesRawSamples = [];
for i=1:handles.nr_of_trials
    raw_samplenrs = [handles.data.sampleinfo(i,1):handles.data.sampleinfo(i,2)]';
    nr_of_parts = ceil(size(handles.z_values{1,i},2)/512);
    stepsize = floor(size(handles.z_values{1,i},2)/nr_of_parts);
    pointer = 1;
    if nr_of_parts>1
        for j=1:nr_of_parts-1
            zValueMaxes = [zValueMaxes max(handles.z_values{1,i}(handles.chan_nr,pointer:pointer+stepsize-1))];
            zValueMaxesRawSamples = [zValueMaxesRawSamples; raw_samplenrs(pointer) raw_samplenrs(pointer+stepsize-1)];
            pointer = pointer+stepsize;
        end
    end
    zValueMaxes = [zValueMaxes max(handles.z_values{1,i}(handles.chan_nr,pointer:end))];
    zValueMaxesRawSamples = [zValueMaxesRawSamples; raw_samplenrs(pointer) raw_samplenrs(end)];  
end

%Plot z-values of all channels
axes(handles.axesAllChannels);
bar(1:handles.nr_of_channels,handles.max_z_per_channel);
ylim([0 max(handles.max_z_per_channel)]);
xlim([0 handles.nr_of_channels+1]);
hold on;
plot(handles.chan_nr,max(handles.max_z_per_channel)-0.2*max(handles.max_z_per_channel),'gv','LineWidth',3);
hold off;

%Plot ZvalueMaxes
axes(handles.axesZvalues);
plot(1:numel(zValueMaxes),zValueMaxes);
ylim([0 max(zValueMaxes)]);
xlim([0 numel(zValueMaxes)]);

hold on;
plot([1,numel(zValueMaxes)],[handles.threshold handles.threshold],'r--', 'LineWidth', 2)

%Update jumpPointer
if handles.jumpPointer == 0
    handles.jumpPointer = 1;
end
if handles.jumpPointer > size(handles.list_of_jumps,1)
    if size(handles.list_of_jumps,1) == 0
        handles.jumpPointer = 0;
    else
        handles.jumpPointer = 1;
    end
end
%Find the ZvalueMax position and plot a pointer
if handles.jumpPointer ~= 0
    possible_begin_nrs = find(handles.list_of_jumps(handles.jumpPointer,1) >= zValueMaxesRawSamples(:,1));
    possible_end_nrs = find(handles.list_of_jumps(handles.jumpPointer,1) <= zValueMaxesRawSamples(:,2));
    zValueMaxes_active = intersect(possible_begin_nrs,possible_end_nrs);
    plot(zValueMaxes_active(1),max(zValueMaxes)-0.2*max(zValueMaxes),'gv','LineWidth',3);
end
hold off;

%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%

function handles = updateJump(handles)

if handles.jumpPointer ~= 0     %it's zero if there are no jumps detected
    
    %find the position of the jump in trial_nr and sample_nrs
    raw_sample_begin = handles.list_of_jumps(handles.jumpPointer,1);
    raw_sample_end = handles.list_of_jumps(handles.jumpPointer,2);
    possible_begin_nrs = find(raw_sample_begin >= handles.data.sampleinfo(:,1));
    possible_end_nrs = find(raw_sample_end <= handles.data.sampleinfo(:,2));
    trial_nr = intersect(possible_begin_nrs,possible_end_nrs);
    sample_nrs = handles.list_of_jumps(handles.jumpPointer,1)-handles.data.sampleinfo(trial_nr,1)+1;
    sample_nrs = sample_nrs:(handles.list_of_jumps(handles.jumpPointer,2)-handles.data.sampleinfo(trial_nr,1)+1);
    handles.width_of_jump = numel(sample_nrs);
    set(handles.staticTextWidth,'String',num2str(handles.width_of_jump));

    %Correction Height
    if sample_nrs(1)~=1
        begin_height = handles.data.trial{1,trial_nr}(handles.chan_nr, sample_nrs(1)-1);
    else
        begin_height = 0;
    end
    end_height = handles.data.trial{1,trial_nr}(handles.chan_nr, sample_nrs(end));
    handles.correction_height = end_height-begin_height;
    set(handles.staticTextCorrection,'String',num2str(handles.correction_height));
    
    timeExtra = 512;
    %Create original data for jump
    if sample_nrs(1)-timeExtra < 1
        zeros_pad_begin = zeros(1,abs(sample_nrs(1)-timeExtra)+1);
        sample_nr_begin = 1;
    else
        zeros_pad_begin = [];
        sample_nr_begin = sample_nrs(1)-timeExtra;
    end
    if size(handles.data.trial{1,trial_nr},2) < sample_nrs(end)+timeExtra
        zeros_pad_end = zeros(1,abs(size(handles.data.trial{1,trial_nr},2)-sample_nrs(end)-timeExtra)+1);
        sample_nr_end = size(handles.data.trial{1,trial_nr},2);
    else
        zeros_pad_end = [];
        sample_nr_end = sample_nrs(end)+timeExtra;
    end
    original = [zeros_pad_begin handles.data.trial{1,trial_nr}(handles.chan_nr, sample_nr_begin:sample_nr_end) zeros_pad_end];
    
    %find neighbours of channel
    neighb_chan_nrs = zeros(size(handles.nearest_neighbours(1,handles.chan_nr).neighblabel,1),1);
    for j=1:size(handles.nearest_neighbours(1,handles.chan_nr).neighblabel,1)
        neighb_chan_nrs(j) = strmatch(handles.nearest_neighbours(1,handles.chan_nr).neighblabel{j},handles.data.label, 'exact');
    end
    avg_neighbours_middle = mean(handles.data.trial{1,trial_nr}(neighb_chan_nrs, sample_nr_begin:sample_nr_end),1);
    avg_neighbours = [zeros_pad_begin avg_neighbours_middle zeros_pad_end];
        
    %Create interpolation for jump
    if sample_nrs(1)~=1
        uncorrected_first_part = handles.data.trial{1,trial_nr}(handles.chan_nr, 1:(sample_nrs(1)-1));
        interpolation_start_height = uncorrected_first_part(end);
        beg_neighb = sample_nrs(1)-1;
    else
        uncorrected_first_part = [];
        interpolation_start_height = 0;
        beg_neighb = sample_nrs(1);
    end
    if sample_nrs(end) ~= size(handles.data.trial{1,trial_nr},2)
        corrected_last_part = handles.data.trial{1,trial_nr} ...
                               (handles.chan_nr,(sample_nrs(end)+1):size(handles.data.trial{1,trial_nr},2))-handles.correction_height;
        interpolation_end_height = corrected_last_part(1);
        end_neighb = sample_nrs(end)+1;
    else
        corrected_last_part = [];
        interpolation_end_height = 0;
        end_neighb = sample_nrs(end);
    end        
    lin_interpolation_broad = linspace(interpolation_start_height,interpolation_end_height,handles.width_of_jump+2);
        
    neighb_interpolation = mean(handles.data.trial{1,trial_nr}(neighb_chan_nrs, [beg_neighb sample_nrs end_neighb]),1);
    lin_neighb_interpolation = linspace(neighb_interpolation(1),neighb_interpolation(end),handles.width_of_jump+2);
    neighb_interpolation_corrected = neighb_interpolation - lin_neighb_interpolation;       %begin and end are zero
    
    interpolation_broad = lin_interpolation_broad + neighb_interpolation_corrected;
    interpolation = interpolation_broad(2:end-1);
    
    handles.repaired_full_trial = [uncorrected_first_part interpolation corrected_last_part];
    handles.repaired_full_trial = ft_preproc_detrend(handles.repaired_full_trial);
    
    repaired = [zeros_pad_begin handles.repaired_full_trial(sample_nr_begin:sample_nr_end) zeros_pad_end];

    timeline = ((1:numel(original))-timeExtra-1)./512;
    
    %Plot original and avg of neighbouring channels
    ymin = min(min(original),min(avg_neighbours));
    ymax = max(max(original),max(avg_neighbours));
    zero_pos = find(timeline == min(abs(timeline)),1,'first');
    
    axes(handles.axesOriginal);
    plot(timeline,avg_neighbours, 'm');
    ylim([ymin ymax]);
    xlim([timeline(1) timeline(end)]);
    hold on;
    plot(timeline(zero_pos),ymax-0.05*(ymax-ymin),'gv','LineWidth',3);
    plot(timeline(zero_pos),ymin+0.05*(ymax-ymin),'g^','LineWidth',3);
    plot(timeline,original, 'b');
    plot([timeline(1) timeline(timeExtra)],[begin_height begin_height],'g--');
    plot([timeline(end-timeExtra) timeline(end)],[end_height end_height],'g--'); 
    if handles.width_of_jump>10
        halfheight = 0.25*(ymax-ymin);
        plot([timeline(timeExtra) timeline(timeExtra)],[begin_height-halfheight begin_height+halfheight],'g--','LineWidth',2);
        plot([timeline(end-timeExtra) timeline(end-timeExtra)],[end_height-halfheight end_height+halfheight],'g--','LineWidth',2);
    end  
    hold off;
    
    %Plot repaired with individual neighbouring channels
    ymin = min(repaired);
    ymax = max(repaired);
    
    axes(handles.axesRepaired);  
    for i = 1:numel(neighb_chan_nrs)
        if i==2
            hold on;
        end
        neighbour_middle = handles.data.trial{1,trial_nr}(neighb_chan_nrs(i), sample_nr_begin:sample_nr_end);
        neighbour = [zeros_pad_begin neighbour_middle zeros_pad_end];
        plot(timeline,neighbour, 'm');
        ymin = min(ymin,min(neighbour));
        ymax = max(ymax,max(neighbour));
    end
    if numel(neighb_chan_nrs)==1
        hold on;
    end
    plot(timeline,repaired, 'b','LineWidth',2);
    ylim([ymin ymax]);
    xlim([timeline(1) timeline(end)]);
    hold off;
    
else    %if no jump above threshold was found
    
    set(handles.staticTextWidth,'String','?');
    set(handles.staticTextCorrection,'String','?');
    
    axes(handles.axesOriginal);
    plot(linspace(-2,2,512),linspace(-10,10,512),'w');
    
    axes(handles.axesRepaired);
    plot(linspace(-2,2,512),linspace(-10,10,512),'w');
    
    set(handles.buttonReady,'Enable','on');
    
    set(handles.buttonPreviousJump,'Enable','off');
    set(handles.buttonNextJump,'Enable','off');
    set(handles.buttonWidthBeforeMore,'Enable','off');
    set(handles.buttonWidthBeforeLess,'Enable','off');
    set(handles.buttonWidthAfterMore,'Enable','off');
    set(handles.buttonWidthAfterLess,'Enable','off');
    set(handles.buttonIgnore,'Enable','off');
    set(handles.buttonAcceptRepair,'Enable','off');
    set(handles.buttonSaveAsArtifact,'Enable','off');
    
end

%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%

function handles = updateZValuesAll(handles,chan_nrs,trial_nrs)
%Update z-values of the specified channels and trials    

order = 129;        %Medfilt1 order (window size) (129 samples = 250 ms, with fsample 512 Hz)
                    %Take N odd, then Y(k) is the median of X( k-(N-1)/2 : k+(N-1)/2 ).

%for each channel
for i=1:numel(chan_nrs)

    chan_nr = chan_nrs(i);
    %find neighbours of channel
    neighb_chan_nrs = zeros(size(handles.nearest_neighbours(1,chan_nr).neighblabel,1),1);
    for j=1:size(handles.nearest_neighbours(1,chan_nr).neighblabel,1)
        neighb_chan_nrs(j) = strmatch(handles.nearest_neighbours(1,chan_nr).neighblabel{j},handles.data.label, 'exact');
    end

    %for each trial_nrs
    for j=1:numel(trial_nrs)

        trial_nr = trial_nrs(j);
        %calculate difference with mean of neighbours
        original = handles.data.trial{1,trial_nr}(chan_nr,:);
        avg_neighb = mean(handles.data.trial{1,trial_nr}(neighb_chan_nrs,:),1);
        diff_with_neighb = original - avg_neighb;

        %medfilt including padding at begin and end
        pad_begin = ones(1,(order-1)/2)*median(diff_with_neighb(1:(order-1)/2));
        pad_end = ones(1,(order-1)/2)*median(diff_with_neighb((end-(order-1)/2):end));
        med_filt = medfilt1([pad_begin diff_with_neighb pad_end],order);                

        %abs of first derivative of medfilt result 
        absdiff_temp = [0 abs(med_filt(2:end)-med_filt(1:end-1))];
        handles.absdiff{1,trial_nr}(chan_nr,:) = absdiff_temp(((order-1)/2+1):(end-(order-1)/2));   %excl. padding
    end

    %update z-values of these trials in this channel
    collect_absdiff = zeros(1,handles.total_nr_of_samples);
    pointer=1;
    for j=1:handles.nr_of_trials    
        collect_absdiff(pointer:(pointer+size(handles.absdiff{1,j},2)-1)) = handles.absdiff{1,j}(chan_nr,:);
        pointer = pointer+size(handles.absdiff{1,j},2);
    end
    overall_mean = mean(collect_absdiff);
    overall_std = std(collect_absdiff);            
    for j=1:numel(trial_nrs)
        trial_nr = trial_nrs(j);
        for k=1:size(handles.absdiff{1,trial_nr},2)
            handles.z_values{1,trial_nr}(chan_nr,k) = abs(handles.absdiff{1,trial_nr}(chan_nr,k)-overall_mean)/overall_std;
        end
    end
    
    %Reset z-values of ignored_jumps to 0 if in the same channel and trial
    if ~isempty(handles.ignored_jumps)
        ign_nrs = find(handles.ignored_jumps(:,3) == chan_nr);
        if ~isempty(ign_nrs)
            for j=1:numel(ign_nrs)
                ign_nr = ign_nrs(j);
                possible_begin_nrs = find(handles.ignored_jumps(ign_nr,1) >= handles.data.sampleinfo(:,1));
                possible_end_nrs = find(handles.ignored_jumps(ign_nr,2) <= handles.data.sampleinfo(:,2));
                trial_nr = intersect(possible_begin_nrs,possible_end_nrs);
                if sum(trial_nrs == trial_nr)
                    %find the position of the ignored_jump in trial_nr and sample_nrs
                    begin_sample_nr = handles.ignored_jumps(ign_nr,1)-handles.data.sampleinfo(trial_nr,1)+1;
                    end_sample_nr = handles.ignored_jumps(ign_nr,2)-handles.data.sampleinfo(trial_nr,1)+1;
                    sample_nrs = begin_sample_nr:end_sample_nr;
                    %Set zValues to zero with a maximum of 25 samples around the jump
                    if sample_nrs(1) > 25
                        sample_nrs = (sample_nrs(1)-25):sample_nrs(end);
                    else
                        sample_nrs = [1:(sample_nrs(1)-1) sample_nrs];
                    end
                    if sample_nrs(end)+25 > size(handles.z_values{1,trial_nr},2)
                        sample_nrs = sample_nrs(1):size(handles.z_values{1,trial_nr},2);
                    else
                        sample_nrs = [sample_nrs (sample_nrs(end)+1):(sample_nrs(end)+25)];
                    end
                    handles.z_values{1,trial_nr}(chan_nr, sample_nrs) = 0;
                end
            end
        end            
    end
    
end

%Reset z-values of extremities and artifacts to zero in the specific trials (these values were changed above)
for i=1:numel(trial_nrs)
    trial_nr = trial_nrs(i);

    %Reset z-values at begin and end of the trials to 0 
    handles.z_values{1,trial_nr}(chan_nrs,1) = 0;
    handles.z_values{1,trial_nr}(chan_nrs,end) = 0;
    
    %Reset z-values of artifacts to 0
    beg_trial = handles.data.sampleinfo(trial_nr,1);
    end_trial = handles.data.sampleinfo(trial_nr,2);
    if ~isempty(handles.artifacts) 
        art_nrs = find(handles.artifacts(:,1) >= beg_trial & handles.artifacts(:,2) <= end_trial);
        if ~isempty(art_nrs)
            for j=1:numel(art_nrs)
                %find the position of the artifact in trial_nr and sample_nrs
                begin_sample_nr = handles.artifacts(art_nrs(j),1)-beg_trial+1;
                end_sample_nr = handles.artifacts(art_nrs(j),2)-beg_trial+1;
                sample_nrs = begin_sample_nr:end_sample_nr;
                %Set zValues to zero with a maximum of 25 samples around the artifact in all channels
                if sample_nrs(1) > 25
                    sample_nrs = (sample_nrs(1)-25):sample_nrs(end);
                else
                    sample_nrs = [1:(sample_nrs(1)-1) sample_nrs];
                end
                if sample_nrs(end)+25 > size(handles.z_values{1,trial_nr},2)
                    sample_nrs = sample_nrs(1):size(handles.z_values{1,trial_nr},2);
                else
                    sample_nrs = [sample_nrs (sample_nrs(end)+1):(sample_nrs(end)+25)];
                end
                handles.z_values{1,trial_nr}(chan_nrs, sample_nrs) = 0;
            end
        end
    end
end

%Update maximum z-values per channel and record in which trials they are found
for i=1:numel(chan_nrs)    
    chan_nr = chan_nrs(i); 
    if sum(trial_nrs == handles.max_z_trialnr_per_channel(chan_nr))     %if something changed in the trial that contained maximum z-value
        %find new maximum of channel
        for j=1:handles.nr_of_trials
            max_in_trial = max(handles.z_values{1,j}(chan_nr,:));
            if max_in_trial > handles.max_z_per_channel(chan_nr)
                handles.max_z_per_channel(chan_nr) = max_in_trial;
                handles.max_z_trialnr_per_channel(chan_nr) = j;
            end
        end
    end
end

