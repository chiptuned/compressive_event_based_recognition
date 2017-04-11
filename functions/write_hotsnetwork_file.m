function [status] = write_hotsnetwork_file(params, filename)

if ~isfield(params,'viewer')
  warning_msg = [inputname(1), '.viewer does not exist. Disabling viewer...'];
  warning(warning_msg);
  params.viewer = 0;
  params.viewer_port = 3333;
  params.viewer_refresh_seconds = 6;
end

fid = fopen(filename, 'w');
headerline = '% Hotsnetwork file generated with Matlab';
fprintf(fid,'%s\n', headerline);
headerline = ['% Generated : ', datestr(now)];
fprintf(fid,'%s\n\n', headerline);

% Viewer
fprintf(fid,'%d %d %d\n', ...
  params.viewer, params.viewer_port, params.viewer_refresh_seconds);

% Input
fprintf(fid,'%d %d ', ...
    params.nbPols, numel(params.nbChannels));
dims = [];
for ind = 1:numel(params.nbChannels);
  dims = [dims, num2str(params.nbChannels(ind)), ' '];
end
fprintf(fid,'%s\n', dims);

% layers
fprintf(fid,'%d', params.nbLayers);
for ind = 1:params.nbLayers
  layer = [' / ', num2str(params.nbCenters(ind)), ...
    ' ', num2str(params.tau(ind)), ...
    ' ', num2str(params.radius(ind))];
  fprintf(fid,'%s', layer);
end
fprintf(fid,'\n');

name_files = [];
for ind = 1:3
  name_files = [name_files ,params.eventsname{ind}, ' '];
end
fprintf(fid,'%s\n', name_files);
name_files = [];
for ind = 1:params.nbLayers
  name_files = [name_files , 'centersOfLayer',num2str(ind),'.txt '];
end
fprintf(fid,'%s\n', name_files);

fclose(fid);
status = 1;
