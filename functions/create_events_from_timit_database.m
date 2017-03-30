function [] = create_events_from_timit_database(path_timit, ratios, nb_levels)
% INPUT : path_timit a string path to the timit database
% INPUT : ratios, a 3*1 vector for the ratios of hots_learning, sig_learning and
%   sig_test data to make events with. hots_learning and sig_learning are ratios
%   of the train database and the sum must be <= 1;
% INPUT : nb_levels the number of levels for levelcrossing

% For reproducibility
% rng(0)

if (~isempty(find(ratios < 0))) || ((ratios(1)+ratios(2)) > 1) || (ratios(3) > 1)
  error('derp ratio')
end

if ~exist('path_timit','var')
  error('Need to specify a timit path.');
end
if ~exist('nb_levels', 'var')
  nb_levels = 100;
end

%% Finding audio directories
if ispc
    dirs = textscan(genpath(path_timit),'%s','Delimiter',';');
elseif isunix
    dirs = textscan(genpath(path_timit),'%s','Delimiter',':');
end
dirs = dirs{1};
nb_char_dirs = zeros(1, numel(dirs));
for ind = 1:numel(dirs)
    nb_char_dirs(ind) = length(dirs{ind});
end
nb_char_sound_dir = max(nb_char_dirs);
dirs(nb_char_sound_dir-1>nb_char_dirs) = [];

% Finding their class (test or train dirs)
is_test_dir = zeros(1, numel(dirs));
for ind = 1:numel(dirs)
  if isempty(regexp(dirs{ind},'train','once'))
    is_test_dir(ind) = is_test_dir(ind) + 1;
  end
end

%% Delete old .dat/.label files
delete([path_timit, '*.dat']);
delete([path_timit, '*.label']);
for ind = 1:numel(dirs) % Should't be necessary
  delete([dirs{ind}, filesep, '*.dat']);
  delete([dirs{ind}, filesep, '*.label']);
end

nb_files = 8; % 10 - (sa1, sa2)
is_test_files = reshape(repmat(is_test_dir, nb_files, 1),1,[]);
full_filenames = cell(nb_files*numel(dirs),1);
short_filenames = cell(nb_files*numel(dirs),1);

for ind = 1:numel(dirs)
  files = dir([dirs{ind}, filesep, '*.wav']);
  filenames = {files.name}';
  % retirer les sa
  filenames(1:2) = [];
  if (numel(filenames)~=nb_files)
    dirs{ind}
    filenames
    error('derp timit dir')
  end
  for ind2 = 1:numel(filenames)
    full_filenames(ind2+(ind-1)*nb_files) = cellstr([dirs{ind}, filesep, filenames{ind2}(1:end-4)]);
    short_filenames(ind2+(ind-1)*nb_files) = cellstr(full_filenames{ind2+(ind-1)*nb_files}(end-7-length(filenames{ind2}):end));
  end
end

idx_filename = randperm(numel(full_filenames));
is_test_files = is_test_files(idx_filename);
full_filenames = full_filenames(idx_filename);
short_filenames = short_filenames(idx_filename);

nb_train_files = numel(find(is_test_files == 0));
nb_hots_learning_files = floor(nb_train_files*ratios(1));
nb_learning_files = floor(nb_train_files*ratios(2));
nb_test_files = floor(numel(find(is_test_files == 1))*ratios(3));

class_files = zeros(size(is_test_files));

class_files(find(is_test_files == 0, nb_hots_learning_files + nb_learning_files)) = 2;
class_files(find(is_test_files == 0, nb_hots_learning_files)) = 1;
class_files(find(is_test_files, nb_test_files)) = 3;

idx_files_to_event = find(class_files);
total_files_to_event = numel(idx_files_to_event);

bar = waitbar(0, short_filenames{idx_files_to_event(1)});
fid = fopen([path_timit, 'files_used.txt'], 'w');

for ind = 1:total_files_to_event
  if ind == 1
    last_event_offset = [0, 0, 0];
  end

  idx_file = idx_files_to_event(ind);
  [events, fe] = convert_timit_to_event([full_filenames{idx_file}, '.wav'], nb_levels, 'cochlea');
  labels = load_labels([full_filenames{idx_file}, '.phn'], fe);

  labels{1}(1) = 0;
  if events.ts(end) > labels{2}(end)
    labels{2}(end) = events.ts(end);
  end

  % Keeping trace of which files were used
  fprintf(fid,'%d %d %s\n', ...
    round(last_event_offset(class_files(idx_file))), ...
    round(last_event_offset(class_files(idx_file)) + labels{2}(end)), ...
    full_filenames{idx_file});

  switch class_files(idx_file)
    case 1
      filename_dat = [path_timit, 'train_hots.dat'];
    case 2
      filename_dat = [path_timit, 'train_classif.dat'];
      filename_label = [path_timit, 'train_classif.label'];
    case 3
      filename_dat = [path_timit, 'test_classif.dat'];
      filename_label = [path_timit, 'test_classif.label'];
  end

  offset_event = write_audio_data(events, filename_dat, 'a', last_event_offset(class_files(idx_file)));
  if class_files(idx_file) > 1
    offset_label = write_label_data(labels, filename_label, 'a', last_event_offset(class_files(idx_file)), 1);
    if offset_event > offset_label
      fprintf('events end : %d\n',events.ts(end));
      fprintf('labels end : %d\n',labels{2}(end));
      fprintf('offset is : %d\n',last_event_offset(class_files(idx_file)));
      offset_event
      offset_label
      error('wttttfffffffff')
    end
  end
  last_event_offset(class_files(idx_file)) = offset_event + 10000000;
  if (ind == total_files_to_event)
    delete(bar);
  else
    waitbar(ind/total_files_to_event,bar,short_filenames{idx_files_to_event(ind+1)});
  end
end
fclose(fid);

labels_train = load_labels([path_timit, 'train_classif.label']);
labels_test = load_labels([path_timit, 'test_classif.label']);
