function [res] = convert_events_into_tensor(ev, timestep, final_time, boardSize, normalize_bins)

nb_bins = double(ceil(final_time/timestep));
ev_activity = zeros(boardSize(1), boardSize(2), nb_bins);
curr_bin = 1;

for ind = 1:numel(ev.ts)
  while ev.ts(ind) > (curr_bin*timestep)
    curr_bin = curr_bin+1;
  end
  ev_activity(ev.x(ind), ev.y(ind), curr_bin) = ev_activity(ev.x(ind), ev.y(ind), curr_bin) + 1;
end

if ~exist('normalize_bins', 'var')
  res = ev_activity;
else
  ev_norms = zeros(boardSize(1), boardSize(2), nb_bins - 2*normalize_bins);
  for ind = (normalize_bins+1):(nb_bins-normalize_bins)
    ev_norms(:, :, ind-normalize_bins) = sum(ev_activity(:, :, ind+(-normalize_bins:normalize_bins)),3);
  end
  ev_norms = ev_norms-repmat(min(ev_norms,[],3),1,1,size(ev_norms,3));
  ev_norms = ev_norms./repmat(max(ev_norms,[],3),1,1,size(ev_norms,3));
  ev_norms(isnan(ev_norms)) = 0;
  res = ev_norms;
end
