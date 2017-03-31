function [ fig ] = draw_scene(events, speed, tau, radius)
% INPUTS =  - Events (structure with fiels ts, x, y and p)
%           - Speed multiplier
%           - Tau : exponential decay constant
%           - Radius : context neighborhood
% OUTPUT =  - Figure handle

%% Initialize workspace
load('data/MyColormaps_new','HoTS','hsv_custom')

%% Initialize constants and variables to display the scene properly
MINY = min(events.y); MINX = min(events.x); 
SIZEY = max(events.y)-MINY+1;
SIZEX = max(events.x)-MINX+1;
list_polarities = sort(unique(events.p));
polarities = numel(list_polarities);
h2 = gobjects(polarities+1);
events.ts=events.ts-events.ts(1);

p2 = 0;

%% Initialize figure
[sizex, sizey, subplot_scene, subp_context] = compute_subplots_scene(p2);
fig = figure('NumberTitle','off','Name','Output Events', ...
    'outerposition',[0 0 1280 800]);
subplot(sizex, sizey, subplot_scene)
h1 = imagesc( make_output_scene_and_context(1, events, tau, radius ));
axis ij equal;
axis(0.5+[0 max(events.x)-MINX+1 0 max(events.y)-MINY+1])
ax = gca;
colormap(ax,hsv_custom)
%title(['2D Scene, size_X=', num2str(SIZEX), ...
%    ', size_Y=',num2str(SIZEY), ...
%    ', tau=',num2str(tau)]);
title('Repr�sentation des �v�nements en sortie de la deuxi�me couche de HoTS')
caxis manual
caxis([0 polarities]);
colorbar;

for ind = 1:p2
    curr_subp = subp_context(ind);
    subplot(sizex, sizey, curr_subp);
    h2(ind) = imagesc(-radius:radius,-radius:radius,rand(2*radius+1));
    ax = gca;
    colormap(ax,HoTS)
    axis ij equal square;
    axis([-radius-0.5 radius+0.5 -radius-0.5 radius+0.5])
    title(['Context, p = ', num2str(list_polarities(ind))]);
    caxis manual
    caxis([0 1]);
    colorbar;
end

%% Draw figure
fprintf('Drawing the scene and contexts...\n');
time = tic;
ind = 1;

while (events.ts(ind) < events.ts(end))
    % Searching for the closest event (according to current time)
    [~,ind] = min(abs(events.ts-floor(toc(time)*1000000*speed)));
    [scene, contexts] = make_output_scene_and_context( ind, events, tau, radius );
    curr_pol = list_polarities == events.p(ind);
    set(h1,'CData', scene);
    for ind2 = 1:p2
        set(h2(ind2),'CData',contexts(:,:,ind2));
    end
    drawnow;
end
fprintf('Done!\n');
end
