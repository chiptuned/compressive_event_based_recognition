function [occs] = hots_reco(events, labels, params)

nbCenters = params.nbCenters;
occs = zeros(numel(labels{1}), nbCenters);

for ind = 1:numel(labels{1})
  condsup = (events.ts>=labels{1}(ind));
  condinf = (events.ts<labels{2}(ind));
  idx_ev = find(condsup.*condinf);
  if ~(isempty(idx_ev))
    cpt = 0;
    for ind2 = 1:nbCenters
      % idx_ev'
      % events.p(idx_ev)'
      occs(ind, ind2) = numel(find(events.p(idx_ev) == ind2-1));
      cpt = cpt + occs(ind, ind2);
    end
    occs(ind, :) = occs(ind, :)/cpt;
  end
end