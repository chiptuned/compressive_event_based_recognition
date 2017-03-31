clearvars;
close all force;

addpath('functions')
addpath('hots_v0_matlab')

%% Variables initialization
if ispc
    %path_timit = 'C:\Users\je_pa\Documents\Scolaire\Master\Divers\timit\';
    path_timit = 'D:\Users\Vincent\Documents\Scolaire\Master\Divers\timit\';
elseif isunix
    path_timit = '/home/vincent/idv/Cochlea/timit/timit/';
end

% 1  'Make with one train/test file'
% 2  'Make train dat/labels with sx files'
% 3  'Make dat/label files for each sentence'
% 4  'Make train/test dat/labels with all corpus'
% 5  'Make train/test dat/labels with n=5 individuals'
% 6  'Remove all dat and label individual files (expect train/test)'
% 7  'Make train dat/labels with everything but sa with N individuals'

%axis_events = [1.0414e6, 1.0430e6, 0, nb_levels_crossing];

% hots
% dt = datestr(now,'mmmdd-HH');
% curr_data_folder = ['hots_data_', dt, 'h', datestr(now,'MM')]; % le faire
% dans le c++ de hots
curr_data_folder = 'hots_data';
path_data = fullfile(pwd, curr_data_folder);

if ~exist(path_data, 'dir')
  mkdir(path_data)
end

aff = 0;
choice_timit = 7;
nb_levels_crossing = 50;

params.nbLayers = 2;
params.nbCenters = [4, 9, 30, 512, 128];
params.tau = [150., 600., 2000., 10000., 8000.];
params.radius = [3, 5, 8, 11, 128];
params.ksi = [2e-5, 4e-4, 4e-4, 4e-4, 4e-4];
params.nPow = 3;
params.nbDim = 1;
params.nbChannels = nb_levels_crossing;
params.typeCenters = 2;

% params.seed = randi(1000,1)


%% Generate event files
% create_events_corpus(path_timit, choice_timit , nb_levels_crossing);
% [truth_timit] = make_database(path_timit);

%% Read files
file_ev_train = [path_timit, 'train.dat'];
file_label_train =  [path_timit, 'train.label'];
file_ev_test = [path_timit, 'test.dat'];
file_label_test =  [path_timit, 'test.label'];
[events_test] = load_audio_data(file_ev_test);
[label_test] = load_labels(file_label_test);
[events_train] = load_audio_data(file_ev_train);
[label_train] = load_labels(file_label_train);

%events_train.p = zeros(size(events_train.p));
params.nbPols = numel(unique(events_train.p));

[centers, events_sig, events] = generic_hots(path_data, params, ...
    events_train, events_test, ...
    label_train, label_test);

if aff
    occs = cell(1,params.nbLayers);
    for ind = 1:params.nbLayers
        occs(ind) = {occurancies_centers(centers{ind}, events{ind+1})};
        plot_centers(centers{ind}, occs{ind}, 4);
        plot_centers_temporal(centers{ind}, occs{ind}, params.tau(ind), 4);
        figure;
        plot_events(events{ind+1});
        drawnow;
    end
end

if aff
    figure;
    sbp1 = subplot(311);
    plot_events(events{end});

    sbp2 = subplot(312);
    plot_events_labelcolor(events{end}, label_train)

    sbp3 = subplot(313);
    events_zero.ts = 0:1000:label_train{2}(end);
    events_zero.level = floor(nb_levels_crossing/2)*ones(size(events_zero.ts));
    events_zero.channel = events_zero.level;
    events_zero.p = events_zero.level;
    plot_events_labelcolor(events_zero, label_train)
    linkaxes([sbp1, sbp2, sbp3]);
end

occ_sig = occurancies_centers(centers{params.nbLayers}, events_sig);

if aff
    figure;
    subplot(211)
    bar(occs{params.nbLayers})
    title('reponse a train, par centre, en nb d''event')
    subplot(212)
    bar(occ_sig)
    title('reponse a test, par centre, en nb d''event')
    figure;
    plot_events(events_sig);
end

pause

nbCenters = params.nbCenters(params.nbLayers);
label_sig = simplify_labels(label_test, 3);
features = zeros(nbCenters+1,numel(label_sig{1}));
% Faire une fonction un peu moins matlab de ca
for ind2 = 1:numel(label_sig{1})
  idx_ev = find((events_sig.ts >= label_sig{1}(ind2)) .* (events_sig.ts < label_sig{2}(ind2)));
  for ind3 = 1:nbCenters
    features(ind3,ind2) = numel(find(events_sig.p(idx_ev) == (ind3-1)));
  end
end
features(end,:) = label_sig{3};

features_test = features(1:end-1,:);
nonnull_feats = find(sum(features_test)~=0);
features_test = features(1:end-1,nonnull_feats);
features_test = features_test ./ repmat(sum(features_test),size(features_test,1),1);
labels_test_feat = features(end,nonnull_feats);
output_test_feat = zeros(numel(unique(labels_test_feat)), size(labels_test_feat,2));
for ind = 1:numel(unique(labels_test_feat))
  output_test_feat(ind,:) = labels_test_feat == ind;
end



% filename_sigs = fullfile(path_data, ['signaturesOfLayer', num2str(params.nbLayers),'.txt']);
% [sigs] = read_signatures(filename_sigs);

% cpt = 0;
% cpt_subp = 0;
% figure;
% phonemas = unique(label_train{3});
% for ind = 1:numel(phonemas)
%     cpt = cpt + 1;
%     cpt_subp = cpt_subp + 1;
%     subplot(8,8,cpt_subp);
%     bar(sigs(cpt,:));
%     xlim([1 params.nbCenters(params.nbLayers)])
%     title(phonemas(ind));

% end

% % axis_events = [6.48e5, 6.71e5, 0, nb_levels_crossing];
% % plot_events(events_train);%, axis_events);
% fullfile(pwd, 'hots_data', 'distances.txt');
% distances = read_distances(fullfile(path_data, 'distances.txt'), events_train, params);
%
% %% Choix des distances, hotsogram, cochleogram
% layer_test = params.nbLayers;
% curr_dists = distances{layer_test};
%
% %%% Gammatonegram
% fid = fopen(fullfile(path_timit, 'files_used.txt'));
% tline = fgetl(fid);
% if isempty(strfind(tline, 'train'))
%     tline = fgetl(fid);
% end
%
% nb_bin = size(D,2);
% hotsogram = zeros(size(curr_dists,2), nb_bin);
% hotsogram2 = zeros(size(curr_dists,2), nb_bin);
%
% for ind = 1:nb_bin
%   condsup = (events_train.ts>=((ind-1)*10000));
%   condinf = (events_train.ts<(ind*10000));
%   idx_ev = find(condsup.*condinf);
%   if ~(isempty(idx_ev))
%      if numel(idx_ev) == 1
%         hotsogram(:,ind) = (-curr_dists(idx_ev,:));
%      else
%         hotsogram(:,ind) = sum((curr_dists(idx_ev,:)))/numel(idx_ev);
%      end
%      for ind2 = 1:params.nbCenters(layer_test)
%          hotsogram2(ind2,ind) = numel(find(events{layer_test+1}.p(idx_ev) == (ind2-1)));
%      end
%      col = hotsogram(:,ind);
%      col2 = hotsogram2(:,ind);
%      hotsogram(:,ind) = col(:)/max(col(:));
%      hotsogram2(:,ind) = col2(:)/max(col2(:));
%   end
% end
%
%
%
% %%% Magie noire
% mat_gammatone = zeros(size(D));
% mat_hots = zeros(size(D));
% g_lim = [-90, -30]; % des db
% h_lim = [0, 1]; % lin, plus ou moins
%
% idx_g = find((20*log10(D) > g_lim(1)) .* (20*log10(D) < g_lim(2)));
% idx_h = find((hotsogram > h_lim(1)) .* (hotsogram < h_lim(2)));
%
% mat_gammatone(20*log10(D) > g_lim(2)) = 1;
% mat_gammatone(idx_g) = (20*log10(D(idx_g))-g_lim(1))/(g_lim(2)-g_lim(1));
% mat_hots(idx_h) = (hotsogram(idx_h)-h_lim(1))/(h_lim(2)-h_lim(1));
%
% figure;
% subplot(211)
% imagesc(mat_gammatone); colorbar
% title('Gammatonegramme avec normalisation')
% subplot(212)
% imagesc(mat_hots); colorbar
% %title('Hotsogramme avec normalisation')
%
%
% %%% Affichages
% figure;
% subplot(311)
% % Load a waveform, calculate its gammatone spectrogram, then display:
% imagesc(20*log10(D)); axis xy
% g_lim = [-90, -30];
% caxis(g_lim)
% colorbar
% % F returns the center frequencies of each band;
% % display whichever elements were shown by the autoscaling
% set(gca,'YTickLabel',round(F(get(gca,'YTick'))));
% ylabel('freq / Hz');
% xlabel('time / 10 ms steps');
% title('Gammatonegram (fast)')
%
%
% subplot(312)
% imagesc(hotsogram2); colorbar; axis xy
% ylabel('center');
% xlabel('time / 10 ms steps');
% title(['Hots - output of layer ', num2str(layer_test), ...
%     ', ', num2str(params.nbCenters(layer_test)), ' centers'])
% %caxis([0 1])
%
% subplot(313)
% imagesc(hotsogram); colorbar; axis xy
% %set(gca,'YTickLabel',idx_centers);
% ylabel('center');
% xlabel('time / 10 ms steps');
% title('Hots - pondérations des ativations pour chaque centre de chaque event')
% %caxis(h_lim) % a virer
