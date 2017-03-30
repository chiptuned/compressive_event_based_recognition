function [] = create_events_corpus(path_timit, ch, nb_levels)
% 1  'Make with one train/test file'
% 2  'Make train dat/labels with sx files'
% 3  'Make dat/label files for each sentence'
% 4  'Make train/test dat/labels with all corpus'
% 5  'Make train/test dat/labels with N individuals'
% 6  'Remove all dat and label files'
% 7  'Make train dat/labels with everything but sa with N individuals'
% 8  'Make train/test with only the train set, at a given ratio'

% For reproducibility
% rng(0)

if ~exist('path_timit','var')
  error('Need to specify a timit path.');
end
if ~exist('ch','var')
  ch = 1;
end
if ~exist('nb_levels', 'var')
  nb_levels = 400;
end

if ispc
    dirs = textscan(genpath(path_timit),'%s','Delimiter',';');
elseif isunix
    dirs = textscan(genpath(path_timit),'%s','Delimiter',':');
end

%% Finding audio directories
dirs = dirs{1};
nb_char_dirs = zeros(1, numel(dirs));
trainset = zeros(1, numel(dirs));
for ind = 1:numel(dirs)
    nb_char_dirs(ind) = length(dirs{ind});
end
nb_char_sound_dir = max(nb_char_dirs);
dirs(nb_char_sound_dir-1>nb_char_dirs) = [];

%% Delete old .dat/.label files
  if (ch == 1 || ch == 2 || ch == 4 || ch == 5 || ch == 7)
    delete([path_timit, '*.dat']);  
    delete([path_timit, '*.label']);
  elseif (ch == 3 || ch == 6)
    for ind = 1:numel(dirs)
      delete([dirs{ind}, filesep, '*.dat']);  
      delete([dirs{ind}, filesep, '*.label']);
    end
  end

%% Removing audio directories according to the choice
% sx, sa, etc
if (ch == 2)
    % Only sx files
  file_prefix = 'sx';
  nb_files = 5; % TIMIT is 5 sx files / pers.
elseif ch == 1
  file_prefix = 'sa1';
  nb_files = 1; % Only take one file.
elseif (ch == 7) || (ch == 4)
  file_prefix = '';
  nb_files = 8; % Only take one file.
else
  file_prefix = '';
  nb_files = 10; % TIMIT is 10 files / pers.
end

% train/test
if (ch == 2)
  testset = zeros(1, numel(dirs));
  for ind = 1:numel(dirs)
    testset(ind) = isempty(regexp(dirs{ind},'test','once'));
  end
  dirs(~testset) = [];
elseif (ch == 5) || (ch == 1) || (ch == 7)
  % Only n1 train and n2 test individuals
  testset = true(1, numel(dirs));
  cpt_test = 0;
  cpt_train = 0;
  max_test = 50;
  max_train = 20;

  if (ch == 1)
    max_test = 1;
    max_train = 1;
  end
  
  % Shuffuling dirs
  idx_dirs = randperm(numel(dirs));
  dirs = dirs(idx_dirs);

  for ind = 1:numel(dirs)
    if isempty(regexp(dirs{ind},'train','once'))
      cpt_test = cpt_test + 1;
      if cpt_test > max_test
        testset(ind) = false;
      end
    else
      cpt_train = cpt_train + 1;
      if cpt_train > max_train
        testset(ind) = false;
      end
    end
  end
  dirs(~testset) = [];
end



%% Event generation
if ((ch <= 5) || (ch == 7))
  full_filenames = cell(nb_files*numel(dirs),1);
  short_filenames = cell(nb_files*numel(dirs),1);
  for ind = 1:numel(dirs)
    files = dir([dirs{ind}, filesep, file_prefix, '*.wav']);
    filenames = {files.name}';
    if (ch == 7) || (ch == 4)
      % retirer les sa
      filenames(1:2) = [];
    end
    if (numel(filenames)~=nb_files)
      dirs{ind}
      filenames
      error('wtf is timit')
    end
    for ind2 = 1:numel(filenames)
      full_filenames(ind2+(ind-1)*nb_files) = cellstr([dirs{ind}, filesep, filenames{ind2}(1:end-4)]);
      short_filenames(ind2+(ind-1)*nb_files) = cellstr(full_filenames{ind2+(ind-1)*nb_files}(end-7-length(filenames{ind2}):end));
    end
  end

  bar = waitbar(0, short_filenames{1});

  nb_files = numel(full_filenames);

  fid = fopen([path_timit, 'files_used.txt'], 'w');
  for ind = 1:nb_files
    
    [events_file, fe] = convert_timit_to_event([full_filenames{ind}, '.wav'], nb_levels);
    labels_file = load_labels([full_filenames{ind}, '.phn'], fe);

    % Keeping trace of which files were used
    fprintf(fid,'%s\n',full_filenames{ind});
    

    if ((ch == 1) || (ch == 2) || (ch == 4) || (ch == 5) || (ch == 7))
      if short_filenames{ind}(1) == 't'
        filename_corpus = 'test';
        ind_corpus = 1;
      else
        filename_corpus = 'train';
        ind_corpus = 2;
      end
      filename_dat = [path_timit, filename_corpus, '.dat'];
      filename_label = [path_timit, filename_corpus, '.label'];
      if ind == 1
        last_event_offset = [0, 0];
        last_label_offset = [0, 0];
      else
      end
      offset = write_audio_data(events_file, filename_dat, 'a', last_event_offset(ind_corpus));
      offset = write_label_data(labels_file, filename_label, 'a', last_label_offset(ind_corpus));
      last_event_offset(ind_corpus) = offset + 10000000;
      last_label_offset(ind_corpus) = offset + 10000000;
    end

    if ch == 3
      write_audio_data(events_file, full_filenames{ind});
      write_label_data(labels_file, full_filenames{ind});
    end

    if ind == nb_files
      delete(bar)
    else 
      waitbar(ind/nb_files,bar,short_filenames{ind+1});
    end
  end
  fclose(fid);
end