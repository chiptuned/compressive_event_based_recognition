function [events, centers, params] = read_data(old_params)

% Place the event file at the right place
if isunix
    path_data = '/home/vincent/idv/matlab_hots/hots_data';
    if exist(path_data, 'dir') == 0
        mkdir(path_data);
    end
else
    error('No hardcoded path specified for non-unix (filename_events)');
end

file_ev = fullfile(path_data, 'events_input.dat');
events = load_audio_data(file_ev);

% Make the parameters struct
h = fopen(fullfile(path_data,'params.hots'), 'rb');
nbL = fread(h, 1, 'int32');
params.nbLayers = nbL;
params.nbCenters = fread(h, nbL, 'int32');
params.tau = fread(h, nbL, 'int32');
params.radius = fread(h, nbL, 'int32');
params.ksi = fread(h, nbL, 'float32');
params.nPow = fread(h, 1, 'int32');
nbDim = fread(h, 1, 'int32');
params.nbDim = nbDim;
params.nbChannels = fread(h, nbDim, 'int32');
params.typeCenters = fread(h, 1, 'int32');
params.nbPols = fread(h, 1, 'int32');
fclose(h);

if ~isequal(params, old_params)
    warning('Input parameters and hots data parameters are different')
end

% Read events and centers
eventslayer0 = events;
events = cell(1,nbL+1);
events(1) = {eventslayer0};
centers = cell(1,nbL);
for ind = 1:nbL
    str_file_ev = ['events_out_of_layer_', num2str(ind), '.dat'];
    str_file_centers = ['centers_of_layer_', num2str(ind), '.bin'];
    events(ind+1) = {load_audio_data(fullfile(path_data, str_file_ev))};
    % FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME FIXME
    %centers(ind) = {load_centers(fullfile(path_data, str_file_centers))};
end