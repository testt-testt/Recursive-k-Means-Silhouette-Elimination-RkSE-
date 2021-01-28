function [IDX,C,SUMD,D,K]=best_kmeans(X)

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

