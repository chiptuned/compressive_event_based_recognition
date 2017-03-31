clearvars;
close all;
[features, targets] = thyroid_dataset;
net = patternnet([10], 'trainscg', 'crossentropy');
net = train(net,features,targets);
net_outputs = net(features);
% plotconfusion(targets, net_outputs);
conf_rate = confusion(targets, net_outputs);
filename = ['conf_', num2str(round(conf_rate*100,2)), '_pourcent.mat'];
save(filename, 'net_outputs')