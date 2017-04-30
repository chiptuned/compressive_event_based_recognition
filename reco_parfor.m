clearvars;
close all force;

addpath('functions')
%addpath('/home/vincent/idv/generichots/matlab')
addpath('../libsvm/matlab')

%% Variables initialization
path_timit = '/home/vincent/idv/Cochlea/timit/timit/';

aff = 1;
create_events = 1;
mode_event_generation = 'spikegram_jittered';
nb_levels_crossing = 50;
ratio_hots_learning_of_train_timit = 0.33;
ratio_classif_learning_of_train_timit = 0.67;
ratio_classif_test_of_test_timit = 1;

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

curr_data_folder = 'hots_data';
path_data = fullfile(pwd, curr_data_folder);
params.path_data = path_data;
params.nbLayers = 1;
params.nbCenters = [8, 32, 128, 32, 256];
params.tau = [10000., 50000., 250000., 640000., 256000.];
params.radius = [5, 10, 15, 25, 35];
params.nbDim = 1;
params.nbChannels = nb_levels_crossing;

% train model
compute_generic_hots(params, events_train_hots, events_train, events_test);
[centers, events, events2] = read_generichots_output(params);

for layer = 1:
for type_classes_label = [2,1,3,0]

    [label_train, classes_phon_1] = change_class_labels(label_train_phon, type_classes_label);
    [label_test] = change_class_labels(label_test_phon, type_classes_label);

    all_sigs_train = compute_all_signatures1D_from_events(events{params.nbLayers+1}, label_train, ...
      params.nbCenters(params.nbLayers));

    all_sigs_test = compute_all_signatures1D_from_events(events2{params.nbLayers+1}, label_test, ...
      params.nbCenters(params.nbLayers));

    max_k = 50;
    reco_rate_metasigs = compute_reco_using_metasigs(all_sigs_train, all_sigs_test);
    reco_rate_euclidean = compute_reco_using_kppv(all_sigs_train, all_sigs_test, max_k, 'euclidean');
    reco_rate_bhattacharrya = compute_reco_using_kppv(all_sigs_train, all_sigs_test, max_k, 'bhattacharrya');

    [max_reco_rate_euclidean, k_max_reco_rate_euclidean] = max(reco_rate_euclidean);
    [max_reco_rate_bhattacharrya, k_max_reco_rate_bhattacharrya] = max(reco_rate_bhattacharrya);
    reco_rate_mlp = compute_reco_using_mlp(all_sigs_train, all_sigs_test);
    reco_rate_svm = compute_reco_using_svm(all_sigs_train, all_sigs_test);

    switch type_classes_label
        case 0
            type = 'TIMIT phonemas, 61 classes';
        case 1
            type = 'Reynolds & Antoniou (2003), 7 classes';
        case 2
            type = 'Halberstadt (1998), 3 classes';
        case 3
            type = 'Lee & Hon (1989), 36 classes';
        otherwise
        error('wtf type_classes_label');
    end

    fprintf('-> Type %s :\n', type);
    fprintf('Recognition rate with meta signatures : %d%%\n', floor(reco_rate_metasigs*100));
    fprintf('Recognition rate with kppv (euclidean) : %d%% with k=%d\n', ...
        floor(max_reco_rate_euclidean*100), k_max_reco_rate_euclidean);
    fprintf('Recognition rate with kppv (bhattacharrya) : %d%% with k=%d\n', ...
        floor(max_reco_rate_bhattacharrya*100), k_max_reco_rate_bhattacharrya);
    fprintf(['Recognition rate with MLP (trainscg, crossentropy, '...
        '[100,1000] neurons in hidden layers : %d%%\n'], floor(reco_rate_mlp*100));
    fprintf(['Recognition rate with SVM (C-SVC, default parameters, no shrinking): %d%%\n\n'], floor(reco_rate_svm*100));
end
