function [new_events, centers] = compute_hots_layer_test_similarities(events, centers, params)
% TODO : make it work!
debug_mode = 0;

h_subp = [];
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
lastEvents_framed = -10*tau*ones(nbPols, nbChannels+2*radius);
nb_Feat_ctx = nbFeats_pol*nbPols;

if learning
  centers = [];%zeros(nbCenters, nbPols, nbFeats_pol);
  occ_centers = [];
  thresh_nb_pixel_relevant_surface = 0;
  thresh_relevant_pixel_surface = 5e-2; % exp(-3tau/tau) = exp(-3) = 5e-2
  thresh_similarity = 0;
  thresh_variance = 1;
  thresh_occ = 1e15;
  nb_discarded_events = 0;
  fprintf('Computing a learning layer...\n');
else
  fprintf('Propagating events..\n');
end

currCtx = zeros(nbPols, 1+2*radius);

for idx_ev = 1:numel(events.ts)
  dists = zeros(1,size(centers,1));
  tstart2 = tic;
  ts = events.ts(idx_ev);
  p = events.p(idx_ev);
  level = events.level(idx_ev);


  %% Computing spatio-temporal context
  currCtx = ts-lastEvents_framed(:, 1+(level:level+2*radius));

  %% Update the spatio-temporal
  lastEvents_framed(p+1, level+radius+1) = ts;

  currCtx = exp(-currCtx/tau);
  % if nbPols > 2
  %   figure(47)
  %   line_ctx = currCtx';
  %   plot(line_ctx(:));
  %   drawnow;
  % end

  % subplot(4,4,[9:16])
  % plot(currCtx)
  % hold on;
  % plot(currCtx, '*r')
  % hold off;
  % title([num2str(idx_ev), ' | ', num2str(size(centers,1))])
  % drawnow
  %% Computing distances
  for ind = 1:size(centers,1)
    % % euclidean
    % dists(ind) = sqrt(sum(abs(currCtx(:)'-centers(ind,:).^2)));
    % % bhattacharrya
    % a = currCtx(:);
    % b = centers(ind,:)';
    % dists(ind) = -log(sum(sqrt(a.*b/(sum(a)*sum(b)))));
    % cityblock alike
    dists(ind) = sum(abs(currCtx(:)'-centers(ind,:)));
  end
  [~, nc] = min(dists); %nc : neareset center
  % On peut analyser dists(nc) (et a fortior dists) afin de quantifier la
  % qualité de l'événement

  if learning
    old_centers = centers;
    if debug_mode
      idx_ev
      %affs
      figure(42)
      for ind = 1:size(centers,1)
        h_subp(ind) = subplot(8,8,ind);
        center_line = squeeze(centers(ind,:,:))';
        plot(center_line(:))
        hold on;
        plot(center_line(:), '*r')
        axis([1 22 0 1])
        hold off;
      end
      for ind = (size(centers,1)+1):64
        if numel(h_subp) >= ind
          delete(h_subp(ind));
          fprintf('deleted %d\n');
        end
      end
      if numel(h_subp) > size(centers,1)
        h_subp(size(centers,1):end) = [];
      end
      subplot(4,4,[9:16])
      line_ctx = currCtx';
      plot(line_ctx(:));
      axis([1 22 0 1])
      drawnow;
    end

    %fin affs
        if numel(find(currCtx(:)>thresh_relevant_pixel_surface))/nb_Feat_ctx > thresh_nb_pixel_relevant_surface
          if isempty(centers)
              % si il n'y a pas encore de centres
              centers = shiftdim(currCtx, -1);
              occ_centers = 1;
              if debug_mode
                fprintf('No centers. Adding this one\n');
              end
          else
            dists_norm = dists/max(dists);
            cond1 = dists(nc)/numel(currCtx) < thresh_similarity;
            cond2 = var(dists_norm) > thresh_variance;
            cond3 = occ_centers(nc) < thresh_occ;
            if cond1 && cond2 && cond3
              if debug_mode
                dists
                dists_norm
              end
              coeff = dists_norm(nc);
              new_center = (1-coeff).*centers(nc,:)+coeff.*currCtx(:)';
              if numel(find(new_center>thresh_relevant_pixel_surface))/nb_Feat_ctx >= thresh_nb_pixel_relevant_surface
                centers(nc,:) = new_center;
                occ_centers(nc) = occ_centers(nc) + 1;
                if debug_mode
                  fprintf('center updated\n')
                end
                thresh_similarity = thresh_similarity - dists(nc)/100;
                if thresh_similarity < 0
                  thresh_similarity = 0;
                end
              else
                centers = [centers; shiftdim(currCtx, -1)];
                occ_centers = [occ_centers, 1];
                if debug_mode
                  fprintf('center added\n');
                end
              end
            else
              if debug_mode
                if ~cond1
                  fprintf('dist %f !< thr_sim %f\n', dists(nc)/numel(currCtx), thresh_similarity);
                end
                if ~cond2
                  fprintf('var(dists) %f !> thr_var %f\n', var(dists_norm), thresh_variance);
                end
                if ~cond3
                  fprintf('occs %f !< thr_occ %f\n', occ_centers(nc), thresh_occ);
                end
              end
              thresh_similarity = thresh_similarity + dists(nc)/10;
              thresh_variance = thresh_variance/2;
              if thresh_similarity > 1
                thresh_similarity = 1;
              elseif thresh_variance == 0
                thresh_variance = 1;
              end

              centers = [centers; shiftdim(currCtx, -1)];
              occ_centers = [occ_centers, 1];
              if debug_mode
                fprintf('center added\n');
              end
            end
          end
        else
            nb_discarded_events = nb_discarded_events+1
        end

        if size(centers,1) > 2*params.nbCenters
          if debug_mode
            warning('too much centers, merging.')
          end
          thresh_variance = thresh_variance * 2^params.nbCenters;
          [centers, occ_centers] = merge_centers(centers, occ_centers, params.nbCenters);
        end
        if debug_mode
          drawnow;
          %pause();
        end

    % for ind = 1:size(centers,1)
    %   if numel(find(centers(ind,:)>thresh_relevant_pixel_surface)) < 1
    %     plot_centers(old_centers)
    %     plot_centers(centers)
    %     pause
    %   end
    % end
  else
    %% Fire events
    new_events.p(idx_ev) = nc-1;
  end
end

if size(centers,1) < params.nbCenters
  warning(['Made ', num2str(size(centers,1)), ' centers, less than the ', ...
    num2str(params.nbCenters), ' expected.'])
    nb_centers_to_add = (params.nbCenters-size(centers,1));
  for ind = 1:nb_centers_to_add
    centers = [centers; centers(end,:,:)];
  end
end
if learning
  [centers, occ_centers] = merge_centers(centers, occ_centers, params.nbCenters);
  numel(events.ts)
  occ_centers
  nb_discarded_events
  sum(occ_centers)+nb_discarded_events
end
fprintf('Took %3.2f seconds\n', toc(tstart))
end

function [centers, occ_centers] = merge_centers(centers, occ_centers, nbC)
while size(centers,1)~=nbC
  similarities = inf(size(centers,1));
  for ind = 1:size(centers,1)
    curr_center = centers(ind,:);
    for ind2 = (ind+1):size(centers,1)
      center_to_compare = centers(ind2,:);

      similarities(ind, ind2) = -log(sum(sqrt(centers(ind,:) .* centers(ind2,:)) / ...
        sqrt(sum(centers(ind,:)) * sum(centers(ind2,:)))));
    end
  end
  [~, ind1] = min(min(similarities));
  [~, ind2] = min(min(similarities'));
  if ind1 == ind2
    imagesc(similarities)
    min(similarities(:))
    idx
    size(centers,1)
    ind1
    ind2
    warning('wtf')
    pause
  end
  centers(ind1,:) = 0.5*centers(ind1,:)+0.5*centers(ind2,:);
  centers(ind2,:,:) = [];
  occ_centers(ind1) = occ_centers(ind1) + occ_centers(ind2);
  occ_centers(ind2) = [];
end
end
