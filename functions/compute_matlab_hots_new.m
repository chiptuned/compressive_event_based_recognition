function [centers, out_events] = compute_matlab_hots_new(params, events)

fprintf('Learning set contains %d events.\n', numel(events{1}.ts));
out_events = cell(numel(events)-1, params.nbLayers);
centers = cell(1, params.nbLayers);

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
    [~, centers{layer}] = compute_hots_layer_offline(events{1}, [], new_params);
    new_params.learning = false;
    new_events = compute_hots_layer_offline(events{1}, centers{layer}, new_params);
    events{1} = new_events;
    out_events{1, layer} = compute_hots_layer_offline(events{2}, centers{layer}, new_params);
    out_events{2, layer} = compute_hots_layer_offline(events{3}, centers{layer}, new_params);
end
end
