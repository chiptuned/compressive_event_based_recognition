function [ events, levels ] = levelcrossing2( data, fs, nb_levels, type )
% L'interet de cette méthode est d'introduire les bandes de niveau et les
% croisements de level "a la main", et actuellement ce code n'est pas
% optimisé. Deux types de croisement son implémentés, lin et log pour la
% musique.

data = uint16(floor((0.5*(1+double(data)/max(abs(double(data)))))*2^16));

SAVG = 2^16; % because data is in a uint16;

if ~exist('type', 'var')
    type = 'lin';
end
if strcmp(type, 'lin')
    levels = linspace(0,1, nb_levels+1)*SAVG;
    bands = (round(levels(1:end-1)));
elseif strcmp(type, '-+log')
    levels = 10 .^ linspace(log10(1),log10(SAVG/2+1), (nb_levels+1)/2);
    levels = unique(round(levels(2:end-1)));
    bands = uint16([0, -levels(end:-1:1)+SAVG/2, SAVG/2, levels+SAVG/2]);
elseif strcmp(type, 'log')
    levels = 10 .^ linspace(log10(1),log10(SAVG+1), (nb_levels+2));
    levels = unique(round(levels(2:end-1)));
    bands = uint16([0, levels(1:end)]);
end
levels = bands(2:end);

bands
levels

plot(0:numel(levels)-1,levels, '*')
pause

ts = [];
val = [];
p = [];
curr_band = numel(find(data(1)>=bands));

if curr_band == 1
    last_level = 1;
elseif curr_band == numel(bands)
    last_level = curr_band-1;
else
    if double(data(1))-double(levels(curr_band-1)) < ...
        double(levels(curr_band)) - double(data(1))
        last_level = curr_band-1;
    else
        last_level = curr_band;
    end
end

t_interval = 1e6/fs;
last_ts = 0;
for ind = 2:numel(data)
    curr_band = numel(find(data(ind)>=bands));
    %pause
    if ((curr_band > (last_level+1)) || (curr_band < (last_level-1)))
        if (curr_band > (last_level+1))
            pol = 1;
            if curr_band == numel(bands)
                event_interlvl = levels(last_level+1:end);
            else
                event_interlvl = levels(last_level+1:curr_band-1);
            end
            a = double(data(ind)-data(ind-1))/t_interval;
        else
            pol = 0;
            if curr_band == numel(bands)
                event_interlvl = levels(last_level-1:-1:1);
            else
                event_interlvl = levels(last_level-1:-1:curr_band);
            end
            a = double(data(ind-1)-data(ind))/t_interval;
        end
        ts_prec = 1e6*(ind-1)/fs;
        for ind2 = 1:numel(event_interlvl)
            if pol
                val_ev = last_level+ind2;
                ts_ev = round(ts_prec + double(levels(val_ev)-data(ind-1))/a);
            else
                val_ev = last_level-ind2;
                ts_ev = round(ts_prec + double(data(ind-1)-levels(val_ev))/a);
            end

            if ts_ev ~= last_ts
                p = [p, pol];
                val = [val, val_ev];
                ts = [ts, ts_ev];
                last_ts = ts_ev;
            end
        end
        last_level = val_ev;
    end
end
events = struct('ts',ts,'level', val, 'p',p);
