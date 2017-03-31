close all;
clearvars;
filename_audio = 'sx127.wav'; % Beware : NIST-formatted (sphere)
[audio_vect, fs] = audioread(filename_audio,'native');

time_vect = (1:numel(audio_vect))/fs;
plot(time_vect, audio_vect);
xlabel('Time in seconds')
max_val = max(abs(audio_vect)) % centering the plot
axis([time_vect(1), time_vect(end), -2*max_val, 2*max_val])
title(['Audio extracted from ', filename_audio]);