clearvars -except all_events_train all_events_test train_feat_reduced train_feat_reduced
close all;

tstart = tic;
addpath(genpath('../functions'))
rng(0,'twister');

%% Start Parpool
N_workers = 72;
myCluster=parcluster('local');
myCluster.NumWorkers=N_workers;
poolobj = parpool(myCluster,N_workers);
fprintf('Pool started, with %.0f workers. Elapsed time : %f seconds\n', N_workers, toc(tstart));

%% Load events
if ~exist('all_events_test', 'var')
    load('nmnist_data/all_events.mat');
end
fprintf('Events loaded, elapsed time : %f seconds\n', toc(tstart));

%% Find the temporal tiles parameters
max_ev_train = max(cellfun(@(ev) max(ev.ts), all_events_train(:,1)));
max_ev_test = max(cellfun(@(ev) max(ev.ts), all_events_test(:,1)));
max_ev = max([max_ev_train, max_ev_test]);

size_spatial = [34,34];
w_gliss_bins = 3;
w_frame_us = 4000;
ntrain = size(all_events_train,1);
ntest = size(all_events_test,1);

fprintf('Parameters computed, elapsed time : %f seconds\n', toc(tstart));

%% Compute tiles
feats = zeros(ntrain + ntest, ...
    prod(size_spatial)*(ceil(double(max_ev)/w_frame_us)-2*w_gliss_bins));
parfor ind = 1:ntrain
  feats(ind,:) = reshape(convert_events_into_tensor(...
    all_events_train{ind,1}, w_frame_us, max_ev, size_spatial, w_gliss_bins) ...
    ,1,[]);
end
parfor ind = 1:ntest
  feats(ind+ntrain,:) = reshape(convert_events_into_tensor(...
    all_events_test{ind,1}, w_frame_us, max_ev, size_spatial, w_gliss_bins) ...
    ,1,[]);
end

fprintf('Tiles computed, elapsed time : %f seconds\n', toc(tstart));

%% Reduce dimensionnality
% FSVD with power method
nb_dims_svd = 300;
[U2, S2, V2] = fsvd(feats, nb_dims_svd, 2, true);
new_feats = U2*S2;
train_feat_reduced = new_feats(1:ntrain,:);
test_feat_reduced = new_feats(ntrain+(1:ntest),:);

fprintf('SVD computed, elapsed time : %f seconds\n', toc(tstart));

clearvars -except tstart poolobj all_events_train all_events_test train_feat_reduced test_feat_reduced

%% Shuffling and MLP
nb_tries = 10;
nets_save = cell(1,nb_tries);
seeds = randi(1000000,1,nb_tries);

parfor ind = 1:nb_tries
    
    rng(seeds(ind));
    idx_train = randperm(60000);
    x = train_feat_reduced(idx_train,:)';
    t = full(ind2vec(cellfun(@(a) a,all_events_train(idx_train,2))'));
    idx_test = randperm(10000);
    x2 = test_feat_reduced(idx_test,:)';
    t2 = full(ind2vec(cellfun(@(a) a,all_events_test(idx_test,2))'));

    trainFcn = 'trainscg';  % Scaled conjugate gradient backpropagation. help nntrain
    % Create a Pattern Recognition Network
    hiddenLayerSize = 1000;
    net = patternnet(hiddenLayerSize);

    % Input and Output Pre/Post-Processing Functions ? help nnprocess
    net.divideFcn = 'divideblock';  % Divide data in blocks (shuffled before)
    net.divideMode = 'sample';  % Divide up every sample
    net.divideParam.trainRatio = 0.75;
    net.divideParam.valRatio = 0.25;
    net.divideParam.testRatio = 0;
    net.performFcn = 'crossentropy';  % Cross-Entropy, help nnperformance
    net.plotFcns = {'plotperform','plottrainstate','ploterrhist', ...
        'plotconfusion', 'plotroc'};

    % Train the Network
    net.trainParam.showWindow=0;
    [net,tr] = train(net,x,t);
    y = net(x);
    y2 = net(x2);
    reco_rate = 1-confusion(t2, y2);
    nets_save{ind} = {net, tr, seeds(ind), reco_rate}; 
end
reco_rates = cellfun(@(cell) cell{4}, nets_save);
mean_reco_rates = mean(reco_rates)*100;
range_reco_rates = range(reco_rates)*100;
std_reco_rates = std(reco_rates)*100;

save('test_save_nmnist_tensor.mat', 'nets_save');

fprintf('Done! Elapsed time : %f seconds\n', toc(tstart));
delete(poolobj)