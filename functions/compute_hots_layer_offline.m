function [new_events, centers] = compute_hots_layer_offline(events, centers, params)
% only 2D

tstart = tic;
new_events = events;
new_events.p = uint32(new_events.p);
tau = params.tau;
nbPols = params.nbPols;
nbCenters = params.nbCenters;
radius = params.radius;
nbChannels = params.nbChannels;
learning = params.learning;
dimension = numel(nbChannels);
nbFeats_pol = (2*radius+1)^dimension;

ratio_variance_keep = 0.8;

MAX_MEMORY_ALLOCATION_GO = 8;
max_offline_allts = floor(MAX_MEMORY_ALLOCATION_GO*1e9/2/8/nbFeats_pol/nbPols);

nb_batch = 1;
ev_start_batch = 1;
ev_end_batch = numel(events.ts);
if numel(events.ts) > max_offline_allts
  size_batch = max_offline_allts;
  if learning
    msg = ['Can learn on only ',num2str(floor(max_offline_allts)), ' events out of ', ...
      num2str(numel(events.ts)),'.'];
    warning(msg);
    ev_end_batch = size_batch;
  else
    nb_batch = ceil(numel(events.ts)/size_batch);
    ev_start_batch = size_batch*(0:nb_batch-1)+1;
    ev_end_batch = [(1:nb_batch-1)*size_batch, ev_end_batch];
    size_batch = [size_batch*ones(1,nb_batch-1), ev_end_batch(end)-ev_start_batch(end)+1];
  end
else
  size_batch = numel(events.ts);
end


if dimension == 1
  lastEvents_framed = -10*tau*ones(nbPols, nbChannels+2*radius);
elseif dimension == 2
  lastEvents_framed = -10*tau*ones(nbChannels(1)+2*radius, nbChannels(2)+2*radius, nbPols);
end

if learning
  fprintf('Computing a learning layer...\n');
else
  for ind = 1:nbPols+1
    tmp = inv(centers.pca_eigv{ind});
    centers.pca_eigv{ind} = tmp(1:centers.k{ind},:)';
  end
  fprintf('Propagating events..\n');
end

for batch = 1:nb_batch

  all_ts = zeros(size_batch(batch), nbFeats_pol, nbPols);

  for idx_ev = ev_start_batch(batch):ev_end_batch(batch)
    ts = double(events.ts(idx_ev));
    p = uint32(events.p(idx_ev));
    if dimension == 1
      level = events.level(idx_ev);
    elseif dimension == 2
      x = events.x(idx_ev);
      y = events.y(idx_ev);
    end

    %% Computing spatio-temporal context
    if dimension == 1
      currCtx = (lastEvents_framed(1+(x:x+2*radius), :)+tau-ts)/tau;
    elseif dimension == 2
      currCtx = (lastEvents_framed(1+(x:x+2*radius), 1+(y:y+2*radius), :)+tau-ts)/tau;
    end
    currCtx(currCtx<0) = 0;

    all_ts(idx_ev+1-ev_start_batch(batch), :) = currCtx(:);

    %% Update the spatio-temporal
    if dimension == 1
      lastEvents_framed(p+1, level+radius+1) = ts;
    elseif dimension == 2
      lastEvents_framed(x+radius+1, y+radius+1, p+1) = ts;
    end
  end
  if learning
    k = cell(1,nbPols+1);
    pca_eigv = cell(1,nbPols+1);
    mu = cell(1,nbPols+1);
    all_ts_proj = [];

    for ind = 1:nbPols
      figure(17)
      imagesc(all_ts(:,:,ind));
      drawnow;
      [coeff,score,~,~,explained,mu{ind}] = pca(all_ts(:,:,ind), 'Algorithm', 'eig', 'Rows', 'complete');
      normsqS = sum(explained.^2);
      k{ind} = find(cumsum(explained.^2)/normsqS >= ratio_variance_keep, 1);
      pca_eigv{ind} = coeff;
      all_ts_proj = [all_ts_proj, score(:,1:k{ind})];
    end

    [coeff,score,~,~,explained,mu{nbPols+1}] = pca(all_ts_proj, 'Algorithm', 'eig');
    normsqS = sum(explained.^2);
    k{nbPols+1} = find(cumsum(explained.^2)/normsqS >= ratio_variance_keep, 1);
    % tmp = inv(coeff);
    % pca_eigv{nbPols+1} = tmp(1:k{nbPols+1},:)';
    pca_eigv{nbPols+1} = coeff;
    new_score = score(:,1:k{nbPols+1});

    opts = statset('Display','off');
    warning('off', 'stats:kmeans:FailedToConvergeRep')
    [~,C] = kmeans(new_score, nbCenters,'Distance','sqeuclidean',...
        'Replicates',3,'Options',opts);
    warning('on', 'stats:kmeans:FailedToConvergeRep')
     % RELANCER
    centers.pca_eigv = pca_eigv;
    centers.data = C;
    centers.k = k;
    centers.mu = mu;
  else
    %% Computing distances
    pol_proj = [];
    for indp = 1:nbPols
      pol_proj = [pol_proj, (all_ts(:,:,indp)-repmat(centers.mu{indp},size(all_ts,1),1))*centers.pca_eigv{indp}];
    end
    Ctx_proj = (pol_proj-repmat(centers.mu{nbPols+1},size(all_ts,1),1))*centers.pca_eigv{nbPols+1};
    [~, nc] = min(pdist2(Ctx_proj,centers.data),[],2); %nc : neareset center

    %% Fire events
    new_events.p(ev_start_batch(batch):ev_end_batch(batch)) = nc-1;
  end
end

fprintf('Took %3.2f seconds\n', toc(tstart))

% if learning
%   new_C = (C*coeff(:,1:k{nbPols+1})') + repmat(mu{nbPols+1},size(C,1),1);
%   C_invproj = [];
%   borne_inf = [1];
%   borne_sup = [k{1}];
%   for ind = 2:nbPols
%     borne_inf = [borne_inf, borne_sup(ind-1)+1];
%     borne_sup = [borne_sup, borne_sup(ind-1)+k{ind}];
%   end
%   for ind = 1:nbPols
%     C_invproj = [C_invproj, (new_C(:,borne_inf(ind):borne_sup(ind))*pca_eigv{ind}(:,1:k{ind})') + repmat(mu{ind},size(C,1),1)];
%   end
%   old_centers = zeros(size(C,1), 2*radius+1, 2*radius+1, nbPols);
%   for ind = 1:size(C,1)
%     tst = C_invproj(ind,:);
%     tst = tst-min(tst);
%     tst = tst/max(tst);
%     old_centers(ind,:,:,:) = reshape(tst, 2*radius+1, 2*radius+1, nbPols);
%   end
%   old_centers = permute(old_centers,[2 3 4 1]);
%   draw_centers(old_centers, params);
%   pause
% end
