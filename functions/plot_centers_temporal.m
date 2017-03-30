function [centers_temporal] = plot_centers_temporal(centers, occ, tau, rep)

THRESH_CONV = 1e-2;
cpt = 0;
nc = size(centers,1);
np = size(centers,2);
dim = numel(size(centers))-2;

if numel(size(centers))-2 > 1
    error('pas encore codé pour events > 1 dim')
end

centers_temporal = centers;

if dim == 1
    x_max = 4;
    y_max = 8;
    reply = 'Y';
    bad_size_plots = nc > x_max || np > y_max;
    too_much_plots = (nc) > (x_max*y_max*3);
    if too_much_plots
        if exist('rep','var')
            if rep < ceil(nc/(x_max*y_max))
                reply = 'N';
            else
                reply = 'Y';
            end
        else
           commandwindow
           string = ['Display ', num2str(nc), ' centers (takes ', ...
               num2str(ceil(nc/(x_max*y_max))), ' figures)? Y/N [N]:'];
           reply = input(string,'s');
           if isempty(reply)
              reply = 'N';
           end
        end
    end
    if reply == 'Y'
        for ind_c = 1:nc
          
            if mod(cpt,x_max*y_max)==0
                figure;
                cpt = 0;
            end
            cpt = cpt + 1;
            if ~bad_size_plots
                subplot(nc, np, cpt)
            else
                subplot(y_max, x_max, cpt) %scrollsubplot? calculer x et y
            end
            for ind_p = 1:np
                curr_pol_center = centers(ind_c,ind_p,:);
                radius = floor(size(centers,3)/2);

                curr_pol_center = -tau*log(curr_pol_center);
                [~, comb] = sort(curr_pol_center, 'descend');
                curr_pol_center = curr_pol_center(comb);
    %             curr_pol_center(:)
                centers_temporal(ind_c,ind_p,:,1) = curr_pol_center(:);

                plot(-curr_pol_center(:)*1e-4, comb(:)-radius-1, '*');
                hold on;
    %             xlabel('Time in microseconds')
    %             ylabel('Level')

                str_title = ['c', num2str(ind_c), ' | p', num2str(ind_p)];
                if exist('occ','var')
                    str_title = [str_title, ' | ', num2str(occ(ind_c))];
                end
                title(str_title);
                axis([tau*log(THRESH_CONV)*1e-4 0 -radius radius]);
            end
            hold off;
        end
        
    end
end
drawnow;