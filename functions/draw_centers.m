function draw_centers(c, params)
% only 2D

if isfield(c,'k')
  nbP = numel(c.k)-1;
  new_C = (c.data*c.proj{nbP+1}(:,1:c.k{nbP+1})') + repmat(c.mu{nbP+1},size(c.data,1),1);
  C_invproj = [];
  borne_inf = [1];
  borne_sup = [c.k{1}];
  for ind = 2:nbP
    borne_inf = [borne_inf, borne_sup(ind-1)+1];
    borne_sup = [borne_sup, borne_sup(ind-1)+c.k{ind}];
  end
  for ind = 1:nbP
    C_invproj = [C_invproj, (new_C(:,borne_inf(ind):borne_sup(ind))*c.proj{ind}(:,1:c.k{ind})') ...
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

% Nb of plots config. Min is 2*1=2 and Max is 6*4=24
subp_y_choices = [1, 2, 2, 2, 3, 4, 5, 6];
subp_x_choices = [2, 2, 3, 4, 5, 6, 6, 8];
%pols_that_in_i = [2, 2, 3, 4, 5, 6, 6, 6];
nbC = size(c,4);
nbP = size(c,3);

MAX_SIZE_SUBP = 6; % Fix the maximum nb of plots in a fig

subp_y_choices = subp_y_choices(1:MAX_SIZE_SUBP);
subp_x_choices = subp_x_choices(1:MAX_SIZE_SUBP);

nb_figs = ceil(nbC/subp_y_choices(end)/subp_x_choices(end));
idx_subp_y_figs = ones(1,nb_figs);
idx_subp_x_figs = ones(1,nb_figs);

while sum(subp_x_choices(idx_subp_x_figs).*subp_y_choices(idx_subp_y_figs)) < nbC
    [~, fig_to_inc] = min(subp_x_choices(idx_subp_x_figs).*subp_y_choices(idx_subp_y_figs));
    idx_subp_x_figs(fig_to_inc) = idx_subp_x_figs(fig_to_inc)+1;
    idx_subp_y_figs(fig_to_inc) = idx_subp_y_figs(fig_to_inc)+1;
end
nb_plots_figs = subp_x_choices(idx_subp_x_figs).*subp_y_choices(idx_subp_y_figs);

sizey_center = floor(sqrt(nbP));
sizex_center = ceil(nbP/sizey_center);
rx = size(c,1);
ry = size(c,2);

indf = 0;
for ind = 1:nbC
  newindf = find(cumsum(nb_plots_figs) >= ind,1);
  if newindf ~= indf
    figure;
  end
  indf = newindf;
  ind_in_subp = ind - sum(nb_plots_figs(1:indf-1));
  subplot(subp_y_choices(idx_subp_y_figs(indf)), subp_x_choices(idx_subp_x_figs(indf)), ind_in_subp)
  img = ones(sizey_center*size(c,2), sizex_center*size(c,1));
  for ind2 = 1:nbP
    indcx = mod(ind2, sizex_center);
    if indcx == 0
      indcx = sizex_center;
    end
    indcy = ceil(ind2/sizex_center);
    img((1:ry)+ry*(indcy-1), (1:rx)+rx*(indcx-1)) = c(:,:,ind2,ind);
  end
  imagesc(img);
  caxis([0 1])
  axis image
  colormap hot
  title(num2str(ind))
  %set(gca,'visible','off')
end
