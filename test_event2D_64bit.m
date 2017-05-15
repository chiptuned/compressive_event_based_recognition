clearvars;
close all;

addpath('functions')
filename_test = 'test.dat';
nb_ev = 10;

ev.ts = uint64(randi(2^40,nb_ev,1));
ev.ts = sort(ev.ts, 'ascend');
ev.x = uint8(randi(2^6,nb_ev,1));
ev.y = uint8(randi(2^6,nb_ev,1));
ev.p = boolean(randi(2,nb_ev,1)-1);

write_event2D_64bit_ts(ev, filename_test);
new_ev = load_event2D_64bit_ts(filename_test);

ev.ts;
new_ev.ts;
isequal(ev, new_ev)
