function [new_events, centers] = compute_hots_layer_offline(events, centers, params)
% only 2D

tstart = tic;
new_events = events;
tau = params.tau;
nbPols = params.nbPols;
nbCenters = params.nbCenters;
radius = params.radius;
nbChannels = params.nbChannels;
learning = params.learning;

dimension = numel(nbChannels);
nbFeats_pol = (2*radius+1)^dimension;

if dimension == 1
  lastEvents_framed = -10*tau*ones(nbPols, nbChannels+2*radius);
elseif dimension == 2
  lastEvents_framed = -10*tau*ones(nbChannels(1)+2*radius, nbChannels(2)+2*radius, nbPols);
end

all_ts = zeros(numel(events.ts), nbFeats_pol * nbPols);

if learning
  fprintf('Computing a learning layer...\n');
else
  fprintf('Propagating events..\n');
end

for idx_ev = 1:numel(events.ts)
  tstart2 = tic;
  ts = double(events.ts(idx_ev));
  p = events.p(idx_ev);
  if dimension == 1
    level = events.level(idx_ev);
  elseif dimension == 2
    x = events.x(idx_ev);
    y = events.y(idx_ev);
  end

  %% Update the spatio-temporal
  if dimension == 1
    lastEvents_framed(p+1, level+radius+1) = ts;
  elseif dimension == 2
    lastEvents_framed(x+radius+1, y+radius+1, p+1) = ts;
  end

  %% Computing spatio-temporal context
  if dimension == 1
    currCtx = (lastEvents_framed(1+(x:x+2*radius), :)+tau-ts)/tau;
  elseif dimension == 2
    currCtx = (lastEvents_framed(1+(x:x+2*radius), 1+(y:y+2*radius), :)+tau-ts)/tau;
  end
  currCtx(currCtx<0) = 0;

  all_ts(idx_ev, :) = currCtx(:);
end
if learning
else
  %% Computing distances
  Ctx_proj = (all_ts-repmat(centers.mu,size(all_ts,1),1))*centers.pca_eigv;
  [~, nc] = min(pdist2(Ctx_proj,centers.data),[],2); %nc : neareset center
  %% Fire events
  new_events.p = nc-1;
end

if learning
  [coeff,score,latent,~,explained,mu] = pca(all_ts, 'Algorithm', 'eig', 'Rows', 'complete');
  normsqS = sum(explained.^2);
  k = find(cumsum(explained.^2)/normsqS >= 0.80, 1);
  new_score = score(:,1:k);
  opts = statset('Display','off');
  warning('off', 'stats:kmeans:FailedToConvergeRep')
  [~,C] = kmeans(new_score, nbCenters,'Distance','sqeuclidean',...
      'Replicates',3,'Options',opts);
  warning('on', 'stats:kmeans:FailedToConvergeRep')
  pca_eigv = inv(coeff);
  pca_eigv = pca_eigv(1:k,:)';
  centers.pca_eigv = pca_eigv;
  centers.data = C;
  centers.mu = mu;
end

fprintf('Took %3.2f seconds\n', toc(tstart))

if learning
  new_C = (C*coeff(:,1:k)') + repmat(mu,size(C,1),1);
  old_centers = zeros(size(C,1), 2*radius+1, 2*radius+1, nbPols);
  for ind = 1:size(C,1)
    tst = new_C(ind,:);
    tst = tst-min(tst);
    tst = tst/max(tst);
    old_centers(ind,:,:,:) = reshape(tst, 2*radius+1, 2*radius+1, nbPols);
  end
  old_centers = permute(old_centers,[2 3 4 1]);
  draw_centers(old_centers, params);
  pause
end
