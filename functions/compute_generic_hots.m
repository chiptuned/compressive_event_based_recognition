
function [] = compute_generic_hots(params, events_train_hots, events_train, events_test)
% generic_hots(path, params, events_train, events_test) perform hots for events
% in events_test, training the centers with events_train.
%
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
% functions according to events), prepare_hots_data

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

if ~exist(params.path_data, 'dir')
  mkdir(params.path_data)
end

if nargin == 2
  % Check if events_test, events_train, label_train, label_test exist
  % not compatible with field research (first lines), to know if its 1D or 2D
else
  % write_label_data(label_train, fullfile(path_data, 'labels_train_classif.txt'));
  % write_label_data(label_test, fullfile(path_data, 'labels_test_classif.txt'));
  params.eventsname = {'events_train_hots.dat', 'events_train_classif.dat', 'events_test_classif.dat'};
  file_ev_train_hots = fullfile(params.path_data, params.eventsname{1});
  file_ev_train = fullfile(params.path_data, params.eventsname{2});
  file_ev_test = fullfile(params.path_data, params.eventsname{3});
  write_audio_data(events_train_hots, file_ev_train_hots);
  write_audio_data(events_train, file_ev_train);
  write_audio_data(events_test, file_ev_test);
end

command = ['cp -f ', fullfile(path_hots_generic, filename_hots), ' ', params.path_data];
system(command);

filename_hotsparams = fullfile(params.path_data, 'params.hotsnetwork');
write_hotsnetwork_file(params, filename_hotsparams);

tic;
fprintf('----     STARTING GENERIC HOTS     ----\n');
generic_hots_main = fullfile(params.path_data, filename_hots);
command = [generic_hots_main, ' ', filename_hotsparams];
system(command);
fprintf('---- END OF GENERIC HOTS EXECUTION ----\nHots : ');
toc;
