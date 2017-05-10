function centers = read_centers2D(filename, params)

fid = fopen(filename, 'r');
header = fgetl(fid);
if strncmp(header, '% V2', 4)
  center_version = 2;
elseif strncmp(header, 'Header', 6)
  center_version = 1;
else
  throw;
end
if center_version == 1
  tmp = str2num(fgetl(fid));
  Ndim = tmp(1);
  tmp = str2num(fgetl(fid));
  nCenters = tmp(1);
  nbFeats = tmp(2);
  if nCenters == params.nbCenters(1)
      NPols = params.nbPols;
  else
      NPols = params.nbCenters(find(nCenters==params.nbCenters,1)-1);
  end
  radius = (sqrt(nbFeats/NPols)-1)/2;
  centers = zeros(nCenters, NPols, 2*radius+1, 2*radius+1);
  for ind = 1:nCenters
    line = str2num(fgetl(fid));
    for ind2 = 1:NPols
      centers(ind,ind2,:) = line((((2*radius+1).^2)*(ind2-1))+(1:((2*radius+1).^2)));
    end
  end
elseif center_version == 2

  splittedstr = strsplit(header,'generated ');
  date = splittedstr{2};
  splittedstr = strsplit(fgetl(fid),'Event files used : ');
  event_file_used = splittedstr{2};
  fgetl(fid);
  fgetl(fid);
  tmp = fgetl(fid);
  tmp = str2num(tmp(2:end));
  layer_of_this_file = tmp(1);
  n_dim_events = tmp(2);
  max_dims_events = tmp(3);
  fgetl(fid);

  nPols = zeros(1,layer_of_this_file);
  nCenters = zeros(1,layer_of_this_file);
  tau = zeros(1,layer_of_this_file);
  radius = zeros(1,layer_of_this_file);

  for ind = 1:layer_of_this_file
    tmp = fgetl(fid);
    tmp = str2num(tmp(2:end));
    nPols(ind) = tmp(2);
    nCenters(ind) = tmp(3);
    tau(ind) = tmp(4);
    radius(ind) = tmp(5);
  end

  fgetl(fid);
  fgetl(fid);
  fgetl(fid);
  centers = zeros(nCenters(end), nPols(end), (2*radius(end)+1)^n_dim_events);
  centers(:) = fread(fid,'float=>double');
end
fclose = fopen(fid);
