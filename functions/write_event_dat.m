function [last_event_ts] = write_event_dat(ev, filename, type, offset)
if ~exist('type', 'var') || ~exist(filename, 'file')
  type = 'w';
end

f = fopen(filename, type);

if ~exist('offset', 'var')
    offset = 0;
end

if isfield(ev, 'level')
  if type == 'w'
  %   header = '% Data file containing EventAudio1d events.';
  %   fprintf(f, '%s\n', header);
  %
  %   fwrite(f,42,'char');
  %   fwrite(f,8,'char');
  end
  lvlshift=0; % bits to shift x to right
  channelshift=16; % bits to shift y to right
  polshift=20; % bits to shift p to right

  addr = bitshift(ev.level,lvlshift) + ...
    bitshift(ev.channel,channelshift) + ...
    bitshift(ev.p,polshift);
elseif isfield(ev, 'y')
  if type == 'w'
  %   header = '% Data file containing Event2d events.';
  %   fprintf(f, '%s\n', header);
  %
  %   fwrite(f,0,'char');
  %   fwrite(f,8,'char');
  end
  xshift=0; % bits to shift x to right
  yshift=8; % bits to shift y to right
  pshift=15; % bits to shift p to right
  paddingshift = 16;

  addr = bitshift(ev.x,xshift) + ...
    bitshift(ev.y,yshift) + ...
    bitshift(ev.p,pshift) + bitshift(0, paddingshift);
end

if type == 'w'
%   header = '% Data file containing EventAudio1d events.';
%   fprintf(f, '%s\n', header);
%
%   fwrite(f,42,'char');
%   fwrite(f,8,'char');
end

list_ts_addr = [ev.ts+offset, addr]';
fwrite(f,list_ts_addr,'uint32');
fclose(f);
last_event_ts = ev.ts(end)+offset;
