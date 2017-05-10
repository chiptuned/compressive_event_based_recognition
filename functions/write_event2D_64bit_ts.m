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
yshift=8; % bits to shift y to right
pshift=15; % bits to shift p to right
paddingshift = 16;

addr = bitshift(ev.x,xshift) + ...
  bitshift(ev.y,yshift) + ...
  bitshift(uint8(ev.p),pshift) + bitshift(0, paddingshift);

ev.ts = uint64(ev.ts)+offset;
fwrite(f,[ev.ts, bitshift(ev.ts,-32), addr]','uint32');
fclose(f);
last_event_ts = ev.ts(end);
