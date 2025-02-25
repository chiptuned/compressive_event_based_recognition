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

ratio_variance_keep = 0.999;
% If in a polarity there is less nonzeros elt than this, discard it
thresh_nonzero_pol = floor(0.05 * nbFeats_pol);

MAX_MEMORY_ALLOCATION_GO = 6;
max_offline_allts = floor(MAX_MEMORY_ALLOCATION_GO*1e9/2/8/nbFeats_pol/nbPols/2); % wtfbbq

nb_batch = 1;
ev_start_batch = 1;
ev_end_batch = numel(events.ts);
if (numel(events.ts) > max_offline_allts) && (~learning)
  nb_batch = ceil(numel(events.ts)/max_offline_allts);
  ev_start_batch = max_offline_allts*(0:nb_batch-1)+1;
  ev_end_batch = [(1:nb_batch-1)*max_offline_allts, ev_end_batch];
  size_batch = [max_offline_allts*ones(1,nb_batch-1), ev_end_batch(end)-ev_start_batch(end)+1];
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
  nb_events_kept = zeros(1,nbPols);
  nb_events_kept_allp = 0;
else
  fprintf('Propagating events..\n');
end

for batch = 1:nb_batch
  try
    if learning
      all_ts = zeros(max_offline_allts, nbFeats_pol, nbPols);
      all_ts2 = zeros(max_offline_allts, nbFeats_pol, nbPols);
    else
      all_ts = zeros(size_batch(batch), nbFeats_pol, nbPols);
      all_ts2 = zeros(size_batch(batch), nbFeats_pol, nbPols);
    end
  catch ex
    size_batch
    [size_batch(batch), nbFeats_pol, nbPols]
    fprintf('That''s %.1fG.\n', size_batch(batch)*nbFeats_pol*nbPols*8/(1024^3));
    rethrow(ex)
  end

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

    if learning
      for indp = 1:nbPols
        if numel(find(currCtx(:,:,indp))) > thresh_nonzero_pol
          if nb_events_kept(indp) < max_offline_allts
            nb_events_kept(indp) = nb_events_kept(indp) + 1;
            all_ts(nb_events_kept(indp), :, indp) = reshape(currCtx(:,:,indp), 1,[]);
          else
            if isequal(nb_events_kept, max_offline_allts*ones(1,nbPols))
              msg = ['Can learn on only ',num2str(floor(max_offline_allts)), ' events out of ', ...
                num2str(numel(events.ts)),'.'];
              warning(msg);
              break;
            end
          end
        end
      end
      if numel(find(currCtx)) > (thresh_nonzero_pol*nbPols)
        if nb_events_kept_allp < max_offline_allts
          nb_events_kept_allp = nb_events_kept_allp + 1;
          all_ts2(nb_events_kept_allp, :) = currCtx(:);
        else
          msg = ['Can learn on only ',num2str(floor(max_offline_allts)), ' events out of ', ...
            num2str(numel(events.ts)),'.'];
          warning(msg);
          break;
        end
      end
    else
      all_ts(idx_ev+1-ev_start_batch(batch), :) = currCtx(:);
    end
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
    proj = cell(1,nbPols+1);
    all_ts_proj = [];

    for ind = 1:nbPols
      % figure(17)
      % imagesc(all_ts(1:nb_events_kept,:,ind));
      % drawnow;
      if nb_events_kept(ind) == 0
        msg = ['Polarity ', num2str(ind), ' doesn''t contain relevant events, discarding...'];
        warning(msg);
        k{ind} = 0;
        pca_eigv{ind} = 0;
        proj{ind} = 0;
        mu{ind} = 0;
      else
        try
          [coeff,score,~,~,explained,mu{ind}] = pca(all_ts(1:nb_events_kept(ind),:,ind), 'Algorithm', 'svd', 'Rows', 'complete');
        catch ex
          mat_pca = all_ts(1:nb_events_kept(ind),:,ind);
          nb_events_kept_this_ind = nb_events_kept(ind);
          save('lastcrash-pca', 'mat_pca', 'ind', 'nb_events_kept_this_ind')
          sum(all_ts(1:nb_events_kept(ind),:,ind))
          sum(all_ts(1:nb_events_kept(ind),:,ind)')
          nb_events_kept(ind)
          imagesc(all_ts(1:nb_events_kept(ind),:,ind))
          drawnow;
          rethrow(ex)
        end
        normsqS = sum(explained.^2);
        k{ind} = find(cumsum(explained.^2)/normsqS >= ratio_variance_keep, 1);
        pca_eigv{ind} = coeff;
        try
          if numel(unique(size(coeff))) ~= 1
            tmp = pinv(coeff);
          else
            tmp = inv(coeff);
          end
        catch ex
          mat_pca = all_ts(1:nb_events_kept(ind),:,ind);
          nb_events_kept_this_ind = nb_events_kept(ind);
          mu_this_ind = mu{ind};
          save('lastcrash_inv_coeff', 'coeff', 'mat_pca', ...
            'ind', 'nb_events_kept_this_ind', 'score', 'explained', 'mu_this_ind');
          size(coeff)
          rethrow(ex);
        end
        proj{ind} = tmp(1:k{ind},:)';
      end
      all_ts_proj = [all_ts_proj, (all_ts2(:,:,ind)-repmat(mu{ind},size(all_ts2,1),1))*proj{ind}];
    end


    try
      [coeff,score,~,~,explained,mu{nbPols+1}] = pca(all_ts_proj, 'Algorithm', 'svd', 'Rows', 'complete');
    catch ex
      save('lastcrash-pca', 'all_ts_proj', 'ind', 'nb_events_kept_this_ind')
      imagesc(all_ts_proj)
      drawnow;
      rethrow(ex)
    end
    normsqS = sum(explained.^2);
    k{nbPols+1} = find(cumsum(explained.^2)/normsqS >= ratio_variance_keep, 1);
    try
      if numel(unique(size(coeff))) ~= 1
        tmp = pinv(coeff);
      else
        tmp = inv(coeff);
      end
    catch ex
      mu_this_ind = mu{nbPols+1};
      save('lastcrash_inv_coeff', 'coeff', 'all_ts_proj', ...
        'score', 'explained', 'mu_this_ind');
      size(coeff)
      rethrow(ex);
    end
    proj{nbPols+1} = tmp(1:k{nbPols+1},:)';
    pca_eigv{nbPols+1} = coeff;
    new_score = score(:,1:k{nbPols+1});

    opts = statset('Display','off');
    warning('off', 'stats:kmeans:FailedToConvergeRep')
    [~,C] = kmeans(new_score, nbCenters,'Distance','sqeuclidean',...
        'Replicates',3,'Options',opts);
    warning('on', 'stats:kmeans:FailedToConvergeRep')

    centers.pca_eigv = pca_eigv;
    centers.proj = proj;
    centers.data = C;
    centers.k = k;
    centers.mu = mu;
  else
    %% Computing distances
    pol_proj = [];
    for indp = 1:nbPols
      pol_proj = [pol_proj, (all_ts(:,:,indp)-repmat(centers.mu{indp},size(all_ts,1),1))*centers.proj{indp}];
    end
    Ctx_proj = (pol_proj-repmat(centers.mu{nbPols+1},size(all_ts,1),1))*centers.proj{nbPols+1};
    [~, nc] = min(pdist2(Ctx_proj,centers.data),[],2); %nc : neareset center

    %% Fire events
    new_events.p(ev_start_batch(batch):ev_end_batch(batch)) = nc-1;
  end
end

fprintf('Took %3.2f seconds\n', toc(tstart))
