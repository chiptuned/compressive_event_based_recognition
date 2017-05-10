function [events_train_hots, events_train_classif, events_test_classif, label_train, label_test] = prepare_N_MNIST_dataset(ratio, path_data)

if ~exist('path_data', 'var')
  path_data = 'nmnist_data';
end

rng(0);

load(fullfile(path_data,'all_events.mat'));

%% Check if events computation is needed
if ~exist('all_events_train', 'var') || ~exist('all_events_train', 'var')
  if ~exist(fullfile(path_data,'all_events.mat'),'file')
    [all_events_train, all_events_test] = get_events_from_N_MNIST();
  else
    load(fullfile(path_data,'all_events.mat'));
  end
end
idx_shuffle_train = randperm(size(all_events_train,1));
numel_examples_train_hots = floor(size(all_events_train,1)*ratio);
cell_events_train_hots = all_events_train(idx_shuffle_train(1:numel_examples_train_hots),:);
cell_events_train_classif = all_events_train(idx_shuffle_train((numel_examples_train_hots+1):end),:);
cell_events_test = all_events_test(randperm(size(all_events_test,1)),:);

label_train = cell(size(cell_events_train_classif));
label_test = cell(size(cell_events_test));

offset_interval = 1000000;
delete('*.dat')
offset = 0;
bar = waitbar(0,'Creating events\_train\_hots');
numel_events_train_hots = cellfun(@(ev) numel(ev.ts), cell_events_train_hots(:,1));
events_train_hots.ts = zeros(sum(numel_events_train_hots), 1, 'uint64');
events_train_hots.x = zeros(sum(numel_events_train_hots), 1, 'uint8');
events_train_hots.y = zeros(sum(numel_events_train_hots), 1, 'uint8');
events_train_hots.p = false(sum(numel_events_train_hots), 1);
borne_inf = 0;
for ind = 1:size(cell_events_train_hots,1)
  events_train_hots.ts(borne_inf+(1:numel_events_train_hots(ind))) = uint64(cell_events_train_hots{ind,1}.ts) + offset;
  events_train_hots.x(borne_inf+(1:numel_events_train_hots(ind))) = cell_events_train_hots{ind,1}.x;
  events_train_hots.y(borne_inf+(1:numel_events_train_hots(ind))) = cell_events_train_hots{ind,1}.y;
  events_train_hots.p(borne_inf+(1:numel_events_train_hots(ind))) = cell_events_train_hots{ind,1}.p;
  borne_inf = borne_inf + numel_events_train_hots(ind);
  last_offset = write_event2D_64bit_ts(cell_events_train_hots{ind,1}, ...
    fullfile(path_data,'events_train_hots.dat'), 'a', offset);
  offset = last_offset + offset_interval;
  if mod(ind,size(cell_events_train_hots,1)/100) == 0
    waitbar(ind/size(cell_events_train_hots,1), bar);
  end
end

offset = 0;
delete(bar)
bar = waitbar(0,'Creating events\_train\_classif');
numel_events_train_classif = cellfun(@(ev) numel(ev.ts), cell_events_train_classif(:,1));
events_train_classif.ts = zeros(sum(numel_events_train_classif), 1, 'uint64');
events_train_classif.x = zeros(sum(numel_events_train_classif), 1, 'uint8');
events_train_classif.y = zeros(sum(numel_events_train_classif), 1, 'uint8');
events_train_classif.p = false(sum(numel_events_train_classif), 1);
borne_inf = 0;
for ind = 1:size(cell_events_train_classif,1)
  events_train_classif.ts(borne_inf+(1:numel_events_train_classif(ind))) = uint64(cell_events_train_classif{ind,1}.ts) + offset;
  events_train_classif.x(borne_inf+(1:numel_events_train_classif(ind))) = cell_events_train_classif{ind,1}.x;
  events_train_classif.y(borne_inf+(1:numel_events_train_classif(ind))) = cell_events_train_classif{ind,1}.y;
  events_train_classif.p(borne_inf+(1:numel_events_train_classif(ind))) = cell_events_train_classif{ind,1}.p;
  borne_inf = borne_inf + numel_events_train_classif(ind);
  last_offset = write_event2D_64bit_ts(cell_events_train_classif{ind,1}, ...
    fullfile(path_data,'events_train_classif.dat'), 'a', offset);
  label_train{ind,1} = {offset};
  label_train{ind,2} = {last_offset};
  label_train{ind,3} = cell_events_train_classif{ind,2};
  offset = last_offset + offset_interval;
  if mod(ind,size(cell_events_train_classif,1)/100) == 0
    waitbar(ind/size(cell_events_train_classif,1), bar);
  end
end
delete(bar)
bar = waitbar(0,'Creating events\_test\_classif');
numel_events_test_classif = cellfun(@(ev) numel(ev.ts), cell_events_test(:,1));
events_test_classif.ts = zeros(sum(numel_events_test_classif), 1, 'uint64');
events_test_classif.x = zeros(sum(numel_events_test_classif), 1, 'uint8');
events_test_classif.y = zeros(sum(numel_events_test_classif), 1, 'uint8');
events_test_classif.p = false(sum(numel_events_test_classif), 1);
borne_inf = 0;
for ind = 1:size(cell_events_test,1)
  events_test_classif.ts(borne_inf+(1:numel_events_test_classif(ind))) = uint64(cell_events_test{ind,1}.ts) + offset;
  events_test_classif.x(borne_inf+(1:numel_events_test_classif(ind))) = cell_events_test{ind,1}.x;
  events_test_classif.y(borne_inf+(1:numel_events_test_classif(ind))) = cell_events_test{ind,1}.y;
  events_test_classif.p(borne_inf+(1:numel_events_test_classif(ind))) = cell_events_test{ind,1}.p;
  borne_inf = borne_inf + numel_events_test_classif(ind);
  last_offset = write_event2D_64bit_ts(cell_events_test{ind,1}, ...
    fullfile(path_data,'events_test_classif.dat'), 'a', offset);
  label_test{ind,1} = {offset};
  label_test{ind,2} = {last_offset};
  label_test{ind,3} = cell_events_test{ind,2};
  offset = last_offset + offset_interval;
  if mod(ind,size(cell_events_test,1)/100) == 0
    waitbar(ind/size(cell_events_test,1), bar);
  end
end
delete(bar)
