function [fig_handle] = plot_events_labelcolor(events, labels, classes_phon)

max_ts_events = 1e8;
if events.ts(end) > max_ts_events
  % not tested
  idx_good_ev = find(events.ts < max_ts_events);
  max_events = idx_good_ev(end);

  events.ts = events.ts(1:max_events);
  events.level = events.level(1:max_events);
  events.channel = events.channel(1:max_events);
  events.p = events.p(1:max_events);

  ts_maxevent = events.ts(max_events);
  label_idx = find(labels{1}<ts_maxevent);
  labels{1} = labels{1}(label_idx);
  labels{2} = labels{2}(label_idx);
  labels{2}(end) = ts_maxevent;
  labels{3} = labels{3}(label_idx);

end

list_pol = unique(labels{3});
nb_pols = numel(list_pol);

colors = distinguishable_colors(nb_pols);

cpt = 0;
legendstr = {};
cpt_label = 0;

for ind = 1:numel(labels{1})
  cpt = cpt + 1;

  curr_label = [];
  for ind2 = 1:nb_pols
    if (list_pol(ind2) == labels{3}(ind))
      curr_label = ind2;
      break;
    end
  end

  hold on;
  good_ev = (events.ts>=labels{1}(ind)) .* (events.ts<labels{2}(ind));
  good_ev = find(good_ev);
  if ~isempty(good_ev)
    cpt_label = cpt_label+1;
    plot(events.ts(good_ev),events.level(good_ev), ...
        '*', 'MarkerEdgeColor', colors(ind2,:));
    if exist('classes_phon', 'var')
      phonema = strrep(classes_phon{labels{3}(ind)},'#','\#');
      txt = ['$$\downarrow ', phonema, '$$'];
      text(events.ts(good_ev(1)),events.level(good_ev(1))+3,txt,'Interpreter','latex')
    end
  end
end
hold off;

legendstr = cell(nb_pols,1);
for ind2 = 1:nb_pols
    if iscell(list_pol(ind2))
        legendstr(ind2) = list_pol(ind2);
    else
        legendstr{ind2} = num2str(list_pol(ind2));
    end
end

if nb_pols == 2
  legend({'OFF', 'ON'});
elseif nb_pols <= 16
  legend(legendstr,'Location', 'southoutside', 'Orientation','horizontal');
end
hold off;
xlabel('Time in microseconds')
ylabel('Level')
if isfield(events,'layer')
  title(['Output of layer ', num2str(events.layer)])
end
