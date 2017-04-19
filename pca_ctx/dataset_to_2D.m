clearvars;
close all force;;

filename_mat = '../N-datasets/Faces/faces_square.mat';
load(filename_mat);
[nb_faces, nb_presentations] = size(ROI);
pts_2D = cell(size(ROI));

radius = 4;
tau = 10000;
scene_w_border = -inf(304+2*radius,240+2*radius,1);

% figure;
% subplot(121);
% img1 = imagesc(zeros(2*radius+1,2*radius+1));
% colormap(hot)
% subplot(122);
% img2 = imagesc(zeros(2*radius+1,2*radius+1));
% colormap(hot)

h = waitbar(0,'Crushing data...');
cpt = 0;
for ind_class = 1:nb_faces
  for ind_pres = 1:nb_presentations
    ev = ROI{ind_class, ind_pres};
    ctx_mat_pres =  zeros(numel(ev.ts), (2*radius+1) * (2*radius+1) * 1);
    for ind_ev = 1:numel(ev.ts)
      scene_w_border(ev.x(ind_ev)+radius+1, ev.y(ind_ev)+radius+1) = ev.ts(ind_ev);
      currCtx = 3*tau - ev.ts(ind_ev) + scene_w_border( ... % 3*tau = 95%
        ev.x(ind_ev)+(1:(2*radius+1)), ...
        ev.y(ind_ev)+(1:(2*radius+1)));
      currCtx(currCtx < 0) = 0;
      currCtx(isinf(currCtx)) = 0;
      currCtx = currCtx/(3*tau);

      % img1.CData = currCtx(:,:,1);
      % img2.CData = currCtx(:,:,2);
      % drawnow;

      ctx_mat_pres(ind_ev,:) = currCtx(:);
    end
    [~,score] = pca(ctx_mat_pres);
    pts_2D{ind_class, ind_pres} = [ev.ts, score(:,1:2)];
    cpt = cpt + 1;
    waitbar(cpt/numel(ROI), h);
  end
end
close(h)
save('faces_square_pca_2D_1pol.mat', 'pts_2D');
