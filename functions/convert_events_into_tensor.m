function [res] = convert_events_into_tensor(ev, timestep, final_time, boardSize, normalize_bins)

nb_bins = double(ceil(final_time/timestep));
ev_activity = zeros(boardSize(1), boardSize(2), nb_bins);
curr_bin = 1;

for ind = 1:numel(ev.ts)
  if ev.p(ind) ~= 1
    continue;
  end
  while ev.ts(ind) > (curr_bin*timestep)
    curr_bin = curr_bin+1;
  end
  try
    ev_activity(ev.x(ind), ev.y(ind), curr_bin) = ev_activity(ev.x(ind), ev.y(ind), curr_bin) + 1;
  catch
     fprintf('numel events : %d\n', numel(ev.ts));
     fprintf('curr ev : (%d, %d, %d, %d)\n', ev.ts(ind), ev.x(ind), ev.y(ind), ev.p(ind));
     fprintf('timestep %d, finaltime %d, curr_bin %d\n', timestep, final_time, curr_bin);
     error('index m8.');
  end
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
