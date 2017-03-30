function events = read_events(filename, type_if_raw_64bit_events)

% Open filename, get first line
% If its Eventstream, rewind and read ES according to byte 14.
% it its %, there is an header, read it according to the 2 first bytes of second line
% else, read it according to default 64bit type.

% if dat, if header, type = type_seen, else type = type_if_raw_64bit_events

fid = open(filename, 'r')
firstline = fgetl(fid);
if firstline(1) = '%'
  % FIXME
  %get second line, first byte (hex value)
  %it's its type
  fclose(fid);
  events = error('Reading headers Not implemented yet')
elseif strcmp(firstline(1:11), 'EventStream')
  fclose(fid);
  events = read_EventStream(filename)
else
  fclose(fid);
  if ~exist('type_if_raw_64bit_events', 'var')
    type_if_raw_64bit_events = 'Event2d'
  end
  events = read_kAER(filename, type_if_raw_64bit_events)
end

function events = read_EventStream(filename)
  % FIXME
  events = error('Not implemented yet')
end

function events = read_kAER(filename, type)
  % NOTE : Assuming the type is the correct type of the file
  % FIXME
  events = error('reading raw not implemented yet')
end
