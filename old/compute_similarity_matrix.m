function [mat] = compute_similarity_matrix(vect1, vect2)
mat = zeros(numel(vect1), numel(vect2));
for ind = 1:numel(vect2)
   tmp = abs(vect1-vect2(ind));
   tmp = (tmp-min(tmp))/(max(tmp)-min(tmp));
   mat(:,ind) = 1-tmp;
end