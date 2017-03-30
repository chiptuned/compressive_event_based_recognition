function [info] = get_info(filename)
regexp(filename, 'dr', 'once');
info = textscan(filename(regexp(filename, 'dr', 'once')-2:end), '%s', ...
'Delimiter', './');
info = info{1};
if (info{1} == 'n') 
  train = 1; 
else
  train = 0; 
end

dr = str2num(info{2}(end));
sex = info{3}(1);
id = info{3}(2:end);
type = info{4}(1:2);
line = str2num(info{4}(3:end));

if train == 1
    set = 'train';
else
    set = 'test';
end

clear info;
info.set = set;
info.dr = dr;
info.id = id;
info.sex = sex;
info.line = line;
info.type = type;

% fprintf('Read %s, dr%d, id %s of sex %s, line %d type %s\n', ...
%     set, dr, id, sex, line, type);