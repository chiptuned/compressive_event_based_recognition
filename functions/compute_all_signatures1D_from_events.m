function [signatures] = compute_all_signatures1D_from_events(events, labels, nbCenters)
% easy to adapt in c++, takes nbCenters avoiding calculating it with numel(unique(events.p))
% which is computationnaly expansive.

signatures = zeros(numel(labels{1}),nbCenters+2);
nb_empty_sig = 0;
whichExampleItIs = 1;
% if there is less than thresh_events in signature, just discard it
thresh_events = 50;

for ind = 1:numel(events.ts)
  while (events.ts(ind) > labels{2}(whichExampleItIs))
    if (signatures(whichExampleItIs - nb_empty_sig, 2) == 0)
      nb_empty_sig = nb_empty_sig + 1;
    else
      if labels{3}(whichExampleItIs) == 0 || signatures(whichExampleItIs - nb_empty_sig, 2) < thresh_events
        signatures(whichExampleItIs - nb_empty_sig, :) = 0;
        nb_empty_sig = nb_empty_sig + 1;
      else
        signatures(whichExampleItIs - nb_empty_sig, 3:end) = ...
          signatures(whichExampleItIs - nb_empty_sig, 3:end) / ...
          signatures(whichExampleItIs - nb_empty_sig, 2);
          signatures(whichExampleItIs - nb_empty_sig, 1) = labels{3}(whichExampleItIs);
      end
    end
    whichExampleItIs = whichExampleItIs + 1;
  end
  signatures(whichExampleItIs - nb_empty_sig, 3+events.p(ind)) = ...
    signatures(whichExampleItIs - nb_empty_sig, 3+events.p(ind)) + 1;
  signatures(whichExampleItIs - nb_empty_sig, 2) = ...
    signatures(whichExampleItIs - nb_empty_sig, 2) + 1;
end

if signatures(whichExampleItIs - nb_empty_sig, 1) == 0
  if labels{3}(whichExampleItIs) == 0 || signatures(whichExampleItIs - nb_empty_sig, 2) < thresh_events
    signatures(whichExampleItIs - nb_empty_sig, :) = 0;
    nb_empty_sig = nb_empty_sig + 1;
  else
  signatures(whichExampleItIs - nb_empty_sig, 3:end) = ...
    signatures(whichExampleItIs - nb_empty_sig, 3:end) / ...
    signatures(whichExampleItIs - nb_empty_sig, 2);
    signatures(whichExampleItIs - nb_empty_sig, 1) = labels{3}(whichExampleItIs);
  end
end
signatures = signatures(1:whichExampleItIs-nb_empty_sig,:);
