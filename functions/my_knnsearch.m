function [IDX,D] = my_knnsearch(X,Y,k,dist)
% Works with 'euclidean' distance with use of knnsearch
% Works with 'bhattacharrya' distance.
% And with use of pdist2 :
% 'euclidean2'
% 'squaredeuclidean'
% 'seuclidean', scaled by dividing NANSTD(X)
% 'cityblock'
% 'minkowski' where the exponent is 2
% 'chebychev'
% 'mahalanobis' using the sample covariance of X : NANCOV(X)
%

if ~exist('k', 'var')
  k = 1;
end

if ~exist('dist', 'var')
  dist = 'euclidean'
end

if nargin == 2
  [IDX,D] = knnsearch(X,Y,'k',1,'distance','euclidean')
elseif strcmp(dist, 'euclidean')
  [IDX,D] = knnsearch(X,Y,'k',k,'distance','euclidean');
elseif (strcmp(dist, 'bhattacharrya') || strcmp(dist, 'euclidean2'))
  if size(X,2) ~= size(Y,2)
    error('explosion')
  end
  num_Y = size(Y,1);
  num_X = size(X,1);
  IDX = zeros(num_Y,k);
  D = zeros(num_Y,k);
  tmp_dists = zeros(num_X,1);
  for elementY = 1:num_Y
    if strcmp(dist, 'bhattacharrya')
      sumY = sum(Y(elementY,:));
      nb_el = numel(Y(elementY,:));
      for elementX = 1:num_X
        sumX = sum(X(elementX,:));
        tmp_dists(elementX) = -log(sqrt(sum(X(elementX,:).*Y(elementY,:)))) + log(sqrt(sumX*sumY));
      end
    elseif strcmp(dist, 'euclidean2')
      tmp_dists = pdist2(X,Y(elementY,:));
    else
      tmp_dists = pdist2(X,Y(elementY,:),dist);
    end
    [val_nearest, idx_nearest] = sort(tmp_dists);

    % if strcmp(dist, 'bhattacharrya') && k>1
    %     X(102,:)
    %     X(207,:)
    %     X(300,:)
    %     X(302,:)
    %     X(708,:)
    %     val_nearest(1:10)'
    %     idx_nearest(1:10)'
    %     pause
    % end

    IDX(elementY,:) = idx_nearest(1:k);
    D(elementY,:) = val_nearest(1:k);
  end
else
  error('wtf?')
end
end
