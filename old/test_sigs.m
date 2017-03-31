layer_sig = 3;
%events_sig = events{layer_sig+1};
label_sig = simplify_labels(label_test);
nbCenters = params.nbCenters(layer_sig);
list_phon = (unique(label_sig{3}));
nb_phon = numel(list_phon);

max_occ_phon = 1000;
occs_eventssig = zeros(1,nbCenters);
sigcell_tot =  cell(1,nb_phon);
for ind = 1:nb_phon
  phonema = list_phon{ind}
  idx_label_phon = [];
  for ind2 = 1:numel(label_sig{3})
    if strcmp(label_sig{3}{ind2}, phonema)
      idx_label_phon = [idx_label_phon, ind2];
    end
  end

  if numel(idx_label_phon)>max_occ_phon
    idx_label_phon = idx_label_phon(1:max_occ_phon);
  end

  occ_phon = 0;
  occs_tot = [];
  for ind2 = 1:numel(idx_label_phon)
    hold on;
    ts_start = int64(label_sig{1}(idx_label_phon(ind2)));
    ts_end = int64(label_sig{2}(idx_label_phon(ind2)));
    idx_ev = find((events_sig.ts >= ts_start) .* (events_sig.ts < ts_end));
    if (numel(idx_ev)  ~= 0)
      occ_phon = occ_phon + 1;
      events_pols = events_sig.p(idx_ev);
      occs_sig = zeros(1,nbCenters);
      for ind3 = 1:nbCenters
        occs_sig(ind3) = numel(find(events_pols == (ind3-1)));
      end
      occs_eventssig = occs_eventssig + occs_sig;
      occs_tot = [occs_tot; occs_sig];%/sum(occs_sig(:))];
    end
  end
  sigcell_tot(ind) = {[{occs_tot}, occ_phon, numel(idx_label_phon)]};
end

%% Affichages
figure;
for ind = 1:nb_phon
  subplot(8,8,ind);
  hold on;
  for ind2 = 1:size(sigcell_tot{ind}{1}, 1)
    plot(sigcell_tot{ind}{1}(ind2,:), '*');
  end
  xlim([1 nbCenters])
  hold off;
  title([list_phon{ind}, ' ', num2str(sigcell_tot{ind}{2}), '/', num2str(sigcell_tot{ind}{3})]);
end

figure;
for ind = 1:nb_phon
  subplot(8,8,ind);
  bar(mean(sigcell_tot{ind}{1},1))
  hold on;
  if size(sigcell_tot{ind}{1}, 1) == 1
     std_sig = zeros(size(sigcell_tot{ind}{1}));
  else
     std_sig = std(sigcell_tot{ind}{1},1);
  end
  errorbar(mean(sigcell_tot{ind}{1},1), std_sig, '.r')
  hold off;
  axis([1 nbCenters 0 max(mean(sigcell_tot{ind}{1},1))])
  title([list_phon{ind}, ' ', num2str(sigcell_tot{ind}{2}), '/', num2str(sigcell_tot{ind}{3})]);
end

features = zeros(nbCenters+1,numel(label_sig{1}));
for ind2 = 1:numel(label_sig{1})
  idx_ev = find((events_sig.ts >= label_sig{1}(ind2)) .* (events_sig.ts < label_sig{2}(ind2)));
  for ind3 = 1:nbCenters
    features(ind3,ind2) = numel(find(events_sig.p(idx_ev) == (ind3-1)));
  end
end
features(end,:) = label_sig{3};
save('features_test.mat', 'features')