function [new_events, centers, hotsogram] = compute_hots_layer(events, centers, params)

% NE FONCTIONNE QUE EN 1D

% tau (us), ksi, nPow, nbPols, nbCenters, radius, nbChannels, learning

% Changement a faire : rajouter une variable pour bloquer/ajouter des
% centres, verifier a chaque update si on fait descendre les centres en
% dessous du thresh, si oui, alors on converge.

% Du coup on peut passer en sparse-matrix, plus pratique pour chopper le
% niveau de convergence, et ca va accélerer le code suivant les couches.

params
tstart = tic; %%%

nb_loops = 0;
new_events = events;

THRESH_ACT_CENTERS = 100;
THRESH_CONV = 1e-2;

AFFICHAGE_CTX = false;
MAXIMUM = 100;
SAVING_FEATURES = false;

if isfield(params,'hotsogram')
  GRAPH_HOTS = params.hotsogram == true;
else
  GRAPH_HOTS = false;
end
if isfield(params,'seed')
    rng(params.seed);
end
if ~isfield(params,'max_loops')
    max_loops = 0;
else
    max_loops = params.max_loops;
end

tau = params.tau;
ksi = params.ksi;
nPow = params.nPow;
nbPols = params.nbPols;
nbCenters = params.nbCenters;
radius = params.radius;
nbChannels = params.nbChannels;
learning = params.learning;

dimension = numel(nbChannels);
convergence = false;

nbFeats_pol = (2*radius+1)^dimension;
lastEvents_framed = -inf(nbPols, nbChannels+2*radius);
dists = zeros(1,size(centers,1));


if learning
  if SAVING_FEATURES
    features = [];
  end
  [centers, nb_occ_centers] = reset_centers(params);
  fprintf('Computing a learning layer...\n');
else
  fprintf('Propagating events..\n'); 
end

if AFFICHAGE_CTX
    figure(170)
    subplot(2,1,1)
    plot(-radius:radius,zeros(1,2*radius+1));
    subplot(2,1,2)
    plot(-radius:radius,zeros(1,2*radius+1));
end

if GRAPH_HOTS
    hotsogram = zeros(numel(events.ts),nbCenters);
end



while ~convergence
%   if learning
%     msgbar = 'learning';
%   else
%     msgbar = 'propagation';
%   end
%   msgbar = ['Computing layer - ', msgbar]; 
%   bar = waitbar(0, msgbar);

  events.ts = events.ts + events.ts(end)+tau*100;
  for idx_ev = 1:numel(events.ts)
    ts = events.ts(idx_ev);
    p = events.p(idx_ev);
    level = events.level(idx_ev);

    %% Update the spatio-temporal 
    lastEvents_framed(p+1, level+radius+1) = ts;

    %% Computing spatio-temporal context
    try
        currCtx = ts-lastEvents_framed(:, 1+(level:level+2*radius));
    catch
        size(lastEvents_framed)
        level
    end
    currCtx = exp(-currCtx/tau);
    if SAVING_FEATURES
      features = [features, currCtx(:)];
    end
    if AFFICHAGE_CTX
        if mod(idx_ev,1000) == 0
        figure(170)
        subplot(2,1,1)
        plot(-radius:radius,currCtx(1,:));
        axis([-radius, radius, 0, 1])
        subplot(2,1,2)
        plot(-radius:radius,currCtx(2,:));
        axis([-radius, radius, 0, 1])
        pause(0.3);
        end
    end

    %% Computing distances 
    for ind = 1:size(centers,1)
      % Bhattacharyya
      if size(currCtx(:)) ~= size(centers(ind,:)')
          size(currCtx(:))
          size(centers(ind,:)')
      end
      try
        %dists(ind) = -log(sum(currCtx(:).*centers(ind,:)')/numel(currCtx));
        tmpctx = currCtx(:)/sum(currCtx(:));
        tmpcenters = centers(ind,:)';
        tmpcenters = tmpcenters(:)/sum(tmpcenters(:));
        dists(ind) = -log(sum(tmpctx.*tmpcenters)/numel(currCtx));
        if (dists(ind) > MAXIMUM) || isnan(dists(ind)) || isinf(dists(ind)) 
            % currCtx(:)'
            % centers(ind,:)
            dists(ind) = MAXIMUM;
            % pause
        elseif dists(ind) < 0
          error('wtf')
        end
      catch
         size(dists)
         ind
         size(currCtx)
         size(centers)
      end
    end
    [~, nc] = min(dists); %nc : neareset center
    % On peut analyser dists(nc) (et a fortior dists) afin de quantifier la 
    % qualité de l'événement

    % Phase de learning puis phase de test, on pourrait switcher au bout d'un certain
    % temps ou une certaine convergence des centres
    
    if learning %&& nb_occ_centers(nc)<2000
      %% Update centers
      %% IIWKMEANS, faut trouver mieux
      coeff = ksi*((nPow+1)*(dists(nc)^(nPow-1))+...
        nPow*(dists(nc)^(nPow-2))*(sum(dists)-dists(nc)));
      % centers(nc,:)
      % currCtx(:)'
      % pause(.5)
      centers(nc, :) = (1-coeff).*centers(nc,:)+coeff.*currCtx(:)';
      if numel(find(isnan(centers(nc,:)))) > 0
          dists
          error('EXPLOSIONS')
      end
      nb_occ_centers(nc) = (1-coeff)*nb_occ_centers(nc);
      %% Manage bounds
      centers(nc, (centers(nc,:) < 0)) = 0;
      centers(nc, (centers(nc,:) > 1)) = 1;
    else
      %% Fire events
      new_events.p(idx_ev) = nc-1;
      if GRAPH_HOTS
        hotsogram(idx_ev,:) = dists;
      end
    end
%     if mod((idx_ev+(idxloop-1)*numel(events.ts)), round(numel(events.ts)*loops/100)) == 0 %tst
%       waitbar((idx_ev+(idxloop-1)*numel(events.ts))/numel(events.ts)*loops,bar);
%     end
  end
%   delete(bar)
  if SAVING_FEATURES
    save('features.mat', 'features');
    error('Terminé après sauvegarde de la feature')
  end
  %% Calcul du critère d'arrêt d'apprentissage
  if learning
      if max_loops == nb_loops
          convergence = true;
          continue;
      end
    convergence = prod(nb_occ_centers<THRESH_CONV);
    centers(centers<THRESH_CONV) = 0;
    nb_loops = nb_loops + 1;
  else
      % un do while aurait été cool
      convergence = true;
  end
end
fprintf('Took %3.2f seconds', toc(tstart))
if learning
    fprintf(' (%d loops)', nb_loops)
end
fprintf('\n')
end