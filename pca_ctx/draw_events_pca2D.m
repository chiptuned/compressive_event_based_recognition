close all force;
clearvars;
clc;

load('faces_square_pca_2D_1pol.mat');
figure;
cpt = 0;
for ind = 1:size(pts_2D,1)
  for ind2 = 1:size(pts_2D,2)
    cpt = cpt + 1;
    events = pts_2D{ind,ind2};
    ts = events(:,1);
    x = events(:,2);
    y = events(:,3);

    xx=[x(:),x(:)];
    yy=[y(:),y(:)];
    zz=[ts(:),ts(:)];

    hs=scatter3(x,y,ts,15,ts,'.'); %// color binded to "y" values
    colormap('hot')
    view(2) %// view(0,90)
    pause
  end
end
