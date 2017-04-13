clearvars;
close all force;

addpath('functions')
curr_data_folder = 'hots_data_chirp_testSUPERCENTERS';
path_data = fullfile(pwd, curr_data_folder);

aff = 1;
nb_levels_crossing = 50;
fs = 1e4;
t_train_hots = 0:1/fs:5;
t_train = 0:1/fs:10;
t_test = 0:1/fs:30;
data_train_hots = chirp(t_train_hots,1,10,100);
data_train_hots = uint16(floor((data_train_hots/max(abs(data_train_hots))+1)*2^15));
data_train = chirp(t_train,1,30,100);
data_train = uint16(floor((data_train/max(abs(data_train))+1)*2^15));
data_test = chirp(t_test,1,60,100);
data_test = uint16(floor((data_test/max(abs(data_test))+1)*2^15));
events_train_hots = levelcrossing( data_train_hots, fs, nb_levels_crossing );
events_train = levelcrossing( data_train, fs, nb_levels_crossing );
events_test = levelcrossing( data_test, fs, nb_levels_crossing );

figure;
plot(t_train_hots, data_train_hots, '.')
figure;
sbp1 = subplot(311);
plot_events(events_train_hots);
sbp2 = subplot(312);
plot_events(events_train);
sbp3 = subplot(313);
plot_events(events_test);
linkaxes([sbp1, sbp2, sbp3]);

params.path_data = path_data;
params.viewer = 0;
params.viewer_port = 3334;
params.viewer_refresh_seconds = 6;
params.nbLayers = 2;
params.nbCenters = [8, 16, 64, 32, 64];
params.tau = [1000., 100000., 16000., 64000., 256000.];
params.radius = [5, 15, 25, 35, 45];
params.nbDim = 1;
params.nbChannels = nb_levels_crossing;

% events_train_hots.p = zeros(size(events_train_hots.p));
% events_train.p = zeros(size(events_train.p));
% events_test.p = zeros(size(events_test.p));
params.nbPols = numel(unique(events_train_hots.p));

% compute_generichots(params, events_train_hots, events_train, events_test);
% return;
% [centers, events, events2] = read_generichots_output(params);

[centers, events] = compute_matlab_hots(params, events_train_hots, events_train, events_test);
ceil(100*density_centers(centers))

if aff
  occs = cell(1,params.nbLayers);

  nb_plots = numel(events);
  if nb_plots > 4
    nb_plots_x = 2;
    nb_plots_y = ceil(nb_plots/2);
  else
    nb_plots_x = 1;
    nb_plots_y = nb_plots;
  end

  handle_subp = [];
  figure;
  for ind = 1:nb_plots
    handle_subp(ind) = subplot(nb_plots_y,nb_plots_x,ind);
    plot_events(events{ind});
    if ind == 1
      title('input');
    else
      title(['output of layer ', num2str(ind)-1]);
    end
  end
  linkaxes(handle_subp);

  for ind = 1:params.nbLayers
    occs(ind) = {occurancies_centers(centers{ind}, events{ind+1})};
    plot_centers(centers{ind}, occs{ind}, 8);
    plot_centers_temporal(centers{ind}, occs{ind}, params.tau(ind));
  end
end
