close all force;
clearvars;

%% Global Parameters.
firsts_init = 1; % 1 firsts init, 0 is init at 0.5
n_ev_to_gen = 10000000; % nb of event to generate
nb_groups_to_find = randi(10,1);    % nb of groups to generate
n_init = floor(nb_groups_to_find * 1.5); % nb of centers for the processings.

% Random seed?
% 9171 4983 1682 5634 9057 8541 8785
seed = randi(10000,1);
rng(seed)

%% IIWK Parameters
ksi_IIWK = 1e-1;
nPow_IIWK = 3;

%% Processing Standard
n_events_standard_clustering = 20000;

%% Processing JM
n_events_JM_clustering = 20000;
BASELR_JM = 0.1;
trick_init_firsts = true;
trick_reboot_centers = false;

%% Script
covs = rand([2, 2, nb_groups_to_find])/2;
data = [];
for ind = 1:nb_groups_to_find
    s = rand(2,1);
    nb_data_of_this_group = randi(1000,1);
    x = randn(nb_data_of_this_group,1);
    A = randn(2);
    [U,ignore] = eig((A+A')); % (Don't really have to divide by 2)
    sigmas = U*diag(abs(randn(2,1)))*U';
    sigmas = sigmas/100;
    data = [data; mvnrnd(s, sigmas, nb_data_of_this_group), ones(nb_data_of_this_group,1)*ind];
    covariance = cov(data);
end

data(:,1) = data(:,1)-min(data(:,1));
data(:,1) = data(:,1)/max(data(:,1));

data(:,2) = data(:,2)-min(data(:,2));
data(:,2) = data(:,2)/max(data(:,2));

idx_perm = randperm(length(data));
timestamps = randi(n_ev_to_gen,[length(data),1]);
data = data(idx_perm,:);
data = [data, timestamps];
[~, idx_sorted] = sort(data(:,4));
data = data(idx_sorted,:);
colors = hsv(numel(unique(data(:,3))));

figure;
subplot(2,2,1)
hold on;
title('Events');
axis([0 1 0 1])
subplot(2,2,2)
hold on;
title('Processing Standard w Euclidean')
axis([0 1 0 1])
subplot(2,2,3)
hold on;
title('Processing IIWK w Euclidean')
axis([0 1 0 1])
subplot(2,2,4)
hold on;
title('Processing JM w Euclidean')
axis([0 1 0 1])

n_processings = 4;

N_standard = n_init;
N_IIWK = n_init;
N_JM = n_init;
firsts_JM = 1;

centers_standard = zeros(N_standard, 2);
centers_nb_assign = zeros(N_standard, 1);
centers_JM = zeros(N_JM, 2);
centers_nb_assign_JM = zeros(N_JM, 1);
centers_IIWK = 0.5*ones(N_IIWK, 2);
h_standard = [];
h_IIWK = [];
h_JM = [];
h_currpt = cell(n_processings,1);
all_txt = cell(2,1);
all_txt{1} = cell(1,N_standard);
all_txt{2} = cell(1,N_IIWK);
all_txt{3} = cell(1,N_JM);

for ind = 1:numel(data(:,1))
    for ind_subp = 1:n_processings
        subplot(2,2,ind_subp)
        plot(data(ind,1), data(ind,2), '*', 'MarkerEdgeColor', colors(data(ind,3),:));
        delete(h_currpt{ind_subp})
        h_currpt{ind_subp} = plot(data(ind,1), data(ind,2), '*', ...
            'MarkerEdgeColor', colors(data(ind,3),:), ...
            'MarkerSize', 25);
    end
    drawnow;
    
    %% Processing Standard
    if ind <= N_standard
        if firsts_init == 0
            centers_standard(ind,:) = data(ind,1:2)*0 + 0.5;
        else
            
            centers_standard(ind,:) = data(ind,1:2);
            
            
        end;
        centers_nb_assign(ind) = centers_nb_assign(ind)+1;
    else
        dists_standard = pdist2(data(ind,1:2),centers_standard);
        % standard
        [~, idx_min] = min(dists_standard);
        alpha = 0.01/(1+centers_nb_assign(idx_min)/n_events_standard_clustering);
        
        beta = sum(centers_standard(idx_min,:).*data(ind,1:2))/ ...
            sqrt(sum(centers_standard(idx_min,:))^2*sum(data(ind,1:2))^2);
        
        %     centers_standard(idx_min,:) = centers_standard(idx_min,:) + ...
        %       alpha.*(data(ind,1:2)-beta.*(centers_standard(idx_min,:)))
        centers_standard(idx_min,:) = centers_standard(idx_min,:) + ...
            alpha.*(data(ind,1:2)-beta.*centers_standard(idx_min,:));
        centers_nb_assign(idx_min) = centers_nb_assign(idx_min)+1;
    end
    
    %% Processing JM
    if firsts_JM <= N_JM
        
        if firsts_init == 0
            centers_JM(ind,:) = data(ind,1:2)*0 + 0.5;  
            firsts_JM = firsts_JM + 1
        else
            if trick_init_firsts
%                 max_beta = 0;
%                 for ii = 1:firsts_JM
%                     beta = sum(centers_JM(ii,:).*data(ind,1:2))/ ...
%             sqrt(sum(centers_JM(ii,:))^2*sum(data(ind,1:2))^2);
%                     if beta > max_beta
%                         max_beta = beta;
%                     end
%                 end
                max_beta = min(pdist2(data(ind,1:2),centers_JM));
                if max_beta < 0.1
                    disp(['Too close - proc JM ' max_beta])
                else
                    disp(['Init ok - proc JM ' max_beta])
                    centers_JM(firsts_JM,:) = data(ind,1:2);
                    firsts_JM = firsts_JM + 1;
                end
                        
            else
                centers_JM(ind,:) = data(ind,1:2);
                firsts_JM = firsts_JM + 1
            end
            
            
        end;
        
%         centers_nb_assign_JM(ind) = centers_nb_assign_JM(ind)+1;
    else
        dists_standard = pdist2(data(ind,1:2),centers_JM);
        % standard
        [~, idx_min] = min(dists_standard);
        alpha = BASELR_JM/(1+centers_nb_assign_JM(idx_min)/n_events_JM_clustering);
        
        beta = sum(centers_standard(idx_min,:).*data(ind,1:2))/ ...
            sqrt(sum(centers_standard(idx_min,:))^2*sum(data(ind,1:2))^2);
        %     disp(['beta ' num2str(beta)])
        
        
        centers_JM(idx_min,:) = centers_JM(idx_min,:) + ...
            beta * alpha * (data(ind,1:2) - centers_JM(idx_min,:));
        
        centers_nb_assign_JM(idx_min) = centers_nb_assign_JM(idx_min)+1;
    end
    
    
    %% IIWK
    if ind <= N_IIWK
        if firsts_init == 0
            centers_IIWK(ind,:) = data(ind,1:2)*0 + 0.5;
        else
            centers_IIWK(ind,:) = data(ind,1:2);
        end;
    else
        dists_battacharrya = zeros(N_IIWK,1);
        for indb = 1:N_IIWK
            dists_battacharrya(indb) = -log(sum(sqrt(data(ind,1:2).*centers_IIWK(indb,:)/ ...
                (sum(data(ind,1:2))*sum(centers_IIWK(indb,:))))));
            if dists_battacharrya(indb) < 0
                throw
            end
        end
        
        dists_battacharrya = pdist2(data(ind,1:2), centers_IIWK);
        [~, idx_min] = min(dists_battacharrya);
        coeff = ksi_IIWK.*((nPow_IIWK+1).*(dists_battacharrya(idx_min).^(nPow_IIWK-1))+...
            nPow_IIWK.*(dists_battacharrya(idx_min).^(nPow_IIWK-2)).*...
            (sum(dists_battacharrya)-dists_battacharrya(idx_min)));
        
        % A check avec Kévin: jamais de la vie
        % % % % %     if coeff > 1
        % % % % %       coeff = 1;
        % % % % %     elseif coeff < 0
        % % % % %       coeff = 0;
        % % % % %     end
        centers_IIWK(idx_min, :) = (1-coeff).*centers_IIWK(idx_min,:)+coeff.*data(ind,1:2);
        centers_IIWK(idx_min,centers_IIWK(idx_min,:) < 0) = 0;
        centers_IIWK(idx_min,centers_IIWK(idx_min,:) > 1) = 1;
    end;
    % affs centers
    subplot(222)
    delete(h_standard)
    h_standard = plot(centers_standard(:,1), centers_standard(:,2), 's', ...
        'MarkerSize',10,  'MarkerEdgeColor',[0 0 0], 'MarkerFaceColor',[0.5,0.5,0.5]);
    for ind_txt1 = 1:N_standard
        delete(all_txt{1}{ind_txt1})
        all_txt{1}{ind_txt1} = text(centers_standard(ind_txt1,1)+0.01, ...
            centers_standard(ind_txt1,2)+0.01,num2str(ind_txt1));
    end
    subplot(223)
    delete(h_IIWK)
    h_IIWK = plot(centers_IIWK(:,1), centers_IIWK(:,2), 'd', ...
        'MarkerSize',10,  'MarkerEdgeColor',[0 0 0], 'MarkerFaceColor',[0.5,0.5,0.5]);
    for ind_txt2 = 1:N_IIWK
        delete(all_txt{2}{ind_txt2})
        all_txt{2}{ind_txt2} = text(centers_IIWK(ind_txt2,1)+0.01, ...
            centers_IIWK(ind_txt2,2)+0.01,num2str(ind_txt2));
    end
    
    subplot(224)
    delete(h_JM)
    h_JM = plot(centers_JM(:,1), centers_JM(:,2), '^', ...
        'MarkerSize',10,  'MarkerEdgeColor',[0 0 0], 'MarkerFaceColor',[0.5,0.5,0.5]);
    for ind_txt3 = 1:N_JM
        delete(all_txt{3}{ind_txt3})
        all_txt{3}{ind_txt3} = text(centers_JM(ind_txt3,1)+0.01, ...
            centers_JM(ind_txt3,2)+0.01,num2str(ind_txt3));
    end
end

disp('Done.')

