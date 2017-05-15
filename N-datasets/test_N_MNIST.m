clearvars -except events_train_hots events_train events_test label_train label_test
close all force;

addpath('../functions');

create_events = 1;
ratio = 0.3;
nb_channels = [35,35];
launch_hots = 1;
path_data = 'nmnist_data';
store_data = 0;

if (create_events || ~exist(fullfile(path_data, 'events_train_hots.dat'), 'file'))
  if ~exist(fullfile(path_data, 'all_events.mat'), 'file')
    get_events_from_N_MNIST;
  end
  [events_train_hots, events_train, events_test, label_train, label_test] = ...
    prepare_N_MNIST_dataset(ratio);
end

params.path_data = path_data;
params.nbLayers = 1;
params.nbCenters = [8, 32, 128, 32, 256];
params.tau = [10000., 50000., 250000., 640000., 256000.];
params.radius = [4, 8, 16, 32, 32];
params.nbDim = 2;
params.nbChannels = nb_channels;
params.nbPols = numel(unique(events_train_hots.p));
params.viewer = 1;
params.viewer_port = 3444;
params.viewer_refresh_seconds = 6;

if launch_hots
  compute_generic_hots(params, events_train_hots, events_train, events_test);
end
centers = cell(1,params.nbLayers);
events1_outofLayers = cell(1,params.nbLayers);
events2_outofLayers = cell(1,params.nbLayers);

if store_data
  for ind = 1:params.nbLayers
    centers_file = fullfile(params.path_data, ['centersOfLayer', num2str(ind), '.txt']);
    events1_file = fullfile(params.path_data, ['events_train_classif_outputOfLayer', num2str(ind), '.dat']);
    events2_file = fullfile(params.path_data, ['events_test_classif_outputOfLayer', num2str(ind), '.dat']);
    centers(ind) = {read_centers2D(centers_file, params)};
    events1_outofLayers(ind) = {load_event2D_64bit_ts(events1_file)};
    events2_outofLayers(ind) = {load_event2D_64bit_ts(events1_file)};
  end
end
