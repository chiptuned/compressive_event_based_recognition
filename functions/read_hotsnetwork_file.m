function [params] = read_hotsnetwork_file(filename)

fid = fopen(filename, 'r');
data = [];
while ~feof(fid)
  line = fgetl(fid)
  numel(line)
  if numel(line) > 0
    if line(1) ~= '%'
      data = [data; {line}]
    end
  end
end

if numel(data) ~= 3
  error('There must be 3 lines in the .hotsnetwork file')
else
  viewer_data = str2num(data{1});
  params.viewer = viewer_data(1);
  params.viewer_port = viewer_data(2);
  params.viewer_refresh_seconds = viewer_data(3);

  input_specs = str2num(data{2});
  params.nbPols = input_specs(1);
  params.nbDim = input_specs(2);
  params.nbChannels = input_specs(3:2+input_specs(2));

  pos_slashs = regexp(data{3},'/');
  params.nbLayers = numel(pos_slashs);
  data{3}(pos_slashs) = [];
  data_layers = str2num(data{3});
  if data_layers(1) ~= params.nbLayers
    error('The number of layers must be the number of slashes in the line')
  end
  params.nbCenters = zeros(1,params.nbLayers);
  params.tau = zeros(1,params.nbLayers);
  params.radius = zeros(1,params.nbLayers);
  for ind = 1:params.nbLayers
    params.nbCenters(ind) = data_layers(1+(ind-1)*3+1);
    params.tau(ind) = data_layers(2+(ind-1)*3+1);
    params.radius(ind) = data_layers(3+(ind-1)*3+1);
  end
end
fclose(fid);
