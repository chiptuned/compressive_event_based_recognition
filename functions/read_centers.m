function [centers] = read_centers(filename)

fid = fopen(filename, 'r');
header = fgetl(fid);
tmp = str2num(fgetl(fid));
Ndim = tmp(1);
NPols = tmp(2); 
tmp = str2num(fgetl(fid));
nCenters = tmp(1);
nbFeats = tmp(2);
radius = (nbFeats/NPols-1)/2;
centers = zeros(nCenters, NPols, nbFeats/NPols);
for ind = 1:nCenters
  line = str2num(fgetl(fid));
  for ind2 = 1:NPols
    centers(ind,ind2,:) = line(((2*radius+1)*(ind2-1))+(1:(2*radius+1)));
  end
end
fclose = fopen(fid);