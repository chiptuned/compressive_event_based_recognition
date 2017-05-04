clearvars;
close all force;

addpath('functions')
%addpath('/home/vincent/idv/generichots/matlab')
addpath('../libsvm/matlab')

%% Variables initialization
path_timit = '/home/vincent/idv/Cochlea/timit/timit/';
curr_data_folder = 'multi_hots_data';
path_data = fullfile(pwd, curr_data_folder);

aff = 1;
create_events = 0;
mode_event_generation = 'spikegram_jittered';
launch_hots = 1;
nb_levels_crossing = 50;
ratio_hots_learning_of_train_timit = 0.33;
ratio_classif_learning_of_train_timit = 0.67;
ratio_classif_test_of_test_timit = 1;

params.path_data = path_data;
params.nbLayers = 1;
params.nbCenters = [8, 32, 128, 32, 256];
params.tau = [10000., 50000., 250000., 640000., 256000.];
params.radius = [5, 10, 15, 25, 35];
params.ksi = [2e-5, 4e-4, 4e-4, 4e-4, 4e-4];
params.nPow = 3;
params.nbDim = 1;
params.nbChannels = nb_levels_crossing;
params.typeCenters = 2;

if create_events
  ratios = [ratio_hots_learning_of_train_timit, ratio_classif_learning_of_train_timit, ...
    ratio_classif_test_of_test_timit];
  create_events_from_timit_database(path_timit, ratios, nb_levels_crossing, mode_event_generation)
end

file_ev_train_hots = [path_timit, 'train_hots.dat'];
file_ev_train = [path_timit, 'train_classif.dat'];
file_label_train =  [path_timit, 'train_classif.label'];
file_ev_test = [path_timit, 'test_classif.dat'];
file_label_test =  [path_timit, 'test_classif.label'];

[events_train_hots] = load_audio_data(file_ev_train_hots);
[events_train] = load_audio_data(file_ev_train);
[events_test] = load_audio_data(file_ev_test);
[label_train_phon] = load_labels(file_label_train);
[label_test_phon] = load_labels(file_label_test);

% Critique : verifier l'output dans la fonction (notamment si toutes les
% classes apparaissent au moins une fois
type_classes_label = 0;
[label_train, classes_phon_1] = change_class_labels(label_train_phon, type_classes_label);
[label_test] = change_class_labels(label_test_phon, type_classes_label);

events_train_hots.p = zeros(size(events_train_hots.p));
events_train.p = zeros(size(events_train.p));
events_test.p = zeros(size(events_test.p));
params.nbPols = numel(unique(events_train_hots.p));

[centers, events] = compute_matlab_hots(params, events_train_hots, events_train, events_test);
