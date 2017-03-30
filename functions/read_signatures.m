function [sigs] = read_signatures(filename_sigs)

fid = fopen(filename_sigs, 'r');
tmp = strsplit(fgetl(fid));
numberOfClasses = str2num(tmp{9});
numberOfExample = str2num(tmp{12});
nbCenters = 0;

sigs = [];

for ind = 1:numberOfClasses
  line = str2num(fgetl(fid));
  if nbCenters == 0
    nbCenters = numel(line);
    sigs = zeros(numberOfClasses, nbCenters);
  end
  sigs(ind,:) = line;
end
fclose(fid);