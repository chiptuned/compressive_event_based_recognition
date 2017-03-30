function [] = write_event2D(ev, filename)
% INPUT : ev struct with fields ts x y p.
f = fopen(filename, type);

header = '% Data file containing Event2d events.'; % header
fprintf(f, '%s\n', header);

fwrite(f,0,'char'); % events2d type 0
fwrite(f,8,'char'); % event2d sur 64bits


xshift=0; % bits to shift x to right
yshift=8; % bits to shift y to right
pshift=15; % bits to shift p to right
paddingshift = 16;

addr = bitshift(ev.x,xshift) + ...
  bitshift(ev.y,yshift) + ...
  bitshift(ev.p,pshift) + bitshift(0, paddingshift);

list_ts_addr = [ev.ts, addr]';
fwrite(f,list_ts_addr,'uint32');
fclose(f);
