function [reco_rate] = compute_reco_using_metasigs(sig_train, sig_test)
% Cette fonction prend les signatures 1D normalisées

label_train = sig_train(:,1);
classes = unique(label_train);
nbclasses = numel(classes);
label_truth = sig_test(:,1);
nb_label_test = numel(label_truth);
label_pred = zeros(nb_label_test,1);

metasigs = zeros(nbclasses, size(sig_train,2));
for ind = 1:nbclasses
  idx_curr_class = find(label_train==ind);
  metasigs(ind,1) = classes(ind);
  metasigs(ind,2) = 1;
  metasigs(ind,3:end) = mean(sig_train(idx_curr_class,3:end));
end

[reco_rate] = compute_reco_using_kppv(metasigs, sig_test, 1, 'bhattacharrya');
