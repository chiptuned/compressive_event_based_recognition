create_events_corpus
clearvars -except events;

events.p = zeros(size(events.p));

params.tau = 10000;
ksis = 2.^(1:6)*1e-4;
params.nPow = 3;
params.nbPols = numel(unique(events.p));
nbCenters = 8:4:16; % FIXME : Trier les scores selon la répartition en nombre de centres
radius = 4:4:20;
params.nbChannels = 2048;

nb_tries = 20;
seed_tries = randperm(10000,nb_tries);

total_tries = numel(radius)*numel(nbCenters)*numel(ksis)*nb_tries;
finish = clock;
finish(end) = finish(end)+2.2*total_tries;
fprintf('Will finish near %s\n',datetime(finish))

cpt_tries = 0;
mat_std = zeros(numel(radius),numel(nbCenters), numel(ksis), nb_tries);
mat_seed = zeros(numel(radius),numel(nbCenters), numel(ksis), nb_tries);
bar = waitbar(0, 'Computing events');

for rad_idx = 1:numel(radius)
  params.radius = radius(rad_idx);
  for nc_idx = 1:numel(nbCenters)
    params.nbCenters = nbCenters(nc_idx);
    for ksi_idx = 1:numel(ksis)
      params.ksi = ksis(ksi_idx);
      for curr_try = 1:nb_tries
          cpt_tries = cpt_tries + 1;
          params.seed = seed_tries(curr_try);
          params.learning = true;
          params.loops = 1;
          [~, new_centers] = hotsND(events, [], params);
          params.learning = false;
          [new_events, ~] = hotsND(events, new_centers, params);
          occs_centers = occurancies_centers(new_centers, new_events);
          mat_occs(rad_idx,nc_idx,ksi_idx,curr_try) = std(occs_centers);
          mat_seed(rad_idx,nc_idx,ksi_idx,curr_try) = seed_tries(curr_try);
          waitbar(cpt_tries/total_tries,bar);
      end
    end
  end
end
delete(bar);
save('test_rng.mat','mat_occs', 'mat_seed');
