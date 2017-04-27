function [events, fe] = convert_timit_to_event(filename, nb_levels, mode)
% A MODIFIER

if ~exist('mode', 'var')
  mode = 0;
end

dat_name = [filename(1:end-3), 'dat'];
[x,fe] = audioread(filename);%, 'native');

if mode == 0
  % Le mode fait comme ceci est très dépend du type des fichiers timit et également
  % du mono.
  % on pourrait lire le header afin de scaler correctement
  x = (x/max(abs(x))+1)*2^15;
  x = uint16(floor(x));
  events = levelcrossing(x, fe, nb_levels);
  events.channel = zeros(size(events.ts));
elseif strcmp(mode, 'cochlea_levelcrossing')
  % Cochlea events
  THOP = 0.010;
  min_scale = -150; %dB
  max_scale = 0; %dB
  db_step = 5; %dB

  [D,F] = gammatonegram(x,fe,0.025,0.010,nb_levels,50,fe/2,1,1.0);
  thresh = 1e-3; % wtfbbq
  delta_per = 0.05; % percentage of increase between levels

  N_levels = ceil(-log(thresh)/log(1+delta_per))
  levels = logspace(log10(thresh),0,N_levels)

  t1=[0:length(x)-1]/fe;
  t2 = (0:length(D(1,:))-1)*max(t1)/length(D(1,:));
  events.ts = [];
  events.level = [];
  events.p = [];

  level_crossed = zeros(1,N);
  for n = 1:length(D(1,:))
      for k = 1:N
          if D(k,n) > levels(level_crossed(k)+1)        % ON event
              level_crossed(k) = level_crossed(k) + 1;
              events.ts = [events.ts round(t2(n)*1e6)];
              events.level = [events.level k];
              events.p = [events.p 0];
          elseif level_crossed(k) > 1
              if D(k,n) < levels(level_crossed(k))        % OFF events
                  level_crossed(k) = level_crossed(k) - 1;
                  events.ts = [events.ts round(t2(n)*1e6)];
                  events.level = [events.level k];
                  events.p = [events.p 1];
              end
          end
      end
  end
  events.channel = zeros(size(events.ts));

elseif strcmp(mode, 'cochlea_integrate_and_fire')
  % Cochlea events
  THOP = 0.010;
  min_scale = -150; %dB
  max_scale = 0; %dB
  db_step = 5; %dB

  [D,F] = gammatonegram(x,fe,0.025,0.010,nb_levels,50,fe/2,1,1.0);

  logD = 20*log10(D);
  nb_levels_levelcrossing = round((max_scale-min_scale)/db_step);

  if (min(logD(:)) < min_scale)
    msg = [num2str(min(logD(:))), ' < ', num2str(min_scale)];
    throw(msg)
  elseif (max(logD(:)) > max_scale)
    msg = [num2str(max(logD(:))), ' < ', num2str(max_scale)];
    throw(msg)
  end

  events.ts = [];
  events.level = [];
  events.p = [];

  for ind = 1:nb_levels
    data = logD(ind,:);
    data = uint16(floor((data-min_scale)/(max_scale-min_scale)*2^16));
    events_curr = levelcrossing(data, 1/THOP, nb_levels_levelcrossing);

    events.ts = [events.ts; events_curr.ts];
    events.level = [events.level; (ind-1)*ones(size(events_curr.ts))];
    events.p = [events.p; events_curr.p];
  end
  [events.ts, sortidx] = sort(events.ts, 'ascend');
  events.level = events.level(sortidx);
  events.p = events.p(sortidx);
  events.channel = zeros(size(events.ts));

elseif strcmp(mode, 'spikegram')
  % Cochlea events
  THOP = 0.010;
  min_scale = -150; %dB
  max_scale = 0; %dB
  db_step = 5; %dB

  [D] = gammatonegram(x,fe,0.025,0.010,nb_levels,50,fe/2,1,1.0);

  threshold = 5e-5;
  t2 = (0:length(D(1,:))-1)*THOP*1e6;
  integ(:,1) = D(:,1)*THOP;

  events.ts = [];
  events.level = [];

  for k = 1:nb_levels
      for n=2:length(t2)
          integ(k,n) = integ(k,n-1) + D(k,n)*THOP;
          if integ(k,n) > threshold
              integ(k,n) = 0;
              events.ts = [events.ts; t2(n)];
              events.level = [events.level; k-1];
          end
      end
  end
  events.ts = round(events.ts);
  [events.ts, sortidx] = sort(events.ts, 'ascend');
  events.level = events.level(sortidx);
  events.p = zeros(size(events.ts));
  events.channel = zeros(size(events.ts));

elseif strcmp(mode, 'spikegram_jittered')
  % Cochlea events
  THOP = 8e-4;
  min_scale = -150; %dB
  max_scale = 0; %dB
  db_step = 5; %dB
  jitter_microseconds = floor(1e6/fe); %should be > nbChannels

  [D] = gammatonegram(x,fe,0.025,THOP,nb_levels,50,fe/2,1,1.0);

  threshold = 5e-5;
  t2 = (0:length(D(1,:))-1)*THOP*1e6;
  integ(:,1) = D(:,1)*THOP;
  
  events.ts = [];
  events.level = [];

  for k = 1:nb_levels
      for n=2:length(t2)
          integ(k,n) = integ(k,n-1) + D(k,n)*THOP;
          if integ(k,n) > threshold
              integ(k,n) = 0;
              events.ts = [events.ts; t2(n)+randi(jitter_microseconds,1)];
              events.level = [events.level; k-1];
          end
      end
  end
  events.ts = round(events.ts);
  [events.ts, sortidx] = sort(events.ts, 'ascend');
  events.level = events.level(sortidx);
  events.p = zeros(size(events.ts));
  events.channel = zeros(size(events.ts));

elseif strcmp(mode, 'spikegram_prob')
  % Cochlea events
  THOP = 8e-4;
  min_scale = -150; %dB
  max_scale = 0; %dB
  db_step = 5; %dB
  jitter_microseconds = floor(1e6/fe); %should be > nbChannels
  nb_tries_spikegram = 10;

  [D,F] = gammatonegram(x,fe,0.025,THOP,nb_levels,50,fe/2,1,1.0);
     for ind = 1:1
     subplot(1,1,ind)
     imagesc(20*log10(D)); axis xy
     g_lim = [-90, -30];
     caxis(g_lim)
     colorbar;
     % F returns the center frequencies of each band;
     % display whichever elements were shown by the autoscaling
     set(gca,'YTickLabel',round(F(get(gca,'YTick'))));
     ylabel('freq / Hz');
     xlabel('time / 10 ms steps');
     title('Gammatonegram - fast method')
     end

  D = (D - min(D(:)))/max(D(:));
  res = zeros(size(D));
  for ind = 1:nb_tries_spikegram
    random_mat = rand(size(D));
    res(random_mat<D) = res(random_mat<D) + 1;
  end

  events.ts = [];
  events.level = [];
  events.p = [];
  for ind = 1:size(D,2) % for each col
    events_col_level = [];
    events_col_p = [];
    for ind2 = 1:size(D,1) % for each level
      if res(ind2,ind) > 0
        events_col_level = [events_col_level, ind2-1];
        events_col_p = [events_col_p, res(ind2,ind)-1];
      end
    end
    jitters = randperm(jitter_microseconds, numel(events_col_p));
    timestamp_jittered = THOP*1e6*ind+jitters;
    [ts_sorted, idx_sort] = sort(timestamp_jittered, 'ascend');
    events.ts = [events.ts, ts_sorted];
    events.level = [events.level, events_col_level(idx_sort)];
    events.p = [events.p, events_col_p(idx_sort)];
  end
    figure;
  plot_events(events, hot(numel(unique(events.p))))
  pause

elseif strcmp(mode, 'test')
  % Cochlea events
  THOP = 1/fe;
  min_scale = -150; %dB
  max_scale = 0; %dB
  db_step = 5; %dB
  [D,F] = gammatonegram(x,fe,0.025,THOP,nb_levels,50,fe/2,1,1.0);
  max(D(:))
  min(D(:))
  % % test les events en sortie du gamatonegram
   % Load a waveform, calculate its gammatone spectrogram, then display:
   for ind = 1:1
     subplot(1,1,ind)
     imagesc(20*log10(D)); axis xy
     g_lim = [-90, -30];
     caxis(g_lim)
     colorbar;
     % F returns the center frequencies of each band;
     % display whichever elements were shown by the autoscaling
     set(gca,'YTickLabel',round(F(get(gca,'YTick'))));
     ylabel('freq / Hz');
     xlabel('time / 10 ms steps');
     title('Gammatonegram - fast method')
   end
   pause
 % subplot(312)
 %  hold on;
 %  plot(events.ts/1e4, events.level+1, '.r');
 %  subplot(313)
 %   hold on;
 %   plot(spike2.t*100,spike2.channel, '.r');
 %   pause
end
