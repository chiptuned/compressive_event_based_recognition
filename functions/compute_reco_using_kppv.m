function [reco_rate] = compute_reco_using_kppv(sig_train, sig_test, k, dist)
% Cette fonction prend les signatures 1D normalisées

if ~exist('k', 'var')
  k = 1;
end
if ~exist('dist', 'var')
  dist = 'euclidean';
end

label_train = sig_train(:,1);
nbclasses = numel(unique(label_train));
label_truth = sig_test(:,1);
nb_label_test = numel(label_truth);
label_pred = zeros(nb_label_test,1);
X = sig_train(:,3:end);
Y = sig_test(:,3:end);
idx_label = label_train(my_knnsearch(X,Y,k,dist));
reco_rate = zeros(1,k);

for ind_k = 1:k
  idx_label_k = idx_label(:,1:ind_k);
  for ind = 1:nb_label_test
    line = idx_label_k(ind,:);
    classes_in_line = unique(line);
    [~, idx_best] = max(hist(line,numel(classes_in_line)));
    label_pred(ind) = classes_in_line(idx_best(1));
  end

  cmat = confusionmat(label_truth,label_pred);
  reco_rate(ind_k) = trace(cmat)/sum(cmat(:));
end
end

function dists = bhattacharrya(v1, v2)
  num_ex = size(v2,1);
  dists = zeros(num_ex,1);
  for ind = 1:num_ex
    dists = -log(sqrt(sum(v1(:).*v2(ind,:))));
  end
end
