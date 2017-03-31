clear all;
close all;

% Need some functions :
% Write and load data (addr and audio)
% Write centers
addpath('../../functions') 

if isunix
    path_data = '/home/vincent/idv/matlab_hots/hots_data';
    if exist(path_data, 'dir') == 0
        mkdir(path_data);
    end
else
    error('No hardcoded path specified for non-unix (filename_events)');
end

file_ev = fullfile(path_data, 'events_input.dat');
% Specify the event format
events = load_audio_data(file_ev);

% Make the parameters struct
h = fopen(fullfile(path_data,'params.hots'), 'rb');
nbL = fread(h, 1, 'int32');
nbLayers = nbL;
nbCenters = fread(h, nbL, 'int32');
tau = fread(h, nbL, 'int32');
radius = fread(h, nbL, 'int32');
ksi = fread(h, nbL, 'float32');
nPow = fread(h, 1, 'int32');
nbDim = fread(h, 1, 'int32');
nbChannels = fread(h, nbDim, 'int32');
typeCenters = fread(h, 1, 'int32');
nbPols = fread(h, 1, 'int32');
fclose(h);

fprintf('Dataset contains %d events.\n', numel(events.ts));

for layer = 1:nbLayers
    fprintf('\nLayer %d\n', layer)
    
    %% HoTS
    %params_layer.nbDim = nbDim; %useless, because nbChannels carries this info
    params_layer.nbChannels = nbChannels;
    params_layer.nPow = nPow;

    if layer == 1
        params_layer.nbPols = nbPols;
    else
        params_layer.nbPols = nbCenters(layer-1);
    end

    params_layer.tau = tau(layer);
    params_layer.ksi = ksi(layer);
    params_layer.nbCenters = nbCenters(layer);
    params_layer.radius = radius(layer);
    params_layer.nPow = nPow;
    %params_layer.max_loops = 10;
    %params_layer.seed = randi(1,1000);
    %params_layer.hotsogram = true;

    params_layer.learning = true;
    if layer == 1
        [~, new_centers] = compute_hots_layer(events, [], params_layer);
        params_layer.learning = false;
        [new_events, ~] = compute_hots_layer(events, new_centers, params_layer);
    else
        [~, new_centers] = compute_hots_layer(new_events, [], params_layer);
        params_layer.learning = false;
        [new_events, ~] = compute_hots_layer(new_events, new_centers, params_layer);
    end
    
    str_file_ev = ['events_out_of_layer_', num2str(layer), '.dat'];
    str_file_centers = ['centers_of_layer_', num2str(layer), '.bin'];
    write_audio_data(new_events, fullfile(path_data, str_file_ev));
    %write_centers(centers, fullfile(path_data, str_file_ev));

    events = new_events;

end