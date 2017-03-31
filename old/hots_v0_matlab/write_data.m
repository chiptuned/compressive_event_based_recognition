function prepare_hots_data(events, params)

% Place the event file at the right place
if isunix
    path_data = '/home/vincent/idv/matlab_hots/hots_data';
    if exist(path_data, 'dir') == 0
        mkdir(path_data);
    end
    file_ev = fullfile(path_data, 'events_input.dat');
else
    error('No hardcoded path specified for non-unix (filename_events)');
end

write_audio_data(events, file_ev);

% Check if params is correct
nbL = params.nbLayers;
nbCenters = params.nbCenters;
tau = params.tau;
radius = params.radius;
ksi = params.ksi;
nbDim = params.nbDim;
nbChannels = params.nbChannels;

if numel(nbCenters) < nbL
  warning(['Vector nbCenters should contain ', num2str(nbL), ' elements. New vector :']);
  nbCenters = nbCenters(1)*[1, 2, 4];
elseif numel(tau) < nbL
  warning(['Vector tau should contain ', num2str(nbL), ' elements. New vector :']);
  tau = tau(1)*[1,2,4];
elseif numel(radius) < nbL
  warning(['Vector radius should contain ', num2str(nbL), ' elements. New vector :']);
  radius = radius(1)*[1,2,4];
elseif numel(ksi) < nbL
  warning(['Vector ksi should contain ', num2str(nbL), ' elements. New vector :']);
  ksi = ksi(1)*[1,1,1];
elseif numel(nbChannels) ~= nbDim
  error(['Vector nbChannels must contain ', num2str(nbDim), ' elements.']);
end

% Make the parameters file
h = fopen(fullfile(path_data,'params.hots'), 'wb');
fwrite(h, nbL, 'int32');
fwrite(h, nbCenters(1:nbL), 'int32');
fwrite(h, tau(1:nbL), 'float32');
fwrite(h, radius(1:nbL), 'int32');
fwrite(h, ksi(1:nbL), 'float32');
fwrite(h, params.nPow, 'int32');
fwrite(h, nbDim, 'int32');
fwrite(h, nbChannels, 'int32');
fwrite(h, params.typeCenters, 'int32');
fwrite(h, params.nbPols, 'int32');
fclose(h);
end