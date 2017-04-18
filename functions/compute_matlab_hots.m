function [out_centers, out_events] = compute_matlab_hots(params, events_train_hots, events_train, events_test)
    % struct with fields:
    %
    %                path_data: '/home/vincent/idv/matlab_hots/hots_data_chirp_testSUPERCENTERS'
    %                   viewer: 0
    %              viewer_port: 3334
    %   viewer_refresh_seconds: 6
    %                 nbLayers: 3
    %                nbCenters: [4 8 16 32 64]
    %                      tau: [1000 4000 12000 64000 256000]
    %                   radius: [5 15 25 35 45]
    %                    nbDim: 1
    %               nbChannels: 50
    %                   nbPols: 1

fprintf('Dataset contains %d events.\n', numel(events_train.ts));
out_events = cell(1, params.nbLayers+1);
out_events{1} = events_train;
new_params = params;
for layer = 1:params.nbLayers
    fprintf('\nLayer %d\n', layer)

    new_params.nbCenters = params.nbCenters(layer);
    new_params.tau = params.tau(layer);
    new_params.radius = params.radius(layer);

    %% HoTS
    if layer == 1
        new_params.nbPols = params.nbPols;
    else
        new_params.nbPols = params.nbCenters(layer-1);
    end

    new_params.learning = true;
    [~, new_centers] = compute_hots_layer_IIWK_style(events_train_hots, [], new_params);
    new_params.learning = false;
    [new_events, ~] = compute_hots_layer_IIWK_style(events_train_hots, new_centers, new_params);
    events_train_hots = new_events;
    [out_events{layer+1}, out_centers{layer}] = compute_hots_layer_IIWK_style(events_train, new_centers, new_params);
end
end
