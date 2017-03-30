function check_integrity_event_label(events, labels)

for ind = 1:numel(events.ts)
  lower_bound = find(events.ts(ind)>labels{1});
  upper_bound = find(events.ts(ind)<=labels{2},1);
  lower_bound = lower_bound(end);
  if lower_bound ~= upper_bound
    ind
    lower_bound
    upper_bound
    events.ts(ind)
    [labels{1}(lower_bound) labels{2}(lower_bound)]
    [labels{1}(upper_bound) labels{2}(upper_bound)]
    error('derp')
  end
end
fprintf('%s and %s are good.\n', inputname(1), inputname(2));
