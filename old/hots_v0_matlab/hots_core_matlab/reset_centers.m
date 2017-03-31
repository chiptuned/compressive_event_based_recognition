function [centers, nb_occ_centers] = reset_centers(params)

nbCenters = params.nbCenters;
nbPols = params.nbPols;
radius = params.radius;
nbChannels = params.nbChannels;
nbFeats_pol = (2*radius+1)^numel(nbChannels);

if isfield(params,'typeCenters')
 type = params.typeCenters; 
else
 type = 0;
end

if type == 0
 centers = 0.5*ones(nbCenters, nbPols, nbFeats_pol);
  nb_occ_centers = 0.5*ones(1, nbCenters);
end
if type == 1
  if nbCenters<(2*nbPols)
    error('pas assez de centres')
  end
  centers = ones(nbCenters, nbPols, nbFeats_pol);
  cpt = 0;
  for ind = 1:nbCenters
    tmp = mod(ind,nbPols*2);
    if tmp == 0
      tmp = nbPols*2;
    end
    ind2 = ceil(tmp/2);
    ind3 = 1:radius;
    if mod(ind,2) == 0
      ind3 = ind3+radius+1;
    end
    centers(ind, ind2, ind3) = zeros(size(ind3));
  end
  nb_occ_centers = ones(1, nbCenters);
end
if type == 2
 centers = rand(nbCenters, nbPols, nbFeats_pol);
   nb_occ_centers = 0.5*ones(1, nbCenters);
end