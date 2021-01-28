%{
Below is the code of the RkSE feature selection Algorithm. For
more details about the algorithm, how it works, and citation purposes
please refer to our published article:
https://www.preprints.org/manuscript/202008.0254/v1

Please note that the feature selected/ the dataset after feature selection
is stored in dataset_use  and the execution time is calculated in
execution_time
%}
%--------------------------------------------------------------------------------------
%test by jjjjjjjjjjjjjjjjjjjjjj
clear all
clc

%apply the initial k-means clustering to find idx, k and the dataset X used
%to calculate the rest
%read the 100% healthy dataset to learn from. The data description is
%mentioned in the read me file.
data = xlsread('zoo','data','B2:Q102');

%apply best_kmeans
%tic
initial_time= tic;

X= data';
disp('start the initial clustering to find k, idx and save X');
[idx,C,sumd,D,K]=best_kmeans(X);

%Now, let's get started
%(1)
%do the clustering and find K.
%I already found and saved them, so just load them.
disp('read the needed files or initial clustering'); 
[m,w]=size(X);
 
%(2)
%Now we need to find the Silhouette value. I also already found this from X
%and the calculated idx. I also have done that before using Si= silhouette(X,idx);
%so just read the file Si_initial.mat

disp('Calculate Si or just read Si');    
Si= silhouette(X,idx);
Si_struct= struct('Si', Si);
Si_matrix_all_stages(1)= Si_struct;

%(3) now we need to make the initial check of the Si values. This step is
%really important not to be done in a loop. because we need to store the
%values of the indices of which where some specific points either high or
%low Si are located in X, so we can retrieve them later from X, without losing their
%original indicies after many re-clustering.

%set the threshold value, please note that when it is set to 1.0 all the
%features in X will be selected with no tolerance in the threshold.
threshold= 1; %1.00; %.95; %.9; %.7; %.95; %.8;    
[size_si, x_size]= size(Si);

disp('1st Si analyzing and initialization');
disp('Start to analyze the values in Si and create the needed matricies and structures');
Si_high_struct= struct('Si_value',[], 'cluster', [], 'X_index', []);
Si_high= Si_high_struct; 

for i=1:size_si
    if Si(i)>= threshold
        %then we need to store all the information about this point in a
        %struct I will call it Si_high matrix to store a structure in it
        %is a matrix of structs Si_high. each row has a struct instead of a
        %value, to avoid the problem of dynamic matrix size not supported
        %in matlab
        %each row of the Si_high_matrix is a struct. to solve the
        %pre-dimension definition problem in matlab, or dynamic size
        %problem.
        Si_high_struct= struct('Si_value',Si(i), 'cluster', idx(i), 'X_index', i);
        Si_high(i)= Si_high_struct;
    else
        %here is all the time points that doesn't follow any cluster or
        %pattern, and they are unique, so we need to cluster them together
        %to find patterns later.
        %now all the values that has lower Si will re-clustered 
        %remaining_index_struct to make sure the size is dynamic with no errors
        remaining_index_struct= struct('index',i);
        remaining_index(i)=remaining_index_struct.index;
        re_cluster_index(i)=remaining_index_struct.index;
           
        %now X_remain struct will contain the features from X with the
        %undesirable Si values so we cluster them again. And same reason
        %it's a struct so the size will be dynamic to avoid error in
        %matlab.
        remaining_X_struct= struct('X_remain',X(remaining_index(i),:), 'X_index',i);
        X_remain_struct(i)= remaining_X_struct;
        X_remain(i,:)= remaining_X_struct.X_remain;
    end
end

%I want to remove the empty cells from remaining_index structure
%and re_cluster_index structure
remaining_index = remaining_index(remaining_index~= 0);
re_cluster_index = re_cluster_index(re_cluster_index~= 0);
X_remain( all(~X_remain,2), : )=[];

%(3)
%now, we need to fill the features selected into the features_selected
%matrix of structures. these structures will be filled with the X values of
%the highest Si values from each cluster separately.. to make sure that we
%took only one feature representing each cluster, and this feature is the
%one with the highest Si value and this highest value should be higher than
%the threshold to be accepted.

%find size_Si_high(i)or number of rows in Si_high(i)
[ss,Si_high_size]= size(Si_high);

%initialize selected_features
Selected_features_struct= struct('selected_features',[]);
selected_features(1)= Selected_features_struct;

disp('Store the Selected features in the Selected_features Matrix');
for j=1:K
     clusterj= struct('Si_value',[], 'cluster', [], 'X_index', []);
     clusterj_Si= [];
     
    for i=1:Si_high_size 
        %this for loop is for sorting out all the values in Si_high into
        %clusters. So we put all the points that belongs to one cluster in
        %one struct 
        if Si_high(i).cluster==j
            %then we need to store the Si_high value in cluster matrix.
            %when j=1 we will store all the Si_high rows that is clustered
            %in cluster 1 in a matrix called clust, and then when we go out
            %of this small for loop we will find the max Si values of
            %cluster 1 and retrieve it's index then store it in
            %selected_features_struct, then Selected_features(j)=selected_features_struct
            clusterj(i)=Si_high(i);
            clusterj_Si(i)= Si_high(i).Si_value;
        end
    end
   if ~isempty(clusterj_Si)
   %find the max in the clusterj and also read it's index
  [max_value, max_index]= max(clusterj_Si);
  %now create a struct called features_selected_struct and add max_index to
  %it
  Selected_features_struct= struct('selected_features', X(max_index,:));
  selected_features(j)= Selected_features_struct;
   end
  
end

%find the size of selected_features and we start to fill the new items in
%size+1
if ~isempty(selected_features)
[nn,left_of_index]= size(selected_features);
else
left_of_index=0;
end

%(4)
%Now, after the 1st clustering and checking process, we need to recluster
%and recalculate Si and process the value until the remaining 
%we will continue clustering till counter>5 or X_remain is empty. make sure to clear up Si_high
%eveytime we do the loop
counter=2;
%we will keep repeating the previous process untill all X_remain values
%will get empty, which means we clusterered all the points until every point Si value
%is above or equal the threshold value

%create a counter called fixed_X_remain_counter, that counts the number of
%times the clustering process didn't reduce the size of X_remain. In other
%words, there were no features with Si >= the Si_threshold in this
%iteration, and if this happened for 5 times in a row, we need to break
%from the loop to prevent infinite loops.
fixed_X_remain_counter=0;
%define X_remain_old_size with has the size of X_remain in the previous
%iteration
X_remain_new_size= 0;

while ~isempty(X_remain)
%calculate size X_remain. if the number of rows lower than K, then it will
%give is an error when we cluster so better to check first.
%this size_X_remain is the size of X_remain before the clustering in this
%iteration
[size_X_remain,cc]= size(X_remain);

%we countinue the iterations when the remaining features number are more
%than the number of clusters so that we can still perform the clustering,
%and the size_x_remain should keep getting smaller each iteration to
%indicate that the features are being seleted each iteration. now, if these
%two criteria or one of them broke, we need to break the loop to avoid
%infinite loops.
if (size_X_remain> K)&&(fixed_X_remain_counter< 5)
 %disp('X_remain is smaller than or equal K ');
 %disp('then add all the X_remain to the features_selected');
 %else
    disp('We are now in while loop');
    disp('loop number');
    disp(counter);
    
    %clear Si_high struct
    clear Si_high
    clear size_si
    clear Si_high_size
    
    %cluster the X_remain and K=K, and store idx
    [idx,C, sumd,D] = kmeans(X_remain,K,'Distance','sqeuclidean','start','plus');
    
    %calculate Si for the calculated X and idx
    Si= silhouette(X_remain,idx);
    Si_struct= struct('Si', Si);
    Si_matrix_all_stages(counter)= Si_struct;
    
    %now process Si values
    %/////////////////////////////////////////////////////////////////////
    [size_si, x_size]= size(Si);

        disp('1st Si analyzing and initialization');
        disp('Start to analyze the values in Si and create the needed matricies and structures');
        Si_high_struct= struct('Si_value',[], 'cluster', [], 'X_index', []);
        %Si_high_struct= struct('Si_value',Si(i), 'cluster', idx(i), 'X_index', X_remain_struct(i).X_index );
        Si_high= Si_high_struct;  
        
        for i=1:size_si
            if Si(i)>= threshold
                %then we need to store all the information about this point in a
                %struct I will call it Si_high matrix to store a structure in it
                %is a matrix of structs Si_high. each row has a struct instead of a
                %value, to avoid the problem of dynamic matrix size not supported
                %in matlab
                %each row of the Si_high_matrix is a struct. to solve the
                %pre-dimension definition problem in matlab, or dynamic size
                %problem.
                %store the original_X_index stored in the
                %remaining_index(i) in the Si_high struct before you remove
                %the index from the remaining_index vector
                Si_high_struct= struct('Si_value',Si(i), 'cluster', idx(i), 'X_index', remaining_index(i));
                Si_high(i)= Si_high_struct;
                
                %remove this point from remaining_index_struct,
                %remaining_index,re_cluster_index and from X_remain
                %remove the high points from the X_remain
                remaining_index(i)=0;
                re_cluster_index(i)=0;
                %also remove the chosen cells from X_remain
                X_remain(i,:)= 0;
               
            end
        end
        
         %I want to remove the empty cells from remaining_index structure
        %and re_cluster_index structure
        %remove zeros from the remaining_index
        remaining_index = remaining_index(remaining_index~= 0);
        re_cluster_index = re_cluster_index(re_cluster_index~= 0);
        %X_remain = X_remain(X_remain~= 0);
        X_remain( all(~X_remain,2), : )=[];

        %(3)
        %now, we need to fill the features selected into the features_selected
        %matrix of structures. these structures will be filled with the X values of
        %the highest Si values from each cluster separately.. to make sure that we
        %took only one feature representing each cluster, and this feature is the
        %one with the highest Si value and this highest value should be higher than
        %the threshold to be accepted.
        
        %find size_Si_high(i)or number of rows in Si_high(i)
        [ss,Si_high_size]= size(Si_high);

        disp('Store the Selected features in the Selected_features Matrix');
        for j=1:K
            clusterj= struct('Si_value',[], 'cluster', [], 'X_index', []);
            clusterj_Si= [];
            
            for i=1:Si_high_size        
                %this for loop is for sorting out all the values in Si_high into
                %clusters. So we put all the points that belongs to one cluster in
                %one struct 
                if Si_high(i).cluster==j
                    %then we need to store the Si_high value in cluster matrix.
                    %when j=1 we will store all the Si_high rows that is clustered
                    %in cluster 1 in a matrix called clust, and then when we go out
                    %of this small for loop we will find the max Si values of
                    %cluster 1 and retrieve it's index then store it in
                    %selected_features_struct, then Selected_features(j)=selected_features_struct
                    clusterj(i)=Si_high(i);
                    clusterj_Si(i)= Si_high(i).Si_value;
                end
            end
          if ~isempty(clusterj_Si)
           %find the max in the clusterj and also read it's index
          [max_value, max_index]= max(clusterj_Si);
          %now create a struct called features_selected_struct and add max_index to
          %it
          %find the index in the original X, for the max_index found
          original_X_index= Si_high(max_index).X_index;
          Selected_features_struct= struct('selected_features', X(original_X_index,:));
          selected_features(left_of_index+j)= Selected_features_struct;
          end

        end
       
        %find the size of selected_features and we start to fill the new items in
        %size+1
        [nn,left_of_index]= size(selected_features);
    %/////////////////////////////////////////////////////////////////////
    
    %just to know how many loops we have done
    counter= counter+1;

%when size_Y_remain is smaller than K, we need to break the loop,
%to avoid stucking in the loop. And before breaking out of the loop we need
%to push the remaining X_remain to the selected_features
%when X_remain_size is less than K, or X_remain_fixed_counter is bigger
%than 5 or both are happening, then we move to the else section to break
%the loop, to prevent infinite loops.
else 
    %add all the remaining features that are in count less than K
    %add all X_remain to the selected_features
    %remaining_index(max_index);
    %we also go here when fixed_counter_remain is fixed for 5 iterations or
    %more, to avoid the infinite loop problem
    disp('Ahlam_X_remain is smaller than K, now add them to features');
    for i=1:size_X_remain
    Selected_features_struct= struct('selected_features', X_remain(i,:));
    selected_features(left_of_index+i)= Selected_features_struct;
    end
   %this will help us break from the whole while loop. 
   break; 
%end the big if, when we check the X_remain size before clustering    
end

%now check the size of X_remain_new to avoid any infinite loops
%added new
%---------------------------------------------------------------------
%added to prevent infinite loops when X_remain is bigger than K, but it
%doesn't give good clusters with higher than threshold accuracy anymore

%the X_remain_new_size is the size of X_remain after this iteration clustering
%which will be an indicator that the clustering results became fixed and no
%longer fulfil the Si criteria
[X_remain_new_size,cc]= size(X_remain);

if X_remain_new_size== size_X_remain
fixed_X_remain_counter= fixed_X_remain_counter+1;
%end X_remain_old_size== size_X_remain if statement 
else
    %the number of times should be in a row to be counted, so keep the
    %counter reset if the criteria doesn't fit
    fixed_X_remain_counter= 0;
end
%-------------------------------------------------------------------
%end while not empty
end

%convert the struct into matrix to hold all the selected_features
[x,y]=size(selected_features);

for i=1:y
  if ~isempty(selected_features(i).selected_features)
  selected_features_mat(i,:)= selected_features(i).selected_features; 
  end
end

%remove the zero rows from the matrix 
selected_features_mat( ~any(selected_features_mat,2), : ) = [];  %rows

%now, if X_remain still has number of t-points in it but it's less than K,
%all these points will be added to the features_selected

End_time= toc(initial_time);
execution_time= End_time;

dataset_use= selected_features_mat';
