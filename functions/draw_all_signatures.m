function fig_handler = draw_all_sigatures(sigs)
% A mettre dans une fonction
diff_phon = unique(sigs(:,1));
nbC = size(sigs,2)-2;
nb_phon = numel(diff_phon);
fig_handler = figure;
for ind = 1:nb_phon
  subplot(8,8,ind)
  sigs_phon = sigs(sigs(:,1)==diff_phon(ind),:);
  occurs_phon = sigs_phon(:,2);
  sigs_phon_norm = sigs_phon(:,3:end);

  if size(sigs_phon_norm,1) > 1
    bar(mean(sigs_phon_norm))
    hold on;
    errorbar(mean(sigs_phon_norm), std(sigs_phon_norm), '.r')
  else
    bar(sigs_phon_norm)
  end

  hold off;
  axis([0, nbC, 0, 1])
end
