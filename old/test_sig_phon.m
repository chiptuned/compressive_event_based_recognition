layer_sig = 2;
events_sig = events{layer_sig+1};
label_sig = label_train;
nbCenters = params.nbCenters(layer_sig);
list_phon = (unique(label_sig{3}));
nb_phon = numel(list_phon);

max_occ_phon = 16;
for ind = 1:nb_phon
  phonema = list_phon{ind}
  idx_label_phon = [];
  for ind2 = 1:numel(label_sig{3})
    if strcmp(label_sig{3}{ind2}, phonema)
      idx_label_phon = [idx_label_phon, ind2];
    end
  end

  if numel(idx_label_phon)>max_occ_phon
    idx_rand = randperm(numel(idx_label_phon));
    idx_label_phon = idx_label_phon(idx_rand(1:max_occ_phon));
  end
  figure;
  hold on;
  for ind2 = 1:numel(idx_label_phon)
    ts_start = double(label_sig{1}(idx_label_phon(ind2)));
    ts_end = double(label_sig{2}(idx_label_phon(ind2)));
    idx_ev = find((events_sig.ts >= ts_start) .* (events_sig.ts < ts_end));
    events_to_plot.ts = events_sig.ts(idx_ev) - ts_start;
    events_to_plot.level = events_sig.level(idx_ev);
    events_to_plot.p = events_sig.p(idx_ev);
    subplot(4,4,ind2)
    colors = distinguishable_colors(nbCenters);
    plot_events(events_to_plot, colors)
    listen_audio(events_to_plot)
    pause(0.1)
  end
end
