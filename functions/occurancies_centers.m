function occ = occurancies_centers(centers, events)

nc = size(centers,1);
occ = zeros(1,nc);
for ind = 1:nc
   occ(ind) = numel(find(events.p==(ind-1))); 
end