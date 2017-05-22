function [events, labels, idx_pres] = prepare_dataset_dat(train, test, path_data, ratio)

%% prepare folder
if ~exist('path_data', 'var')
  path_data = 'dataset_dat';
end
% FIXME : create folder
% FIXME : delete everything in it
if ~exist(path_data, 'dir')
  mkdir(path_data)
else
  delete(fullfile(path_data, '*.dat'))
end

%% Partitioning the dataset
idx_shuffle_train = randperm(size(train,1));
numex_train_hots = floor(size(train,1)*ratio);

cellev = {train(idx_shuffle_train(1:numex_train_hots),:), ...
  train(idx_shuffle_train((numex_train_hots+1):end),:), ...
  test(randperm(size(test,1)),:)};


%% Calculate the time interval between two presentations
% Empirically set to 10x the duration of the longest presentation of a class
max_ev = max(cellfun(@(cell_array) max(cellfun(@(ev) max(ev.ts), cell_array(:,1))), cellev));
offset_interval = 10*double(max_ev);

%%
num_ev = cellfun(@(cell_array) {cellfun(@(ev) numel(ev.ts), cell_array(:,1))}, cellev);

filenames = {'events_train_hots.dat', 'events_train_classif.dat', 'events_test_classif.dat'};

fdn = fieldnames(train{1});
evclasses = cellfun(@(fdn) {class(train{1}.(fdn))}, fdn);
nb_f = numel(fdn);
idx_of_ts = cellfun(@(str) strcmp(str,'ts'), fdn);
fdn_wo_ts = fdn(~idx_of_ts);

for ind_ev = 1:numel(cellev)
  offset = 0;
  nbev_tot = sum(num_ev{ind_ev});
  nbpres = size(cellev{ind_ev},1);
  for ind_f = 1:nb_f-1
    events{ind_ev}.(fdn_wo_ts{ind_f}) = zeros(nbev_tot, 1, evclasses{ind_f});
  end
  events{ind_ev}.ts = zeros(nbev_tot, 1, 'uint64');

  borne_inf = 0;
  bar = waitbar(0,['Creating events (',num2str(ind_ev), ' of 3)']);
  for ind = 1:nbpres
    ev = cellev{ind_ev}{ind,1};
    nbev = num_ev{ind_ev}(ind);
    events{ind_ev}.ts(borne_inf+(1:nbev)) = uint64(ev.ts) + offset;
    for ind_f = 1:(nb_f-1)
      events{ind_ev}.(fdn_wo_ts{ind_f})(borne_inf+(1:nbev)) = ev.(fdn_wo_ts{ind_f});
    end
    borne_inf = borne_inf + nbev;
    last_offset = write_event2D_64bit_ts(ev, ...
      fullfile(path_data, filenames{ind_ev}), 'a', offset);
    labels{ind_ev}{ind,1} = offset;
    labels{ind_ev}{ind,2} = last_offset;
    labels{ind_ev}{ind,3} = cellev{ind_ev}{ind,2};
    idx_pres{ind_ev}{ind} = cellev{ind_ev}{ind,3};
    offset = last_offset + offset_interval;
    if mod(ind,nbpres/100) == 0
      waitbar(ind/nbpres, bar);
    end
  end
  delete(bar)
end
