function [out_ev_array] = dat_to_evarray(out_dat, labels, idx_pres);
% j'en veux plutot autant que out_dat
%
% cellev =  1×3 cell array     {8×3 cell}    {992×3 cell}    {1000×3 cell}
%
% cellev{1} = 8×3 cell array
% [1×1 struct]    [ 4]    [39706]
% [1×1 struct]    [ 1]    [50910]
% [1×1 struct]    [ 6]    [33574]
% [1×1 struct]    [ 7]    [41060]
% [1×1 struct]    [ 6]    [26144]
% [1×1 struct]    [10]    [44993]
% [1×1 struct]    [ 4]    [ 9356]
% [1×1 struct]    [ 5]    [51818]
%
%
% >> cellev{1}{1} =  struct with fields:
%      x: [4871×1 uint8]
%      y: [4871×1 uint8]
%      p: [4871×1 logical]
%     ts: [4871×1 uint32]

out_ev_array = cell(size(out_dat));
for dat = 1:size(out_dat,2)

  % find correspondancies (in no of events) for each struct
  n_pr = numel(idx_pres{dat});
  ev_start = zeros(1,n_pr);
  ev_end = zeros(1,n_pr);
  for ind = 1:n_pr
    ev_start(ind) = find(out_dat{dat, 1}.ts == labels{dat}{ind,1}, 1)
    ev_end(ind) = find(out_dat{dat, 1}.ts == labels{dat}{ind,2}, 1) - 1
    labels{dat}(ind,1)
    labels{dat}(ind,2)
    out_dat{dat, 1}.ts(ev_start(ind))
    out_dat{dat, 1}.ts(ev_end(ind))
    pause
  end

  for layer = 1:size(out_dat,1)
    out_ev_array{dat, layer} = cell(n_pr, 3);
    % putting labels and ids in it
    out_ev_array{dat, layer}(:,2) = labels{dat}(:,3);
    out_ev_array{dat, layer}(:,3) = idx_pres{dat};
    for pres = 1:n_pr
      % faire l'histoire d'extraire les namefields etc
      ev_struct.ts = out_dat{dat, layer}.ts(ev_start(pres):ev_end(pres)) ...
        - labels{dat}(pres,1);
      % for tous les autres namefields
      ev_struct.ts = out_dat{dat, layer}.ts(ev_start(pres):ev_end(pres))
      ev_struct.ts = out_dat{dat, layer}.ts(ev_start(pres):ev_end(pres))
      ev_struct.ts = out_dat{dat, layer}.ts(ev_start(pres):ev_end(pres))
      % voila.
      out_ev_array{dat, layer}{pres,1} = ev_struct;
    end
  end
end
