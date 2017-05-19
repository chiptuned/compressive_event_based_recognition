function [res] = convert_events_into_tensor(ev, timestep, final_time, boardSize, normalize_bins, variante)

if ~exist('variante', 'var')
  variante = 'pol1';
end

if ~strcmp(variante, 'activity')
  nb_bins = ceil(double(final_time)/timestep);
  ev_activity = zeros(boardSize(1), boardSize(2), nb_bins);
  size_ev_start = size(ev_activity);
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

elseif ~strcmp(variante, 'pol1')
  nb_bins = ceil(double(final_time)/timestep);
  ev_activity = zeros(boardSize(1), boardSize(2), nb_bins);
  size_ev_start = size(ev_activity);
  curr_bin = 1;

  for ind = 1:numel(ev.ts)
    if ev.p(ind) ~= 1
      continue;
    end
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

elseif ~strcmp(variante, 'each_pol')
  nb_bins = ceil(double(final_time)/timestep);
  pols = unique(ev.p);
  ev_activity = zeros(boardSize(1), boardSize(2), numel(pols), nb_bins);
  size_ev_start = size(ev_activity);
  curr_bin = 1;

  for ind = 1:numel(ev.ts)
    while ev.ts(ind) > (curr_bin*timestep)
      curr_bin = curr_bin+1;
    end
    ev_activity(ev.x(ind), ev.y(ind), find(ev.p(ind)==pols), curr_bin) = ...
      ev_activity(ev.x(ind), ev.y(ind), find(ev.p(ind)==pols), curr_bin) + 1;
  end

  if ~exist('normalize_bins', 'var')
    res = ev_activity;
  else
    ev_norms = zeros(boardSize(1), boardSize(2), numel(pols), nb_bins - 2*normalize_bins);
    for ind = (normalize_bins+1):(nb_bins-normalize_bins)
      ev_norms(:, :, :, ind-normalize_bins) = sum(ev_activity(:, :, :, ind+(-normalize_bins:normalize_bins)),4);
    end
    ev_norms = ev_norms-repmat(min(ev_norms,[],4),1,1,1,size(ev_norms,4));
    ev_norms = ev_norms./repmat(max(ev_norms,[],4),1,1,1,size(ev_norms,4));
    ev_norms(isnan(ev_norms)) = 0;
    res = ev_norms;
  end
end
