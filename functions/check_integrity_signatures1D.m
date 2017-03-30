function [] = check_integrity_signatures1D(events, labels, all_sigs)
% all_sigs : matrix n*m, n = number of "good" sigs, m = nbcenters + 2;
% all_sigs(:,1) is the vector of good labels;
% all_sigs(:,2) is the number of events in each signature;
% all_sigs(:,3:end) is the normalized signature as sum(all_sigs(curr_sig,3:end)) must be 1.
% a "good" signature is a signature where the class of the label or the
% number of events is not zero.

nbCenters = size(all_sigs,2) - 2;
signatures = zeros(numel(labels{1}), nbCenters);
labels_sig = labels{3};
occs_sig = zeros(1,numel(labels{1}));

all_sigs_cpt = 0;

for ind = 1:numel(labels_sig)
  cond = (events.ts > labels{1}(ind)) .* (events.ts <= labels{2}(ind));
  occs_sig(ind) = numel(find(cond));
  pols = events.p(find(cond));
  for center = 1:nbCenters
    signatures(ind, center) = numel(find(pols==center-1));
  end
  if (labels_sig(ind)~= 0) && (occs_sig(ind) ~= 0)
    all_sigs_cpt = all_sigs_cpt + 1;
    if all_sigs(all_sigs_cpt,1) ~= labels_sig(ind)
      all_sigs(all_sigs_cpt,1)
      labels_sig(ind)
      msg = 'Not the same labels.';
      error(msg)
    end
    if all_sigs(all_sigs_cpt,2) ~= occs_sig(ind)
      all_sigs(all_sigs_cpt,2)
      occs_sig(ind)
      msg = 'Not the same occurancies.';
      error(msg)
    end
    if all_sigs(all_sigs_cpt,3:end) ~= (signatures(ind,:)/occs_sig(ind))
      all_sigs(all_sigs_cpt,3:end)
      signatures(ind,:)
      (signatures(ind,:)/occs_sig(ind))
      msg = 'Not the same signatures.';
      error(msg)
    end
  end
end
fprintf('Signatures ok!\n')
