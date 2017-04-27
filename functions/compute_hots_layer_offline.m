function [new_events, centers] = compute_hots_layer_offline(events, centers, params)
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
  all_ts = zeros(numel(events.ts), nbFeats_pol * nbPols);
  fprintf('Computing a learning layer...\n');
else
  fprintf('Propagating events..\n');
end

dists = zeros(1,size(centers,1));
currCtx = zeros(nbPols, nbFeats_pol);

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

  if learning
    all_ts(idx_ev, :) = currCtx(:);
  else
    %% Computing distances
    for ind = 1:size(centers,1)
      a = currCtx;
      a = a(:)/sum(a(:));
      b = centers(ind,:);
      b = b(:)/sum(b(:));
      dists(ind) = -log(sqrt(sum(a.*b)));
    end
    [~, nc] = min(dists); %nc : neareset center
    %% Fire events
    new_events.p(idx_ev) = nc-1;
  end
end
if learning
  opts = statset('Display','off');
  [~,C] = kmeans(all_ts, nbCenters,'Distance','sqeuclidean',...
      'Replicates',5,'Options',opts);
  centers(:) = C(:);
end

fprintf('Took %3.2f seconds\n', toc(tstart))
end
