function draw_centers(c, params)
% only 2D

MAX_SUBP_X = 6;
MAX_SUBP_Y = 4;

if isfield(c,'k')
  nbP = numel(c.k)-1;
  new_C = (c.data*c.pca_eigv{nbP+1}(:,1:c.k{nbP+1})') + repmat(c.mu{nbP+1},size(c.data,1),1);
  C_invproj = [];
  borne_inf = [1];
  borne_sup = [c.k{1}];
  for ind = 2:nbP
    borne_inf = [borne_inf, borne_sup(ind-1)+1];
    borne_sup = [borne_sup, borne_sup(ind-1)+c.k{ind}];
  end
  for ind = 1:nbP
    C_invproj = [C_invproj, (new_C(:,borne_inf(ind):borne_sup(ind))*c.pca_eigv{ind}(:,1:c.k{ind})') ...
      + repmat(c.mu{ind},size(c.data,1),1)];
  end
  radius = (sqrt(numel(C_invproj(ind,:))/nbP)-1)/2; % FIXME : should have this with parameters coz not 2D 100%
  old_centers = zeros(size(c,1), 2*radius+1, 2*radius+1, nbP);
  for ind = 1:size(c.data,1)
    tst = C_invproj(ind,:);
    tst = tst-min(tst);
    tst = tst/max(tst);
    old_centers(ind,:,:,:) = reshape(tst, 2*radius+1, 2*radius+1, nbP);
  end
  c = permute(old_centers,[2 3 4 1]);
end
% 
% figure;
% nbC = size(c,4);
% nbP = size(c,3);
% x_subp = mod(nbC,8);
% if x_subp == 0
%   x_subp = 8;
% end
% for ind = 1:nbC
%   subplot(x_subp, ceil(nbC/8), ind)
%   img = [];
%   for ind2 = 1:nbP
%     img = [img, c(:,:,ind2,ind)];
%   end
%   imagesc(img);
%   caxis([0 1])
%   axis image
%   colormap hot
% end
% drawnow;

figure;
nbC = size(c,4);
nbP = size(c,3);
x_subp = mod(nbC,8);
if x_subp == 0
  x_subp = 8;
end
for ind = 1:nbC
  subplot(x_subp, ceil(nbC/8), ind)
  img = [];
  for ind2 = 1:nbP
    img = [img, c(:,:,ind2,ind)];
  end
  imagesc(img);
  caxis([0 1])
  axis image
  colormap hot
end
drawnow;
