function [last_label] = write_label_data(labels, filename, type, ts_offset, type_labels)

% When no type is specified or the file doesn't exist, truncate the file and
% add the number of entries in the second line of the file.

lines_in_header = true;
if ~exist('type', 'var') || ~exist(filename, 'file')
  type = 'w';
  lines_in_header = false;
end

if ~exist('ts_offset', 'var')
  ts_offset = 0;
end

f = fopen(filename, type);

if type == 'w'
  header = '% labels : t_start t_end class';
  fprintf(f, '%s\n', header);
  if lines_in_header
    fprintf(f, '%d\n', numel(labels{1}));
  end
end

for ind = 1:numel(labels{1})
    if exist('type_labels', 'var')
      fprintf(f, '%d %d %s\n',round(labels{1}(ind))+round(ts_offset), ...
          round(labels{2}(ind))+round(ts_offset),labels{3}{ind});
    else
      fprintf(f, '%d %d %d\n',round(labels{1}(ind))+round(ts_offset), ...
          round(labels{2}(ind))+round(ts_offset),labels{3}(ind));
    end
end
fclose(f);
last_label = round(labels{2}(end))+round(ts_offset);
