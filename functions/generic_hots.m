function [varargout] = generic_hots(path_data, params, events_train_hots, events_train, events_test)
% generic_hots(path, params, events_train, events_test) perform hots for events
% in events_test, training the centers with events_train.
%
% [centers] = generic_hots(...) return the centers.
%
% [centers, events] = generic_hots(...) return events performed by hots.
% [centers, events, events2] = generic_hots(...) return events performed by hots.
% events are for classif learning purposes. events2 are for testing purposes
%
%
% INPUTS : - path_data : string to the working directory of the processing_standard;
%          - params : struct containing all the parameters in order to compute hots;
%          - events_train, events_test : event structures
%
%
% Notes : 1) params structure must contain those fields :
%
%
%         2) There are 1 event structure allowed :
%           - Event1D : struct with fields 'ts, 'level', 'channel', and 'p' pointing
%             to vectors (1*N or N*1);


% Depends on write_label_data, write_audio_data (should fieldnames events to trigger
% functions according to events), prepare_hots_data, load_audio_data and read_centers

% NOTE : Integrity of events and labels should be checked

% NOTE : Should be in hots_generic folder (then change path_hots_generic)

% NOTE : Check if params and events are the same and files are generated, don't reload
% Maybe this feature should be in hots_generic -> hash of params and events_input
% in the centerfiles header

if isfield(events_train_hots,'level')
  filename_hots = 'hots1D';
elseif isfield(events_train_hots,'y')
  filename_hots = 'hots2D';
end

%path_hots_generic = '../_build/app/test';
path_hots_generic = '/home/vincent/idv/generichots/_build/app/test';

if ~exist(path_data, 'dir')
  mkdir(path_data)
end

if nargin == 2
  % Check if events_test, events_train, label_train, label_test exist
else
  % write_label_data(label_train, fullfile(path_data, 'labels_train_classif.txt'));
  % write_label_data(label_test, fullfile(path_data, 'labels_test_classif.txt'));

  file_ev_train_hots = fullfile(path_data, 'events_train_hots.dat');
  file_ev_train = fullfile(path_data, 'events_train_classif.dat');
  file_ev_test = fullfile(path_data, 'events_test_classif.dat');
  write_audio_data(events_train_hots, file_ev_train_hots);
  write_audio_data(events_train, file_ev_train);
  write_audio_data(events_test, file_ev_test);
end

command = ['cp -f ', fullfile(path_hots_generic, filename_hots), ' ', path_data];
system(command);

filename_hotsparams = fullfile(path_data, 'params.hotsnetwork');
write_hotsnetwork_file(params, filename_hotsparams);

tic;
fprintf('----     STARTING GENERIC HOTS     ----\n');
generic_hots_main = fullfile(path_data, filename_hots);
command = [generic_hots_main, ' ', filename_hotsparams];
system(command);
fprintf('---- END OF GENERIC HOTS EXECUTION ----\nHots : ');
toc;

if nargout > 3
  error(['Too many output arguments. Maximum should be 3 (centers,', ...
  ' events_train_classif, events_test_classif).'])
end

if nargout > 0
  centers = cell(1,params.nbLayers);
  if nargout > 1
  events = cell(1,params.nbLayers+1);
  events(1) = {load_audio_data(fullfile(path_data, ['events_train_classif.dat']))};
  end
  if nargout > 2
  events2 = cell(1,params.nbLayers+1);
  events2(1) = {load_audio_data(fullfile(path_data, ['events_test_classif.dat']))};
  end
  for ind = 1:params.nbLayers
    centers_file = fullfile(path_data, ['centersOfLayer', num2str(ind), '.txt']);
    centers(ind) = {read_centers(centers_file)};
    if nargout > 1
      events_file = fullfile(path_data, ['events_train_classif_outputOfLayer', num2str(ind), '.dat']);
      events(ind+1) = {load_audio_data(events_file)};
    end
    if nargout > 2
      events_file = fullfile(path_data, ['events_test_classif_outputOfLayer', num2str(ind), '.dat']);
      events2(ind+1) = {load_audio_data(events_file)};
    end
  end
  varargout{1} = centers;
  if nargout > 1
    varargout{2} = events;
  end
  if nargout > 2
    varargout{3} = events2;
  end
end
