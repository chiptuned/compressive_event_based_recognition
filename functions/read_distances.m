function [distances] = read_distances(filename, events, params)
nbLayers = params.nbLayers;

distances = cell(1,nbLayers);
fid = fopen(filename, 'r');


for ind = 1:nbLayers

  distances(ind) = {zeros(numel(events.ts), params.nbCenters(ind))};
  for ind2 = 1:numel(events.ts)
    try
      fgetl(fid);
      dists = fgetl(fid);
      distances{ind}(ind2,:) = str2num(dists);
    catch
      str2num(dists)
      ind
      ind2
      distances{ind}(ind2,:)
      error('distances not gud')
    end
  end
end