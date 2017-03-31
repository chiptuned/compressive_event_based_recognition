%function [temporal] = centers_temporal(centers)
test_hots;
close 2;
clearvars -except all_centers params;
nb_channels = 2048;
nb_pols = params.nbPols;
centers = all_centers{1};
tau = params.tau;
radius = params.radius;
nb_feats = numel(centers(1,1,:));

nb_elem = numel(centers(1,:));
elems = zeros(nb_elem,3); % level, ts, pol
cpt = 0;
for ind = 1:nb_pols
    for ind2 = 1:nb_feats
        cpt = cpt + 1;
        elems(cpt,:) = [ind2-radius-1, centers(2,ind,ind2), ind-1];
    end
end
elems(:,2) = -tau*log(elems(:,2));
[~, comb] = sort(elems(:,2), 'descend');
elems = elems(comb,:);

figure;
plot(-elems(elems(:,3)==0,2), elems(elems(:,3)==0,1), '*-b');
hold on;
plot(-elems(elems(:,3)==1,2), elems(elems(:,3)==1,1), '*-r');
xlabel('Time in microseconds')
ylabel('Level')
% [p,~,mu] = polyfit(-elems(:,2),elems(:,1),3);
% t_vect = linspace(-elems(2,2),-elems(end-1,2),100);
% f = polyval(p,t_vect,[],mu);
% plot(t_vect,f);
% hold off;
% 
% pad = length(f);
% fe = 1e6/(t_vect(2)-t_vect(1));
% freqvect=linspace(-fe/2,fe/2,pad);
% p1mw=abs(fftshift(fft(f,pad)))/length(f);
% figure;
% plot(freqvect,p1mw);
% axis([0,1000,0,max(p1mw)])
% figure;
% plot(-tau*log(test_1(:))); hold on;
% plot(-tau*log(test_2(:)));
% 
% figure;
% [test_sorted, comb] = sort(test, 'descend');
% axe_radius = -radius:radius;
% plot(-test_sorted, axe_radius(comb))