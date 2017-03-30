function td_data = read_event_dat(filename, type)
% We want to be compatible with kAER
% Event types :
%   0 -> Event2d
%  42 -> Event1d
%  43 -> EventHots2d

ev = load_addr_data(filename);
if ~isfield(ev, 'type')
  ev.type = 0;
end

if ~exist('type', 'var')
  type = ev.type;
end

if type = 0
  % Event2d
  td_data = convert_addr_to_2D(ev);
elseif type = 42
  % Event1d
  td_data = convert_addr_to_1D(ev);
end

function converted_data = convert_addr_to_1D(td_data)

lvlmask = hex2dec('0000FFFF'); % level, 16 bits
channelmask = hex2dec('000F0000'); % Channel (ear), 4 bits
polmask = hex2dec('FFF00000'); % polarity, 12 bits

% Maybe use Hamming weight instead?
lvlshift=0; % bits to shift x to right
channelshift=16; % bits to shift y to right
polshift=20; % bits to shift p to right

converted_data.ts = td_data.ts;
converted_data.level=double(bitshift(bitand(td_data.addr,lvlmask),-lvlshift));
converted_data.channel=double(bitshift(bitand(td_data.addr,channelmask),-channelshift));
converted_data.p=double(bitshift(bitand(td_data.addr,polmask),-polshift));
end

function converted_data = convert_addr_to_2D(td_data)

xmask = hex2dec('000000FF'); % x, 8 bits
ymask = hex2dec('0000EF00'); % y, 7 bits
polmask = hex2dec('00001000'); % polarity, 1 bit

% Maybe use Hamming weight instead?
xshift=0; % bits to shift x to right
yshift=8; % bits to shift y to right
polshift=15; % bits to shift p to right

converted_data.ts = td_data.ts;
converted_data.x=double(bitshift(bitand(td_data.addr,xmask),-xshift));
converted_data.y=double(bitshift(bitand(td_data.addr,ymask),-yshift));
converted_data.p=double(bitshift(bitand(td_data.addr,polmask),-polshift));
end

function converted_data = convert_addr_to_HOTS2D(td_data)

xmask = hex2dec('000000FF'); % x, 8 bits
ymask = hex2dec('0000EF00'); % y, 7 bits
polmask = hex2dec('FFFF1000'); % polarity, 17 bit

% Maybe use Hamming weight instead?
xshift=0; % bits to shift x to right
yshift=8; % bits to shift y to right
polshift=15; % bits to shift p to right

converted_data.ts = td_data.ts;
converted_data.x=double(bitshift(bitand(td_data.addr,xmask),-xshift));
converted_data.y=double(bitshift(bitand(td_data.addr,ymask),-yshift));
converted_data.p=double(bitshift(bitand(td_data.addr,polmask),-polshift));
end
