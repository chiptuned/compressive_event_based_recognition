clear variables;
close all;
nb_levels = 128;

logs = logspace(0,1,nb_levels/2);
logs = (logs-1)/18;
logs = [logs, -logs] + 0.5;

logs = sort(logs,'ascend');

x_vect = 1:10;
for ind = 1:numel(logs)
    plot(x_vect,repmat(logs(ind), numel(x_vect)),'*-');
    hold on;
end