function [] = listen_audio(events)

fe = 44100;
events.ts = events.ts - events.ts(1);
%events.level = events.level - 25;
nb_ech = ceil(events.ts(end)*fe/1e6);
x = zeros(1,nb_ech);
cpt_ech = 1;
period = 1e6/fe;
x(1) = events.level(1);
for ind = 2:numel(events.ts)
  while events.ts(ind) > (cpt_ech*period)
    % fais l'interpolation sur les derniers events
    x1 = events.ts(ind-1);
    x2 = events.ts(ind);
    
    y1 = events.level(ind-1);
    y2 = events.level(ind);

    a = (y2-y1)/(x2-x1);
    b = ((x2*y1)-(x1*y2))/(x2-x1);
    curr_x = (cpt_ech*period);
    val = a*curr_x+b;
    x(cpt_ech+1) = val;
    cpt_ech = cpt_ech + 1;
    %pause
  end
end
x = (x/25)-1;
sound(x,fe)