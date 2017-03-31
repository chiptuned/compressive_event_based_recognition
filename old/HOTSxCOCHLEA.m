create_events_corpus
clearvars -except events labels full_filenames;

%% Gammatonegramme
[d,sr] = audioread([full_filenames{1},'.wav']);
[D,F] = gammatonegram(d,sr);

%% Hots
nbLayers = 1;
nbCenters = numel(F);
tau = 200;
radius = 8; % BM

params.ksi = 2e-4;
params.nPow = 3;
params.nbChannels = 400;
params.nbPols = numel(unique(events.p));
params.nbCenters = nbCenters;
params.tau = tau;
params.radius = radius;
params.max_loops = 0;

params.learning = true;
[~, new_centers] = hotsND(events, [], params);
params.learning = false;
params.hotsogram = true;j
[new_events, ~, eventogram] = hotsND(events, new_centers, params);
occs = occurancies_centers(new_centers, new_events);

%% Hotsogrammes centres/temps par pas de 10ms
nb_bin = size(D,2);
hotsogram = zeros(size(eventogram,2), nb_bin);
hotsogram2 = zeros(size(eventogram,2), nb_bin);

for ind = 1:nb_bin
  
  condsup = (events.ts>=((ind-1)*10000));
  condinf = (events.ts<(ind*10000));
  idx_ev = find(condsup.*condinf);
  if ~(isempty(idx_ev))
     if numel(idx_ev) == 1
        hotsogram(:,ind) = exp(-eventogram(idx_ev,:));
     else
        hotsogram(:,ind) = sum(exp(-eventogram(idx_ev,:)))/numel(idx_ev);
     end
     for ind2 = 1:nbCenters
         hotsogram2(ind2,ind) = numel(find(new_events.p(idx_ev) == (ind2-1)));
     end
  end
end

%% Magie noire
mat_gammatone = zeros(size(D));
mat_hots = zeros(size(D));
g_lim = [-90, -30]; % des db
h_lim = [0, 0.24]; % lin, plus ou moins

idx_g = find((20*log10(D) > g_lim(1)) .* (20*log10(D) < g_lim(2)));
idx_h = find((hotsogram > h_lim(1)) .* (hotsogram < h_lim(2)));

mat_gammatone(idx_g) = (20*log10(D(idx_g))-g_lim(1))/(g_lim(2)-g_lim(1));
mat_hots(idx_h) = (hotsogram(idx_h)-h_lim(1))/(h_lim(2)-h_lim(1));

figure;
subplot(211)
imagesc(mat_gammatone); colorbar
title('Gammatonegramme avec normalisation')
subplot(212)
imagesc(mat_hots); colorbar
title('Hotsogramme avec normalisation')

%% Similarités
sum_similarities = zeros(nbCenters);
% figure;
% imgsc = imagesc(sum_similarities); colorbar; axis xy; axis square;
% xlabel('hots centers');
% ylabel('frequency bands');
for ind = 1:nb_bin
    simmat = compute_similarity_matrix(mat_gammatone(:,ind), ...
        mat_hots(:,ind));
    sum_similarities = sum_similarities + simmat;
%     imgsc.CData = simmat;
%     drawnow;
end

[idx_centers] = compute_columns_order(sum_similarities);

%% Affichages

figure
subplot(311)
% Load a waveform, calculate its gammatone spectrogram, then display:
imagesc(20*log10(D)); axis xy
caxis(g_lim)
colorbar
% F returns the center frequencies of each band;
% display whichever elements were shown by the autoscaling
set(gca,'YTickLabel',round(F(get(gca,'YTick'))));
ylabel('freq / Hz');
xlabel('time / 10 ms steps');
title('Gammatonegram - fast method')

subplot(312)
imagesc(log(hotsogram2(idx_centers,:))); colorbar; axis xy
ylabel('center');
xlabel('time / 10 ms steps');
title(['Hots - output of layer, ', num2str(nbCenters), ' centers'])

subplot(313)
imagesc(hotsogram(idx_centers,:)); colorbar; axis xy
set(gca,'YTickLabel',idx_centers);
ylabel('center');
xlabel('time / 10 ms steps');
title('Hots - pondérations des ativations pour chaque centre de chaque event')
caxis(h_lim) % a virer