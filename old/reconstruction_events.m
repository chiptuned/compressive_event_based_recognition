function reconstruction_events(events, new_events, new_centers, params)

tau = params.tau;
cpt_ev = 0;
for ind = 1:size(new_centers,1)
    elem_center = find(new_events.p == ind-1);
    for ind2 = 1:size(new_centers,2)
        elem_pol = events.p(elem_center);
        nb_elem_pol = numel(find(elem_pol == ind2-1));
        curr_feats_center_ts = new_centers(ind,ind2,:);
        cpt_ev = cpt_ev + sum(isfinite(curr_feats_center_ts(:)))*nb_elem_pol;
    end
end

ev_t = zeros(1,cpt_ev);
ev_val = zeros(1,cpt_ev);
ev_pol = zeros(1,cpt_ev);
radius = (numel(curr_feats_center_ts)-1)/2;

cpt = 0;
for ind = 1:size(new_centers,1)
    ts_events = new_events.ts(new_events.p == ind-1);
    p_events = events.p(new_events.p == ind-1);
    val_events = events.level(new_events.p == ind-1);
    for ind2 = 1:size(new_centers,2)
        events_to_index_ts = ts_events(p_events==ind2-1);
        events_to_index_val = val_events(p_events==ind2-1);
        curr_feats_center_ts = new_centers(ind,ind2,:);
        curr_feats_center_ts = -tau*log(curr_feats_center_ts(:));
        curr_feats_center_rad = -radius:radius;
        finite_samples_val = find(curr_feats_center_ts~=inf);
        for ind3 = 1:numel(events_to_index_ts)
            for ind4 = 1:numel(finite_samples_val)
                cpt = cpt + 1;
                ev_t(cpt) = events_to_index_ts(ind3)-curr_feats_center_ts(finite_samples_val(ind4));
                ev_val(cpt) = events_to_index_val(ind3)+curr_feats_center_rad(finite_samples_val(ind4));
                ev_pol(cpt) = ind-1;
            end
        end
    end
end

occs = occurancies_centers(new_centers, new_events);
    
nb_good_centers = sum(occs>0);
cmap = distinguishable_colors(nb_good_centers);
legend_str = cell(1,nb_good_centers);
figure;
cpt = 0;
for ind = find(occs>0)
    cpt = cpt+1;
    hold on;
    plot(ev_t(ev_pol==ind-1),ev_val(ev_pol==ind-1),'*', 'Color', cmap(cpt,:));
    legend_str{cpt} = num2str(ind);
end
legend(legend_str);
hold off;
