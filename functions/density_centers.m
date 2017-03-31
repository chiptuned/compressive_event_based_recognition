function [densities] = density_centers(centers)

MINIMUM_VALUE_IN_A_CENTER = 1e-6;

if iscell(centers)
  densities = zeros(size(centers));
  for ind = 1:numel(centers);
    densities(ind) = 1-(numel(find(centers{ind} <= MINIMUM_VALUE_IN_A_CENTER))/numel(centers{ind}));
  end
else
  nb_centers = 1;
  densities = 1-(numel(find(centers <= MINIMUM_VALUE_IN_A_CENTER))/numel(centers));
end
