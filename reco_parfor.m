clearvars;
close all force;

addpath('functions')
%addpath('/home/vincent/idv/generichots/matlab')
addpath('../libsvm/matlab')

%% Variables initialization
path_timit = '/home/vincent/idv/Cochlea/timit/timit/';

aff = 1;
create_events = 0;
mode_event_generation = 'spikegram_jittered';
nb_levels_crossing = 50;
ratio_hots_learning_of_train_timit = 0.33;
ratio_classif_learning_of_train_timit = 0.67;
ratio_classif_test_of_test_timit = 1;

if create_events
  ratios = [ratio_hots_learning_of_train_timit, ratio_classif_learning_of_train_timit, ...
    ratio_classif_test_of_test_timit];
  create_events_from_timit_database(path_timit, ratios, nb_levels_crossing, mode_event_generation)
  fprintf('Database created.\n');
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

nLayers_parfor = 3;
centers_parfor = [2,3,4,5,6,7,8,9,10];
taus_parfor = [500, 1000, 2000, 4000, 8000];
radius_parfor = [3,4,5,6,7,8,9,10];

all_results = cell(numel(centers_parfor)*numel(taus_parfor)*numel(radius_parfor), 2);

for ind1 = 1:numel(centers_parfor)
  for ind2 = 1:numel(taus_parfor)
    for ind3 = 1:numel(radius_parfor)
      idx_settings = ind3+((ind2-1)+(ind1-1)*numel(taus_parfor))*numel(radius_parfor);
      curr_data_folder = ['hots_data_', num2str(idx_settings)];
      path_data = fullfile(pwd, curr_data_folder);
      params.path_data = path_data;
      params.viewer = 0;
      params.viewer_port = 3333+idx_settings;
      params.viewer_refresh_seconds = 6;
      params.nbLayers = nLayers_parfor;
      params.nbCenters = centers_parfor(ind1).*2.^(0:4);
      params.tau = taus_parfor(ind2).*2.^(0:4);
      params.radius = radius_parfor(ind3).*2.^(0:4);
      params.nbDim = 1;
      params.nbChannels = nb_levels_crossing;
      params.nbPols = numel(unique(events_train_hots.p));
      all_results(idx_settings,1) = {params};
    end
  end
end
classes_label = [2,1,3,0];

N_workers = 72;
myCluster=parcluster('local');
myCluster.NumWorkers=N_workers;
parpool(myCluster,N_workers)

parfor idx_settings = 1:size(all_results,1)
  % train model
  compute_generic_hots(all_results{idx_settings,1}, events_train_hots, events_train, events_test);
  [centers, events, events2] = read_generichots_output(all_results{idx_settings,1});

  % pour chaque layer, et chasses type de classes (nb de classes croissant)
  % on a les 5 tests de reconnaissance
  reco_rates = zeros(all_results{idx_settings,1}.nbLayers, numel(classes_label), 5);

  for layer = 1:all_results{idx_settings,1}.nbLayers
    for idx_classes_label = 1:numel(classes_label)

        type_classes_label = classes_label(idx_classes_label);
        [label_train, classes_phon_1] = change_class_labels(label_train_phon, type_classes_label);
        [label_test] = change_class_labels(label_test_phon, type_classes_label);

        all_sigs_train = compute_all_signatures1D_from_events(events{layer+1}, label_train, ...
          all_results{idx_settings,1}.nbCenters(layer));

        all_sigs_test = compute_all_signatures1D_from_events(events2{layer+1}, label_test, ...
          all_results{idx_settings,1}.nbCenters(layer));

        max_k = 50;
        reco_rates(layer,idx_classes_label, 1) = compute_reco_using_metasigs(all_sigs_train, all_sigs_test);
        reco_rate_euclidean = compute_reco_using_kppv(all_sigs_train, all_sigs_test, max_k, 'euclidean');
        reco_rate_bhattacharrya = compute_reco_using_kppv(all_sigs_train, all_sigs_test, max_k, 'bhattacharrya');

        reco_rates(layer,idx_classes_label, 2) = max(reco_rate_euclidean);
        reco_rates(layer,idx_classes_label, 3) = max(reco_rate_bhattacharrya);
        reco_rates(layer,idx_classes_label, 4) = compute_reco_using_mlp(all_sigs_train, all_sigs_test);
        reco_rates(layer,idx_classes_label, 5) = compute_reco_using_svm(all_sigs_train, all_sigs_test);
    end
  end
  results(2,idx_settings) = {reco_rates};
end

save('results.mat', 'results');