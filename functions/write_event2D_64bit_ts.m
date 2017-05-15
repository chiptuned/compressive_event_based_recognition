function [last_event_ts] = write_event2D_64bit_ts(ev, filename, type, offset)
if ~exist('type', 'var') || ~exist(filename, 'file')
  type = 'w';
end

f = fopen(filename, type);

if type == 'w'
%   header = '% Data file containing Event2d events.';
%   fprintf(f, '%s\n', header);
%
%   fwrite(f,0,'char');
%   fwrite(f,8,'char');
end

if ~exist('offset', 'var')
    offset = 0;
end

xshift=0; % bits to shift x to right
yshift=9; % bits to shift y to right
pshift=17; % bits to shift p to right
paddingshift = 18;

addr = bitshift(uint32(ev.x),xshift) + ...
  bitshift(uint32(ev.y),yshift) + ...
  bitshift(uint32(ev.p),pshift) + bitshift(0, paddingshift);

ev.ts = uint64(ev.ts)+offset;
fwrite(f,[mod(ev.ts, 2^32), bitshift(ev.ts,-32), addr]','uint32','l');
fclose(f);
last_event_ts = ev.ts(end);
