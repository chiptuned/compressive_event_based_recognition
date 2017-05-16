function [res] = compute_event_activity(ev, timestep, final_time, normalize_bins)

nb_bins = double(ceil(final_time/timestep));
ev_activity = zeros(1,nb_bins);
curr_bin = 1;

for ind = 1:numel(ev.ts)
  while ev.ts(ind) > (curr_bin*timestep)
    curr_bin = curr_bin+1;
  end
  ev_activity(curr_bin) = ev_activity(curr_bin) + 1;
end

if ~exist('normalize_bins', 'var')
  res = ev_activity;
else
  ev_norms = zeros(1,nb_bins - 2*normalize_bins);
  for ind = (normalize_bins+1):(nb_bins-normalize_bins)
    ev_norms(ind-normalize_bins) = sum(ev_activity(ind+(-normalize_bins:normalize_bins)));;
  end
  ev_norms = ev_norms-min(ev_norms);
  ev_norms = ev_norms./max(ev_norms);
  res = ev_norms;
end
