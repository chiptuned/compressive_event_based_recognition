function [all_events_train, all_events_test] = get_events_from_N_MNIST(path_data, path_dataset)

%% Variables initialization
if ~exist('path_dataset', 'var')
  path_dataset = 'N-MNIST';
end

if ~exist('path_data', 'var')
  path_data = 'nmnist_data';
end
if exist(path_data, 'dir')
  rmdir(path_data, 's')
end

if ~exist(fullfile(path_dataset, 'Test'), 'dir') || ~exist(fullfile(path_dataset, 'Train'), 'dir')
  unzip(fullfile(path_dataset, 'Test.zip'), path_dataset);
  unzip(fullfile(path_dataset, 'Train.zip'), path_dataset);
end

%% Create events from N MNIST database

all_files_train = [];
all_labels_train = [];
all_files_test = [];
all_labels_test = [];
for ind_figure = 0:9
  curr_train_folder = [fullfile(path_dataset,'Train/'), num2str(ind_figure), '/'];
  curr_test_folder = [fullfile(path_dataset,'Test/'), num2str(ind_figure), '/'];
  dir_class_train = dir([curr_train_folder, '*.bin']);
  dir_class_test = dir([curr_test_folder, '*.bin']);
  all_files_train = [all_files_train; strcat(curr_train_folder, {dir_class_train.name}')];
  all_labels_train = [all_labels_train; ind_figure.*ones(size(dir_class_train))];
  all_files_test = [all_files_test; strcat(curr_test_folder, {dir_class_test.name}')];
  all_labels_test = [all_labels_test; ind_figure.*ones(size(dir_class_test))];
end

classes = unique(all_labels_train);
h = waitbar(0, 'Opening train events...');
all_events_train = cell(numel(all_labels_train), 3);

for ind = 1:numel(all_labels_train)
  eventData = fopen(all_files_train{ind});
  evtStream = fread(eventData);
  fclose(eventData);
  TD.x    = uint8(evtStream(1:5:end)+1); %pixel x address, with first pixel having index 1
  TD.y    = uint8(evtStream(2:5:end)+1); %pixel y address, with first pixel having index 1
  TD.p    = boolean(bitshift(evtStream(3:5:end), -7)); %polarity, 0 means off, 1 means on
  TD.ts   = (bitshift(bitand(evtStream(3:5:end), 127), 16)); %time in microseconds
  TD.ts   = TD.ts + bitshift(evtStream(4:5:end), 8);
  TD.ts   = uint32(TD.ts + evtStream(5:5:end));

  all_events_train(ind,1) = {TD};
  all_events_train(ind,2) = {find(classes==all_labels_train(ind))};
  all_events_train(ind,3) = {uint32(str2num(all_files_train{ind}(end-8:end-4)))};

  if mod(ind, round(numel(all_labels_train)/100)) == 0
    waitbar(ind/numel(all_labels_train), h);
  end
end
delete(h)

classes = unique(all_labels_test);
h = waitbar(0, 'Opening test events...');
all_events_test = cell(numel(all_labels_test), 3);

for ind = 1:numel(all_labels_test)
  eventData = fopen(all_files_test{ind});
  evtStream = fread(eventData);
  fclose(eventData);
  TD.x    = uint8(evtStream(1:5:end)+1); %pixel x address, with first pixel having index 1
  TD.y    = uint8(evtStream(2:5:end)+1); %pixel y address, with first pixel having index 1
  TD.p    = boolean(bitshift(evtStream(3:5:end), -7)); %polarity, 0 means off, 1 means on
  TD.ts   = (bitshift(bitand(evtStream(3:5:end), 127), 16)); %time in microseconds
  TD.ts   = TD.ts + bitshift(evtStream(4:5:end), 8);
  TD.ts   = uint32(TD.ts + evtStream(5:5:end));

  all_events_test(ind,1) = {TD};
  all_events_test(ind,2) = {find(classes==all_labels_test(ind))};
  all_events_test(ind,3) = {uint32(str2num(all_files_test{ind}(end-8:end-4)))};

  if mod(ind, round(numel(all_labels_test)/100)) == 0
    waitbar(ind/numel(all_labels_test), h);
  end
end
delete(h)

whos all_events_train
whos all_events_test
fprintf('Saving events...\n')
mkdir(path_data)
save(fullfile(path_data, 'all_events.mat'), 'all_events_train', 'all_events_test', '-v7.3')

rmdir(fullfile(path_dataset, 'Test'), 's')
rmdir(fullfile(path_dataset, 'Train'), 's')
