clearvars -except all_events_train all_events_test
close all;

addpath(genpath('../functions'))

if ~exist('all_events_test', 'var')
    load('nmnist_data/all_events.mat');
end

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

N_workers = 72;
myCluster=parcluster('local');
myCluster.NumWorkers=N_workers;
parpool(myCluster,N_workers)


train_features = zeros(prod(size_spatial)*(ceil(max_ev/w_frame_us)-2*w_gliss_bins), ...
    numel(all_events_train,1));
test_features = zeros(prod(size_spatial)*(ceil(max_ev/w_frame_us)-2*w_gliss_bins), ...
    numel(all_events_test,1));
parfor ind = 1:numel(all_events_train,1)
  train_features(:,ind) = reshape( convert_events_into_tensor(...
    all_events_train{ind,1}, w_frame_us, max_ev, size_spatial, w_gliss_bins) ...
    ,1,[]);
end
parfor ind = 1:numel(all_events_test,1)
  test_features(:,ind) = reshape( convert_events_into_tensor(...
    all_events_test{ind,1}, w_frame_us, max_ev, size_spatial, w_gliss_bins) ...
    ,1,[]);
end

% train_features = cellfun(@(ev) reshape( ...
%   convert_events_into_tensor(ev, w_frame_us, max_ev, size_spatial, w_gliss_bins) ...
%   ,1,[]), ...
%   all_events_train(:,1), 'UniformOutput', 0);
%
% test_features = cellfun(@(ev) reshape( ...
%   convert_events_into_tensor(ev, w_frame_us, max_ev, size_spatial, w_gliss_bins) ...
%   ,1,[]), ...
%   all_events_test(:,1), 'UniformOutput', 0);
