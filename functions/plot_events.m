function [fig_handle] = plot_events(events, colors, axis_lim)

max_ts_events = 1e8;
if events.ts(end) > max_ts_events
  % not tested
  idx_good_ev = find(events.ts < max_ts_events);
  max_events = idx_good_ev(end);

  events.ts = events.ts(1:max_events);
  events.level = events.level(1:max_events);
  events.channel = events.channel(1:max_events);
  events.p = events.p(1:max_events);
end

nb_pols = numel(unique(events.p));
list_pol = unique(events.p);

if ~exist('colors', 'var')
    colors = distinguishable_colors(nb_pols);
end


cpt = 0;

for ind = 1:nb_pols
  cpt = cpt + 1;
  hold on;
  plot(events.ts(events.p==list_pol(ind)),events.level(events.p==list_pol(ind)), ...
      '.', 'MarkerEdgeColor', colors(ind,:));

end
hold off;

legendstr = cell(nb_pols,1);
for ind2 = 1:nb_pols
    if iscell(list_pol(ind2))
        legendstr{ind2} = list_pol(ind2);
    else
        legendstr{ind2} = num2str(list_pol(ind2));
    end
end

if exist('axis_lim', 'var')
  axis(axis_lim)
end

% if nb_pols == 2
%   legend({'OFF', 'ON'});
% elseif nb_pols <= 16
%   legend(legendstr,'Location', 'eastoutside', 'Orientation','vertical');
% end

hold off;
xlabel('Time in microseconds')
ylabel('Level')
if isfield(events,'layer')
  title(['Output of layer ', num2str(events.layer)])
end
drawnow;
