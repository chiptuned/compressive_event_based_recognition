function labels = load_labels(label_file, fe)

if ~exist('fe', 'var')
  fe = 16000;
end

fid = fopen(label_file, 'r');
first_line = fgetl(fid);
isheader = first_line(1) == '%';
if isheader
  fact_norm = 1;
else
  frewind(fid);
  fact_norm = 1e6/fe;
end
% FGETL POUR LES LABELS DEJA GENERES
labels = textscan(fid, '%d64 %d64 %s');
labels{1} = double(labels{1})*fact_norm;
labels{2} = double(labels{2})*fact_norm;
fclose(fid);
