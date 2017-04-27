function [last_event_ts] = write_audio_data(ev, filename, type, audio_offset)
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

if ~exist('audio_offset', 'var')
    audio_offset = 0;
end

lvlshift=0; % bits to shift x to right
channelshift=16; % bits to shift y to right
polshift=20; % bits to shift p to right

if isfield(ev, 'channel')
addr = bitshift(ev.level,lvlshift) + ...
  bitshift(ev.channel,channelshift) + ...
  bitshift(ev.p,polshift);
else
  addr = bitshift(ev.level,lvlshift) + ...
    bitshift(ev.p,polshift);
end
%list_ts_addr = [floor((ev.ts+audio_offset)/(2^32)), mod((ev.ts+audio_offset),2^32), addr]';
%fwrite(f,list_ts_addr,'uint32');
for ind = 1:numel(ev.ts)
  fwrite(f,ev.ts(ind)+audio_offset,'uint64');
  fwrite(f,addr(ind),'uint32');
end
fclose(f);
last_event_ts = ev.ts(end)+audio_offset;
