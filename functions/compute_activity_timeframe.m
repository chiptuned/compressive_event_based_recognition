function [activity_events] = compute_activity_timeframe(events, time_interval)

activity_events = events;
events_buff = [];
for ind = 1:numel(events.ts)
  events_buff = [events_buff, events.ts(ind)];
  while events_buff(1) < (events.ts(ind)-time_interval)
    events_buff = events_buff(2:end);
  end
  activity_events.p(ind) = numel(events_buff);
end

figure;
sbp1 = subplot(311)
plot_events(events, labels)
sbp2 = subplot(312)
% colors = hot(max(activity_events.p))
% plot_events(activity_events, colors)
plot(activity_events.ts(activity_events.ts<1e8), activity_events.p(activity_events.ts<1e8))
sbp3 = subplot(313)
% events_zero.ts = 0:500:labels{2}(end);
% events_zero.level = floor(nb_levels_crossing/2)*ones(size(events_zero.ts));
% events_zero.channel = events_zero.level;
% events_zero.p = events_zero.level;
% plot_events_labelcolor(events_zero, labels, classes_phon)
linkaxes([sbp1, sbp2, sbp3], 'x');
