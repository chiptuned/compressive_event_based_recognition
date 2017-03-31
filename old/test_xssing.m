clearvars;
close all;

[x, fs] = audioread('sx127.wav');
data = uint16(floor((0.5*(1+x/max(abs(x))))*2^16));
t = (1:numel(x))*1e6/fs;

%% linear xssing
nb_levels = 100;
events_lin = levelcrossing( x, fs, nb_levels);
[events_log, levels_log] = levelcrossing2( x, fs, nb_levels, 'log');


%% aff
figure;

plot(t,double(data)*nb_levels/2^16, '.-b');
hold on;
plot(events_lin.ts,events_lin.level, '*r');
plot(events_log.ts,double(levels_log(events_log.level))*nb_levels/2^16, '*m')
%axis([3.7186e+05 4.5504e+05 -0.647 0.647]);
legend({num2str(numel(x)),num2str(numel(events_lin.ts)),num2str(numel(events_log.ts))})