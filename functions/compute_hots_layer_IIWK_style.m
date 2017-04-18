function [new_events, centers] = compute_hots_layer_IIWK_style(events, centers, params)
tstart = tic; %%%
ksi = 2e-4;
nPow = 3;
new_events = events;
tau = params.tau;
nbPols = params.nbPols;
nbCenters = params.nbCenters;
radius = params.radius;
nbChannels = params.nbChannels;
learning = params.learning;

dimension = numel(nbChannels);
nbFeats_pol = (2*radius+1)^dimension;
lastEvents_framed = -10*tau*ones(nbPols, nbChannels+2*radius);

if learning
  centers = zeros(nbCenters, nbPols, nbFeats_pol);
  fprintf('Computing a learning layer...\n');
else
  fprintf('Propagating events..\n');
end

dists = zeros(1,size(centers,1));
currCtx = zeros(nbPols, 1+2*radius);

for idx_ev = 1:numel(events.ts)
  tstart2 = tic;
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

  %% Computing distances
  for ind = 1:size(centers,1)
    % cityblock
    dists(ind) = sum(abs(currCtx(:)'-centers(ind,:)));
  end
  [~, nc] = min(dists); %nc : neareset center
  % On peut analyser dists(nc) (et a fortior dists) afin de quantifier la
  % qualité de l'événement

  % Phase de learning puis phase de test, on pourrait switcher au bout d'un certain
  % temps ou une certaine convergence des centres
  if learning %&& nb_occ_centers(nc)<2000
    %% Update centers
    %% IIWKMEANS, faut trouver mieux
    coeff = ksi.*((nPow+1).*(dists(nc).^(nPow-1))+...
      nPow.*(dists(nc).^(nPow-2)).*(sum(dists)-dists(nc)));
    if coeff > 1
      coeff = 1;
    elseif coeff < 0
      coeff = 0;
    end
    % centers(nc,:)
    % currCtx(:)'
    % pause(.5)
    centers(nc, :) = (1-coeff).*centers(nc,:)+coeff.*currCtx(:)';
    if numel(find(isnan(centers(nc,:)))) > 0
        dists
        error('EXPLOSIONS')
    end
    %% Manage bounds
    centers(nc, (centers(nc,:) < 0)) = 0;
    centers(nc, (centers(nc,:) > 1)) = 1;
  else
    %% Fire events
    new_events.p(idx_ev) = nc-1;
  end
end
fprintf('Took %3.2f seconds\n', toc(tstart))
end
