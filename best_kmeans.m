function [IDX,C,SUMD,D,K]=best_kmeans(X)
% [IDX,C,SUMD,K] = best_kmeans(X) partitions the points in the N-by-P data matrix X
% into K clusters. Rows of X correspond to points, columns correspond to variables. 
% IDX containing the cluster indices of each point.
% C is the K cluster centroids locations in the K-by-P matrix C.
% SUMD are sums of point-to-centroid distances in the 1-by-K vector.
% K is the number of cluster centriods determined using ELBOW method.
% ELBOW method: computing the destortions under different cluster number counting from
% 1 to n, and K is the cluster number corresponding 90% percentage of
% variance expained, which is the ratio of the between-group variance to
% the total variance. see <http://en.wikipedia.org/wiki/Determining_the_number_of_clusters_in_a_data_set>
% After find the best K clusters, IDX,C,SUMD are determined using kmeans
% function in matlab.

dim=size(X);
disp('dim');
disp(dim);

%maximum number of k allowed is number of features minus one.
max_K_to_try= dim(1)-1
disp("max_K_to_try");
disp(max_K_to_try);

%----------------------------------------------
% default number of test to get minimun under differnent random centriods
test_num=10;
distortion=zeros(dim(1),1);
for k_temp=1:dim(1)
    [~,~,sumd,D]=kmeans(X,k_temp,'emptyaction','drop');
    destortion_temp=sum(sumd);
    % try differnet tests to find minimun disortion under k_temp clusters
    for test_count=2:test_num
        [~,~,sumd,D]=kmeans(X,k_temp,'emptyaction','drop');
        destortion_temp=min(destortion_temp,sum(sumd));
    end
    distortion(k_temp,1)=destortion_temp;
end
variance=distortion(1:end-1)-distortion(2:end);
distortion_percent=cumsum(variance)/(distortion(1)-distortion(end));
plot(distortion_percent,'b*--');
[r,~]=find(distortion_percent>0.9);
K=r(1,1)+1;
[IDX,C,SUMD,D]=kmeans(X,K);

end

