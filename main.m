clearvars;
close all force;

addpath('functions')

%% Variables initialization
path_timit = '/home/vincent/idv/Cochlea/timit/timit/';
curr_data_folder = 'hots_data';
path_data = fullfile(pwd, curr_data_folder);
if exist(path_data, 'dir')
  rmdir(path_data, 's');
end

aff = 1;
create_events = 0;
nb_levels_crossing = 50;
ratio_hots_learning_of_train_timit = 0.01;
ratio_classif_learning_of_train_timit = 0.03;
ratio_classif_test_of_test_timit = 0.15;

params.nbLayers = 5;
params.nbCenters = [4, 8, 16, 32, 64];
params.tau = [500., 2500., 12500., 75000., 375000.];
params.radius = [2, 4, 8, 16, 32];
params.ksi = [2e-5, 4e-4, 4e-4, 4e-4, 4e-4];
params.nPow = 3;
params.nbDim = 1;
params.nbChannels = nb_levels_crossing;
params.typeCenters = 2;

if create_events
  ratios = [ratio_hots_learning_of_train_timit, ratio_classif_learning_of_train_timit, ...
    ratio_classif_test_of_test_timit];
  create_events_from_timit_database(path_timit, ratios, nb_levels_crossing)
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

[centers, events, events2] = generic_hots(path_data, params, events_train_hots, ...
  events_train, events_test, label_train, label_test);

all_sigs_train = compute_all_signatures1D_from_events(events{params.nbLayers+1}, label_train, ...
  params.nbCenters(params.nbLayers));

all_sigs_test = compute_all_signatures1D_from_events(events2{params.nbLayers+1}, label_test, ...
  params.nbCenters(params.nbLayers));

% labels = all_sigs_train(:,1);
% features = all_sigs_train(:,3:end).*repmat(all_sigs_train(:,2),1,size(all_sigs_train,2)-2);
% save('test_features_non_norm_mar24_16h40.mat','labels','features');

max_k = 50;
reco_rate = zeros(1,max_k);
for ind = 1:max_k
  reco_rate(ind) = compute_reco_using_kppv(all_sigs_train, all_sigs_test, ind, 'euclidean');
end
max(reco_rate)
%reco_rate_mlp = compute_reco_using_mlp(all_sigs_train, all_sigs_test)

if aff
  occs = cell(1,params.nbLayers);
  for ind = 1:params.nbLayers
    occs(ind) = {occurancies_centers(centers{ind}, events{ind+1})};
    plot_centers(centers{ind}, occs{ind}, 8);
%       plot_centers_temporal(centers{ind}, occs{ind}, params.tau(ind), 4);
%       figure;
%       plot_events(events{ind+1});

    figure;
    sbp1 = subplot(311);
    plot_events(events{ind+1});

    sbp2 = subplot(312);
    plot_events_labelcolor(events{ind+1}, label_train)

    sbp3 = subplot(313);
    events_zero.ts = 0:500:label_train{2}(end);
    events_zero.level = floor(nb_levels_crossing/2)*ones(size(events_zero.ts));
    events_zero.channel = events_zero.level;
    events_zero.p = events_zero.level;
    plot_events_labelcolor(events_zero, label_train, classes_phon_1)
    linkaxes([sbp1, sbp2, sbp3]);
    axis([5.15e7 5.45e7 0 49])
  end
  % draw_all_signatures(all_sigs_train);
  figure;
  plot(reco_rate, '*')
  axis([1 numel(reco_rate) 0 1])
  xlabel('k')
  ylabel('recognition rate')
  title('recognition rate of sigs using kppv');
end
