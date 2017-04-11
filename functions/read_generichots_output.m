function [varargout] = read_generichots_output(params)

% [centers] = read_generichots_output(path, params) return the centers.
%
% [centers, events] = read_generichots_output(path, params) return events
% performed by hots.
% [centers, events, events2] = read_generichots_output(path, params) return
% events performed by hots.
% events are for classif learning purposes. events2 are for testing purposes
%
% INPUTS : - path_data : string to the working directory of the processing_standard;
%          - params : struct containing all the parameters in order to compute hots;

% NOTE : Integrity of events and labels should be checked

% NOTE : Should be in hots_generic folder (then change path_hots_generic)

% NOTE : Check if params and events are the same and files are generated, don't reload
% Maybe this feature should be in hots_generic -> hash of params and events_input
% in the centerfiles header

if nargout > 3
  error(['Too many output arguments. Maximum should be 3 (centers,', ...
  ' events_train_classif, events_test_classif).'])
end

if nargout > 0
  centers = cell(1,params.nbLayers);
  if nargout > 1
  events = cell(1,params.nbLayers+1);
  events(1) = {load_audio_data(fullfile(params.path_data, ['events_train_classif.dat']))};
  end
  if nargout > 2
  events2 = cell(1,params.nbLayers+1);
  events2(1) = {load_audio_data(fullfile(params.path_data, ['events_test_classif.dat']))};
  end
  for ind = 1:params.nbLayers
    centers_file = fullfile(params.path_data, ['centersOfLayer', num2str(ind), '.txt']);
    centers(ind) = {read_centers(centers_file, params)};
    if nargout > 1
      events_file = fullfile(params.path_data, ['events_train_classif_outputOfLayer', num2str(ind), '.dat']);
      events(ind+1) = {load_audio_data(events_file)};
    end
    if nargout > 2
      events_file = fullfile(params.path_data, ['events_test_classif_outputOfLayer', num2str(ind), '.dat']);
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
