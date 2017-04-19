clearvars;
close all force;

addpath('functions')
%addpath('/home/vincent/idv/generichots/matlab')
addpath('../libsvm/matlab')

%% Variables initialization
path_timit = '/home/vincent/idv/Cochlea/timit/timit/';
curr_data_folder = 'hots_data_apr3';
path_data = fullfile(pwd, curr_data_folder);

aff = 1;
create_events = 0;
launch_hots = 1;
nb_levels_crossing = 50;
ratio_hots_learning_of_train_timit = 0.01;
ratio_classif_learning_of_train_timit = 0.03;
ratio_classif_test_of_test_timit = 0.15;

params.path_data = path_data;
params.nbLayers = 3;
params.nbCenters = [16, 32, 64, 128, 256];
params.tau = [1000., 4000., 16000., 64000., 256000.];
params.radius = [5, 15, 25, 35, 45];
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

if launch_hots
    compute_generic_hots(params, events_train_hots, events_train, events_test);
end
[centers, events, events2] = read_generichots_output(params);
% [centers, events] = compute_matlab_hots(params, events_train_hots, events_train, events_test);
% ceil(100*density_centers(centers))

%% Affichages
if aff
  occs = cell(1,params.nbLayers);

  nb_plots = numel(events);
  if nb_plots > 4
    nb_plots_x = 2;
    nb_plots_y = ceil(nb_plots/2);
  else
    nb_plots_x = 1;
    nb_plots_y = nb_plots;
  end

  handle_subp = [];
  figure;
  for ind = 1:nb_plots
    handle_subp(ind) = subplot(nb_plots_y,nb_plots_x,ind);
    plot_events(events{ind});
    if ind == 1
      title('input');
    else
      title(['output of layer ', num2str(ind)-1]);
    end
  end
  linkaxes(handle_subp);
  axis([5.15e7 5.45e7 0 49])
  pause

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
    plot_events_labelcolor(events{ind+1}, label_train, classes_phon_1)

    sbp3 = subplot(313);
    events_zero.ts = 0:500:label_train{2}(end);
    events_zero.level = floor(nb_levels_crossing/2)*ones(size(events_zero.ts));
    events_zero.channel = events_zero.level;
    events_zero.p = events_zero.level;
    plot_events_labelcolor(events_zero, label_train, classes_phon_1)
    linkaxes([sbp1, sbp2, sbp3]);
    axis([5.15e7 5.45e7 0 49])
  end
end

disp('phase 1 terminee')
pause

%% Reco
for type_classes_label = [2,1,3,0]

    [label_train, classes_phon_1] = change_class_labels(label_train_phon, type_classes_label);
    [label_test] = change_class_labels(label_test_phon, type_classes_label);

    all_sigs_train = compute_all_signatures1D_from_events(events{params.nbLayers+1}, label_train, ...
      params.nbCenters(params.nbLayers));

    all_sigs_test = compute_all_signatures1D_from_events(events2{params.nbLayers+1}, label_test, ...
      params.nbCenters(params.nbLayers));

    % labels = all_sigs_train(:,1);
    % features = all_sigs_train(:,3:end).*repmat(all_sigs_train(:,2),1,size(all_sigs_train,2)-2);
    % save('test_features_non_norm_mar24_16h40.mat','labels','features');

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

% if aff
%   % draw_all_signatures(all_sigs_train);
%   figure;
%   plot(reco_rate, '*')
%   axis([1 numel(reco_rate) 0 1])
%   xlabel('k')
%   ylabel('recognition rate')
%   title('recognition rate of sigs using kppv');
% end

% -> Type Halberstadt (1998), 3 classes :
% Recognition rate with meta signatures : 61%
% Recognition rate with kppv (euclidean) : 67% with k=48
% Recognition rate with kppv (bhattacharrya) : 62% with k=22
% Recognition rate with MLP (trainscg, crossentropy, [100,1000] neurons in hidden layers : 68%
% Recognition rate with SVM (C-SVC, default parameters, no shrinking): 61%
%
% -> Type Reynolds & Antoniou (2003), 7 classes :
% Recognition rate with meta signatures : 25%
% Recognition rate with kppv (euclidean) : 37% with k=47
% Recognition rate with kppv (bhattacharrya) : 29% with k=16
% Recognition rate with MLP (trainscg, crossentropy, [100,1000] neurons in hidden layers : 42%
% Recognition rate with SVM (C-SVC, default parameters, no shrinking): 33%
%
% -> Type Lee & Hon (1989), 36 classes :
% Recognition rate with meta signatures : 2%
% Recognition rate with kppv (euclidean) : 19% with k=4
% Recognition rate with kppv (bhattacharrya) : 17% with k=12
% Recognition rate with MLP (trainscg, crossentropy, [100,1000] neurons in hidden layers : 31%
% Recognition rate with SVM (C-SVC, default parameters, no shrinking): 21%
%
% -> Type TIMIT phonemas, 61 classes :
% Recognition rate with meta signatures : 1%
% Recognition rate with kppv (euclidean) : 3% with k=49
% Recognition rate with kppv (bhattacharrya) : 5% with k=5
% Recognition rate with MLP (trainscg, crossentropy, [100,1000] neurons in hidden layers : 18%
% Recognition rate with SVM (C-SVC, default parameters, no shrinking): 0%
