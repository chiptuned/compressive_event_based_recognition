function [reco_rate_mlp] = compute_reco_using_mlp(all_sigs_train, all_sigs_test)
% sigs are nLabels * nbCenters+2
% sigs(:,1) are their class (integer)
% sigs(:,2) are the number of occurancies of each centers;

classes = unique(all_sigs_train(:,1));
nb_classes = numel(classes);
nb_examples_train = size(all_sigs_train,1);
train_output = zeros(nb_examples_train, nb_classes);
for ind = 1:nb_examples_train
  curr_class = find(all_sigs_train(ind,1)==classes);
  train_output(ind,curr_class) = 1;
end

nb_examples_test = size(all_sigs_test,1);
test_output = zeros(nb_examples_test, nb_classes);
for ind = 1:nb_examples_test
  curr_class = find(all_sigs_test(ind,1)==classes);
  test_output(ind,curr_class) = 1;
end

features1 = all_sigs_train(:,3:end)';
targets1 = train_output';
features2 = all_sigs_train(:,3:end)';
targets2 = train_output';

nb_neurons_each_layer = [100,1000];%, 500];
[net] = patternnet(nb_neurons_each_layer, 'trainscg', 'crossentropy');
net.divideParam.trainRatio = 0.7;
net.divideParam.valRatio = 0.3;
net.divideParam.testRatio = 0;


net = train(net,features1,targets1);%, 'CheckpointFile','Checkpoint_MLP', 'CheckpointDelay',120, 'showResources','yes');
output = sim(net,features2);

% plotconfusion(targets, net_outputs);
reco_rate_mlp = 1-confusion(targets2, output);
