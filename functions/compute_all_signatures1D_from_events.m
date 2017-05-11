function [signatures] = compute_all_signatures1D_from_events(events, labels, nbCenters)
% easy to adapt in c++, takes nbCenters avoiding calculating it with numel(unique(events.p))
% which is computationnaly expansive.

if isequal(size(labels), [1,3])
  label_format = 0;
  nb_label_pres = numel(labels{1});
else
  label_format = 1;
  nb_label_pres = size(label_train,1);
end

signatures = zeros(nb_label_pres,nbCenters+2);
nb_empty_sig = 0;
whichExampleItIs = 1;
% if there is less than thresh_events in signature, just discard it
thresh_events = 50;

for ind = 1:numel(events.ts)
  if label_format
    ts_max = labels{2}(whichExampleItIs);
    curr_label = labels{3}(whichExampleItIs);
  else
    ts_max = labels{whichExampleItIs,2};
    curr_label = labels{whichExampleItIs,3};
  end
  while (events.ts(ind) > ts_max)
    if (signatures(whichExampleItIs - nb_empty_sig, 2) == 0)
      nb_empty_sig = nb_empty_sig + 1;
    else
      if curr_label == 0 || signatures(whichExampleItIs - nb_empty_sig, 2) < thresh_events
        signatures(whichExampleItIs - nb_empty_sig, :) = 0;
        nb_empty_sig = nb_empty_sig + 1;
      else
        signatures(whichExampleItIs - nb_empty_sig, 3:end) = ...
          signatures(whichExampleItIs - nb_empty_sig, 3:end) / ...
          signatures(whichExampleItIs - nb_empty_sig, 2);
          signatures(whichExampleItIs - nb_empty_sig, 1) = curr_label;
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
  if curr_label == 0 || signatures(whichExampleItIs - nb_empty_sig, 2) < thresh_events
    signatures(whichExampleItIs - nb_empty_sig, :) = 0;
    nb_empty_sig = nb_empty_sig + 1;
  else
  signatures(whichExampleItIs - nb_empty_sig, 3:end) = ...
    signatures(whichExampleItIs - nb_empty_sig, 3:end) / ...
    signatures(whichExampleItIs - nb_empty_sig, 2);
    signatures(whichExampleItIs - nb_empty_sig, 1) = curr_label;
  end
end
signatures = signatures(1:whichExampleItIs-nb_empty_sig,:);
