function varargout = events_definition(varargin)
%EVENTS_DEFINITION Events definitions database.
%   DEF = EVENTS_DEFINITION() get the events definitions in the database inside
%   this function. The resulting array is a N*6 cell array, containing N event
%   definitions.
%
%   DEF = EVENTS_DEFINITION(E) get the event definition of E. The resulting
%   array is a 1*6 cell array containing its definition.
%   [DEF, E] = EVENTS_DEFINITION(E) return E with an updated field 'name'.
%
%   New definitions are set in this function. They must be added at the end
%   of the cell array to not break the function.
%
%   An event definition must be an 1*3 cell array
%   - First cell should be its name. (character vector)
%   - Second cell the fields names. If padding, add an empty string. (cell array
%     of character vector)
%   - Third cell the type. (cell array of character vector)
%   - Fourth cell the size for each field in the same index. (uint vector)
%   - Fifth cell the identifier of the event in its framework. (uint)
%   - Sixth cell the framework the events are attached to. (character vector)
%
%   See also READ_EVENTS, WRITE_EVENTS.
%
%   Notes : - To read/write event from kAER, it's very straightforward, fields
%   are packed in a c++ class/struct, according to their sizes, with
%   __attribute__((__packed__)). They can be casted in (char* buffer) vars.
%
%           - To read/write event from EventStream, a state machine must be
%   implemented. See https://github.com/neuromorphic-paris/eventStream for more.

if nargin == 1
  events = varargin{1};
elseif nargin > 1
  error('nargin must be < 2');
end

if (nargout > 2)
  error('nargout must be < 2')
end

% FIXME : read in events.txt instead
ev_types = [ ...
    % Event 2D from kAER, identifier 0;
    % NOTE : original implementation in kAER have p as an unsigned int.
    {   'Event2d', ...
        {'ts','x','y','p', ''}, ...
        {'unsigned','unsigned','unsigned','boolean', 'unsigned'}, ...
        [32, 9, 8, 1, 14], ...
        [0], ...
        {'kAER'} ...
    }; ...
    % Event Addr from kAER, identifier 5;
    {   'EventAddr', ...
        {'ts','addr'}, ...
        {'unsigned','unsigned'}, ...
        [32, 32], ...
        [5], ...
        {'kAER'} ...
    }; ...
    % Event 1D, kAER style. With channel (ear, not used yet)
    {   'Event1d', ...
        {'ts','level','channel','pol'}, ...
        {'unsigned','unsigned','unsigned','unsigned'}, ...
        [32, 16, 4, 12], ...
        [6], ...
        {'kAER'} ...
    }; ...
    % Event Hots2D, kAER style
    {   'EventHots2d', ...
        {'ts','x','y','pol'}, ...
        {'unsigned','unsigned','unsigned','unsigned'}, ...
        [32, 9, 8, 15], ...
        [7], ...
        {'kAER'} ...
    }; ...
    % ATIS events, ES style;
    {   'ATIS_events', ...
        {'ts','x','y','isThresholdCrossing','pol'}, ...
        {'unsigned','unsigned','unsigned','unsigned','unsigned'}, ...
        [64, 9, 8, 1, 1], ...
        [42], ...
        {'EventStream'} ...
    } ...
];



for ind = 1:size(ev_types,1)
  if (numel(unique([numel(ev_types{ind,2}), numel(ev_types{ind,3}), numel(ev_types{ind,4})])) ~= 1)
    ev_types{ind,2}
    numel(ev_types{ind,2})
    ev_types{ind,3}
    numel(ev_types{ind,3})
    ev_types{ind,4}
    numel(ev_types{ind,4})
    msg = ['Event Definition of ',ev_types{ind,1},' is not valid, because name, ' ...
      'format and size must have the same number of elements.'];
    error(msg);
  end
end

for ind = 1:size(ev_types,1)
  if strcmp(ev_types{ind,6}, 'kAER')
    if mod(sum(ev_types{ind,4}),8) ~= 0
      ev_types{ind,4}
      msg = ['Event Definition of ',ev_types{ind,1},' is not valid, because ' ...
        'the sum of all size must be a multiple of 8 (byte)'];
      error(msg);
    end
  end
end

res = 0;
if exist('events', 'var')
  if ~isstruct(events)
    if isempty(inputname(1))
      ev_name = '';
    else
      ev_name = [' (here, ', inputname(1),')'];
    end
    error(['Events', ev_name, ' must be structures.'])
  end
  if isfield(events, 'name')
    % If we have a name, find the definition.
    for ind = 1:size(ev_types,1)
      if strcmp(events.name, ev_types{ind,1})
        res = ind;
        break;
      end
    end
  else
    if nargout < 2
      % Not assigning the event with a updated name, so display a warning message.
      if isempty(inputname(1))
        ev_name = '';
      else
        ev_name = [' (here, ', inputname(1),')'];
      end
      warning(['Events', ev_name, ' should have a name field.']);
    end
    fn = fieldnames(events);
    for ind = 1:size(ev_types,1)
      if numel(fn) == numel(ev_types{ind,2})
        if isempty(find(ismember(fn, ev_types{ind,2}) == 0))
          if res ~= 0
            if strcmp(ev_types{res,1},'EventHots2d')
              % If it's EventHots2d, then it was matched with Event2d, we can
              % discriminate it by checking is pol is an uint or bool.
            else
              warning(['Found multiple correspondance of event types from', ...
              ' fieldnames. Assign to the last correct definition...'])
              % NOTE : Else, we could check the maximum size storing the data of
              % the event, and assign to the 'smallest' definition regarding
              % data size.
            end
          end
          res = ind;
        end
      end
    end
  end
  if res == 0
    error(['404 : Event definition of struct ',inputname(1), ' not found.', ...
    ' Please check your events, or add a relevant definition for them', ...
    ' in this function.']);
  else
    varargout{1} = ev_types(res,:);
    if nargout == 2
      events.name = ev_types{res,1};
      varargout{2} = events;
    end
  end
else
  varargout{1} = ev_types;
end
