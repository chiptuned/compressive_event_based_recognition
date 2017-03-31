function [idx_col] = compute_columns_order(matrix)
% objectif -> rendre la matrice carée diagonale

VISUALISATION = false;

if VISUALISATION
  figure;
  himg = imagesc(matrix); colorbar; axis xy; axis square;
  xlabel('hots centers');
  ylabel('frequency bands');
end
comb = 1:size(matrix);
for ind = 1:size(matrix)
    %%% searching best centers for frequancy bands
    vect_max = max(matrix(ind:end,ind:end));
    [~, maxidx] = max(vect_max);
    maxidx = maxidx + ind - 1;
    tmp = matrix(:,ind);
    tmp2 = comb(ind);
    matrix(:,ind) = matrix(:,maxidx);
    comb(ind) = comb(maxidx);
    matrix(:,maxidx) = tmp;
    if VISUALISATION
      comb(maxidx) = tmp2;
      himg.CData = matrix;
      drawnow;
    end
end
idx_col = comb;