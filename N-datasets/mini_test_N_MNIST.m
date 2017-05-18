clearvars -except train test;
close all force;

addpath('../functions');

path_data = 'nmnist_data';
rng(0) % for reproducibility

if (~exist('train', 'var') || ~exist('test', 'var'))
  if ~exist(fullfile(path_data, 'all_events.mat'), 'file')
    get_events_from_N_MNIST;
  end
  load(fullfile(path_data, 'all_events.mat'))
  idx_tr = randperm(size(all_events_train,1)); % todel
  idx_test = randperm(size(all_events_test,1)); % todel
  train = all_events_train(idx_tr(1:100),:); % todel
  test = all_events_test(idx_test(1:100),:); % todel
  % add : train = all_events_train;
  % add : test = all_events_test;

  clear all_events_train all_events_test idx_tr idx_test
end

ratio = 20/100; % of events in train are to train hots
[events, labels, idx_pres] = prepare_dataset_dat(train, test, path_data, ratio);

nb_channels = [35,35];
params.path_data = path_data;
params.nbLayers = 3;
params.nbCenters = [8, 16, 32, 32, 256];
params.tau = [10000., 50000., 250000., 640000., 256000.];
params.radius = [4, 8, 16, 32, 32];
params.nbDim = 2;
params.nbChannels = nb_channels;
%events{1}.p = zeros(size(events{1}.p))
params.nbPols = numel(unique(events{1}.p));

[centers, out_events] = compute_matlab_hots_new(params, events);
