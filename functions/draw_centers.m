function draw_centers(c, params)
% only 2D

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
