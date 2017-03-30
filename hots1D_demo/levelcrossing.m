function [ events ] = levelcrossing( data, fs, nb_levels )
%Converting info into a uint16 format.
data = data/max(abs(data));
data = uint16(floor((0.5*(1+data))*2^16));

SAVG = 65536;
first_ = true;
last_level = 0;
old_ts = 0;
old_loc = 0;
ts = [];
val = [];
p = [];

for ind = 1:numel(data)
    ttmp = data(ind);
    loc = double(ttmp)*nb_levels/SAVG;
    if (loc <= 0)
        loc = 1;
    end
    time = round(1e6*ind/fs);
    cur_level = floor(loc);
    if (first_) 
        last_level = floor(loc);
        first_  = false;
    end
    
    if (cur_level > last_level) % On ev
        for (level = last_level+1:1:cur_level)
            ts_rect = old_ts+(level-old_loc)*(time-old_ts)/(loc-old_loc);
            ts = [ts;ts_rect];
            val = [val;level];
            p = [p;1];
            last_level = level;
        end
    elseif (cur_level < last_level) % Off ev
        for (level = last_level-1:-1:cur_level+1)
            ts_rect = old_ts+(level-old_loc)*(time-old_ts)/(loc-old_loc);
            ts = [ts;ts_rect];
            val = [val;level];
            p = [p;0];
            last_level = level;
        end
    end
    old_ts = time;
    old_loc = loc;
end
events = struct('ts',ts,'level', val, 'p',p);