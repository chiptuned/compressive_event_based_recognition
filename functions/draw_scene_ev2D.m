function [] = draw_scene_ev2D(ev, tau, nb_us_per_frame, windowsize)
% draw_scene_ev2D(events_train_hots, 40000, 30000, [35,35])

framerate = 10;
if ~exist('nb_us_per_frame', 'var')
  nb_us_per_frame = 100000;
end
if ~exist('tau', 'var')
  tau = nb_us_per_frame;
end
if ~exist('windowsize', 'var')
  windowsize = [304,240];
end

nbPols = numel(unique(ev.p));
nb_frames = double(floor(ev.ts(end)/nb_us_per_frame)+1);
ts_frames = linspace(0, (nb_frames-1)*nb_us_per_frame, nb_frames);

curr_frame = 1;
lastEvents = -inf*ones(windowsize(1)*nbPols, windowsize(2));
figure;
h_img = imagesc(zeros(size(lastEvents))', [0 1]);
colorbar
for idx_ev = 1:numel(ev.ts)
  while ev.ts(idx_ev) > ts_frames(curr_frame)
    h_img.CData = exp(-(ts_frames(curr_frame)-lastEvents)/tau)';
    drawnow;
    if curr_frame ~= nb_frames
      curr_frame = curr_frame + 1;
    else
      break;
    end
  end
  lastEvents(ev.p(idx_ev)*windowsize(1)+(ev.x(idx_ev)+1), ev.y(idx_ev)+1) ...
    = ev.ts(idx_ev);
end
