clear all;
close all;

if isunix
    path_data = '/home/vincent/idv/matlab_hots/hots_data';
    if exist(path_data, 'dir') == 0
        mkdir(path_data);
    end
else
    error('No hardcoded path specified for non-unix (filename_events)');
end

file_ev = fullfile(path_data, 'events_input.dat');
% Specify the event format
events = load_audio_data(file_ev);

% Make the parameters struct
h = fopen(fullfile(path_data,'params.hots'), 'rb');
nbL = fread(h, 1, 'int32');
nbLayers = nbL;
nbCenters = fread(h, nbL, 'int32');
tau = fread(h, nbL, 'int32');
radius = fread(h, nbL, 'int32');
ksi = fread(h, nbL, 'int32');
nPow = fread(h, 1, 'int32');
nbDim = fread(h, 1, 'int32');
nbChannels = fread(h, nbDim, 'int32');
typeCenters = fread(h, 1, 'int32');
nbPols = fread(h, 1, 'int32');
fclose(h);

fprintf('Dataset contains %d events.\n', numel(events.ts));

for layer = 1:nbLayers
    fprintf('\nLayer %d\n', layer)
    
    %% HoTS
    %params_layer.nbDim = nbDim; %useless, because nbChannels carries this info
    params_layer.nbChannels = nbChannels;
    params_layer.nPow = nPow;

    if layer == 1
        params_layer.nbPols = nbPols;
    else
        params_layer.nbPols = nbCenters(layer-1);
    end

    params_layer.tau = tau(layer);
    params_layer.ksi = ksi(layer);
    params_layer.nbCenters = nbCenters(layer);
    params_layer.radius = radius(layer);
    params_layer.nPow = nPow;
    %params_layer.max_loops = 10;
    %params_layer.seed = randi(1,1000);
    %params_layer.hotsogram = true;

    params_layer.learning = true;
    if layer == 1
        [~, new_centers] = compute_hots_layer(events, [], params_layer);
        params_layer.learning = false;
        [new_events, ~] = compute_hots_layer(events, new_centers, params);
    else
        [~, new_centers] = compute_hots_layer(new_events, [], params);
        params_layer.learning = false;
        [new_events, ~] = compute_hots_layer(new_events, new_centers, params);
    end
    
    
    %% occurancies of polarities & export
    occs = occurancies_centers(new_centers, new_events);
    all_centers(layer) = {new_centers};
    all_occs(layer) = {occs};
    
    %% Displaying event stream
    % A mettre dans une fonction
    nb_good_centers = sum(occs>0);
    cmap = distinguishable_colors(nb_good_centers);
    legend_str = cell(1,nb_good_centers);
    figure;
    cpt = 0;
    for ind = find(occs>0)
        cpt = cpt+1;
        hold on;
        plot(new_events.ts(new_events.p==ind-1),new_events.level(new_events.p==ind-1),'*', 'Color', cmap(cpt,:));
        legend_str{cpt} = num2str(ind);
    end
    axis([6.48e5 6.71e5 0 130])
    legend(legend_str);
    xlabel('Time in microseconds')
    ylabel('Level')
    title(['Output of layer ', num2str(layer)])
    hold off;
    
    
    %% Displaying centers (time surfaces & temporal)
    plot_centers(new_centers, occs);
    centers_temporal = plot_centers_temporal(new_centers, occs, params);
    
    figure;
    plot((1:params.nbCenters)-1,occs)
    xlabel('Polarities');
    ylabel('Number of events');
    title('Distribution of events across polarities');
    axis([0, params.nbCenters-1, 0, max(occs)]);
    drawnow;
    
    %% Event-stream reconstruction
    %reconstruction_events(events, new_events, centers_temporal, params);

    %% Classifier
    figure;
    imagesc(hots_reco(new_events, labels, params))
    xlabel('Center');
    ylabel('Phoneme');
    title(['Signatures of Layer ', num2str(layer)]);
    colorbar;
    drawnow;
end