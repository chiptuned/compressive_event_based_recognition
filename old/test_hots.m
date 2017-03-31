create_events_corpus
clearvars -except events labels;

fprintf('Dataset contains %d events.\n', numel(events.ts));
%events.p = zeros(size(events.p));

figure;
for ind = 1:2
    hold on;
    plot(events.ts(events.p==ind-1),events.level(events.p==ind-1),'*');
end
%axis([6.48e5 6.71e5 0 130])
legend({'OFF', 'ON'});
xlabel('Time in microseconds')
ylabel('Level')
title(['Output of layer 0'])
drawnow;
hold off;

nbLayers = 1;
nbCenters = 16;
tau = 500;
radius = 8;

params.ksi = 2e-4;
params.nPow = 3;
params.nbChannels = 400;
% params.seed = 674;%randi(1000,1)

all_centers = cell(1,nbLayers);
all_occs = cell(1,nbLayers);

for layer = 1:nbLayers
    fprintf('\nLayer %d\n', layer)
    %% HoTS
    if layer == 1
        params.nbPols = numel(unique(events.p));
    else
        params.nbPols = params.nbCenters;
    end
    params.nbCenters = nbCenters*2^(layer-1);
    params.tau = tau*2^(layer-1);
    params.radius = radius*2^(layer-1);
    
    params.learning = true;
    if layer == 1
        [~, new_centers] = hotsND(events, [], params);
        params.learning = false;
        [new_events, ~] = hotsND(events, new_centers, params);
    else
        [~, new_centers] = hotsND(new_events, [], params);
        params.learning = false;
        [new_events, ~] = hotsND(new_events, new_centers, params);
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