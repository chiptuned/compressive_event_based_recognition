function plot_centers(centers, occ, rep)

cpt = 0;
nc = size(centers,1);
np = size(centers,2);
dim = numel(size(centers))-2;

if exist('occ','var')
    occ = occ/sum(occ);
end
if numel(size(centers))-2 > 1
    error('pas encore codé pour events > 1 dim')
end

if dim == 1
    x_max = 4;
    y_max = 8;
    reply = 'Y';
    bad_size_plots = nc > x_max || np > y_max;
    too_much_plots = (nc*np) > (x_max*y_max*3);
if too_much_plots
        if exist('rep','var')
            if rep < ceil(nc*np/(x_max*y_max))
                reply = 'N';
            else
                reply = 'Y';
            end
        else
           commandwindow
           string = ['Display ', num2str(nc), ...
               ' centers of ', num2str(np), ' polarities (takes ', ...
               num2str(ceil(nc*np/(x_max*y_max))), ...
               ' figures)? Y/N [N]:'];
           reply = input(string,'s');
           if isempty(reply)
              reply = 'N';
           end
        end
    end
    if reply == 'Y'
        for ind_c = 1:nc
          for ind_p = 1:np
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
            curr_pol_center = centers(ind_c,ind_p,:);
            radius = floor(size(centers,3)/2);
            plot((-radius:radius),curr_pol_center(:), '*-');
            str_title = ['c', num2str(ind_c), ' | p', num2str(ind_p)];
            if exist('occ','var')
                str_title = [str_title, ' | ', num2str(round(occ(ind_c)*100)), '%'];
            end
            title(str_title);
            axis([-radius radius 0 1]);
          end
        end
    end
end
drawnow;