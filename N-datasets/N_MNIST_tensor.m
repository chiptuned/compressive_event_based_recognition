clearvars -except all_events_train all_events_test
close all;

tstart = tic;
addpath(genpath('../functions'))

%% Load events
if ~exist('all_events_test', 'var')
    load('nmnist_data/all_events.mat');
end
fprintf('Events loaded, elapsed time : %f seconds\n', toc(tstart));

%% Find the temporal tiles parameters
min_ev_train = min(cellfun(@(ev) min(ev.ts), all_events_train(:,1)));
max_ev_train = max(cellfun(@(ev) max(ev.ts), all_events_train(:,1)));

min_ev_test = min(cellfun(@(ev) min(ev.ts), all_events_test(:,1)));
max_ev_test = max(cellfun(@(ev) max(ev.ts), all_events_test(:,1)));


max_ev = max([max_ev_train, max_ev_test]);
% hists_activity = cellfun(@(ev) compute_event_activity(ev, 1000, max_ev, 10), ...
%   all_events_train(:,1), 'UniformOutput', 0);
%
% hold off;
% for ind = 1:50
%   plot(hists_activity{ind})
%   hold on;
% end
%
% cellfun(@(ev) draw_scene_ev2D(ev, 10000, 10000, [35 35]), ...
%   all_events_train(:,1));

% test = convert_events_into_tensor(all_events_test{1}, 4000, max_ev, [34, 34], 3);
% for ind = 1:size(test,3)
%   imagesc(test(:,:,ind))
%   pause
% end

size_spatial = [34,34];
w_gliss_bins = 3;
w_frame_us = 4000;

fprintf('Parameters computed, elapsed time : %f seconds\n', toc(tstart));

%% Compute tiles
train_features = zeros(size(all_events_train,1), ...
    prod(size_spatial)*(ceil(double(max_ev)/w_frame_us)-2*w_gliss_bins));
test_features = zeros(size(all_events_test,1), ...
    prod(size_spatial)*(ceil(double(max_ev)/w_frame_us)-2*w_gliss_bins));

N_workers = 72;
myCluster=parcluster('local');
myCluster.NumWorkers=N_workers;
parpool(myCluster,N_workers)

parfor ind = 1:size(all_events_train,1)
  train_features(ind,:) = reshape(convert_events_into_tensor(...
    all_events_train{ind,1}, w_frame_us, max_ev, size_spatial, w_gliss_bins) ...
    ,1,[]);
end
parfor ind = 1:size(all_events_test,1)
  test_features(ind,:) = reshape(convert_events_into_tensor(...
    all_events_test{ind,1}, w_frame_us, max_ev, size_spatial, w_gliss_bins) ...
    ,1,[]);
end

fprintf('Tiles computed, elapsed time : %f seconds\n', toc(tstart));

% train_features = cellfun(@(ev) reshape( ...
%   convert_events_into_tensor(ev, w_frame_us, max_ev, size_spatial, w_gliss_bins) ...
%   ,1,[]), ...
%   all_events_train(:,1), 'UniformOutput', 0);
% test_features = cellfun(@(ev) reshape( ...
%   convert_events_into_tensor(ev, w_frame_us, max_ev, size_spatial, w_gliss_bins) ...
%   ,1,[]), ...
%   all_events_test(:,1), 'UniformOutput', 0);

%% Reduce dimensionnality
% FSVD with power method
X = [train_features;test_features];
nb_dims_svd = 300;
tic
[U2, S2, V2] = fsvd(X, nb_dims_svd, 2, true);
toc
new_X = U2*S2;
train_feat_reduced = new_X(1:60000,:);
test_feat_reduced = new_X(60001:end,:);

% preserve 99% variance but of fsvd so need to deep down
% because actually fsvd cuts to the nb_dims_svd dims and don't preserve
% a specific amount of variance (probably around 80-95%)

% sing_values = diag(S2);
% normsqS = sum(sing_values.^2);
% k = find(cumsum(sing_values.^2)/normsqS >= 0.97, 1);

fprintf('SVD computed, elapsed time : %f seconds\n', toc(tstart));


%% Shuffling
% intule car dans nprtool mais on le fait quand meme
idx_train = randperm(60000);
train_feats_mlp = train_feat_reduced(idx_train,:);
train_label_mlp = cellfun(@(a) a,all_events_train(idx_train,2));

classes = unique(train_label_mlp);
nb_classes = numel(classes);

nb_examples_train = numel(train_label_mlp);
train_output = zeros(nb_examples_train, nb_classes);
for ind = 1:nb_examples_train
  curr_class = find(train_label_mlp(ind)==classes);
  train_output(ind,curr_class) = 1;
end

idx_test = randperm(10000);
test_feats_mlp = test_feat_reduced(idx_test,:);
test_label_mlp = cellfun(@(a) a,all_events_test(idx_test,2));

nb_examples_test = numel(test_label_mlp);
test_output = zeros(nb_examples_test, nb_classes);
for ind = 1:nb_examples_test
  curr_class = find(test_label_mlp(ind)==classes);
  test_output(ind,curr_class) = 1;
end

fprintf('Features order is now shuffled, elapsed time : %f seconds\n', toc(tstart));

clearvars -except all_events_train all_events_test train_output test_output train_feats_mlp test_feats_mlp

% then we use nprtool, using 45000 train 12000 val 3000 test samples,
% 1 layer of 1000 neurons, on R2016a.
% then the error is on test data
% 10 fold cross validation
% 3.58 3.39 3.33 3.57 3.28 3.33 3.36 3.55 3.6 3.41
% mean : 96.56%   std : 0.1219   range : +- 0.16%   meanerr : 3.44%
