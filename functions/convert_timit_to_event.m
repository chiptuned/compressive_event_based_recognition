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
elseif strcmp(mode, 'cochlea')
  % Cochlea events
  THOP = 0.010;
  min_scale = -150; %dB
  max_scale = 0; %dB
  db_step = 5; %dB

  [D,F] = gammatonegram(x,fe,0.025,0.010,nb_levels,50,fe/2,1,1.0);
  % thresh = 1e-3; % wtfbbq
  % delta_per = 0.05; % percentage of increase between levels
  %
  % N_levels = ceil(-log(thresh)/log(1+delta_per))
  % levels = logspace(log10(thresh),0,N_levels)
  %
  % t1=[0:length(x)-1]/fe;
  % t2 = (0:length(D(1,:))-1)*max(t1)/length(D(1,:));
  % events.ts = [];
  % events.level = [];
  % events.p = [];
  %
  % level_crossed = zeros(1,N);
  % for n = 1:length(D(1,:))
  %     for k = 1:N
  %         if D(k,n) > levels(level_crossed(k)+1)        % ON event
  %             level_crossed(k) = level_crossed(k) + 1;
  %             events.ts = [events.ts round(t2(n)*1e6)];
  %             events.level = [events.level k];
  %             events.p = [events.p 0];
  %         elseif level_crossed(k) > 1
  %             if D(k,n) < levels(level_crossed(k))        % OFF events
  %                 level_crossed(k) = level_crossed(k) - 1;
  %                 events.ts = [events.ts round(t2(n)*1e6)];
  %                 events.level = [events.level k];
  %                 events.p = [events.p 1];
  %             end
  %         end
  %     end
  % end
  % events.channel = zeros(size(events.ts));

  %plot(20*log10(D(1,:)))
  %xlim([1 numel(D(1,:))])

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
end
