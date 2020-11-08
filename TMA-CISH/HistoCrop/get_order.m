%This function finds the correct order of the spots
%
%INPUT:
%       -all_spots: TMA spots
%       -all_summaries: summary images
%       -all_angles: rotation anlges
%       -n_rows: max row number
%       -n_cols: max col number
%
%OUTPUT:
%       -all_spots: TMA spots in correct order
%
% Ariotta Valeria  & Pohjonen Joona
% June 2019

function all_spots = get_order(all_spots, all_summaries, all_angles,...
    n_rows, n_cols)

for tma_i=1:length(all_spots)
    
    %Rotate boundingBox upper corner
    x = all_spots{tma_i}(:,1)';
    y = all_spots{tma_i}(:,2)';
    
    %choose a point which will be the center of rotation
    dim_img = size(all_summaries{tma_i});
    x_center = dim_img(2)/2;
    y_center = dim_img(1)/2;
    
    %move points to new origo
    x_tmp = x - x_center;
    y_tmp = y - y_center;
    
    %create rotation matrix and rotate the centroids
    theta = all_angles{tma_i};
    R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
    point = R*[x_tmp;y_tmp];
    all_spots{tma_i}(:,1) = x_center + point(1,:)';
    all_spots{tma_i}(:,2) = y_center + point(2,:)';
    
    %turn boundingBox upper left corner to boundingBox centroid
    all_spots{tma_i}(:,1) = all_spots{tma_i}(:,1) + all_spots{tma_i}(:,3)/2;
    all_spots{tma_i}(:,2) = all_spots{tma_i}(:,2) - all_spots{tma_i}(:,4)/2;
    
    %Kmeans silhouette to find right number of cols and rows
    eva = evalclusters(all_spots{tma_i}(:,1),'kmeans','silhouette','KList',1:n_cols);
    number_of_cols = eva.OptimalK;
    
    number_of_rows = 1:min(n_rows,ceil(length(all_spots{tma_i})/(n_cols-1)));
    eva = evalclusters(all_spots{tma_i}(:,2),'kmeans','silhouette','KList',number_of_rows);
    number_of_rows = eva.OptimalK;
    
    %Hierarchial clustering works better for us
    all_spots{tma_i} = [all_spots{tma_i},clusterdata(all_spots{tma_i}(:,1),number_of_cols) + 1e6];
    all_spots{tma_i} = [all_spots{tma_i},clusterdata(all_spots{tma_i}(:,2),number_of_rows) + 2e6];
        
    %Change cluster numbers
    all_spots{tma_i} = sortrows(all_spots{tma_i},1, 'descend');
    clusts = unique(all_spots{tma_i}(:,5),'stable');
    for i=1:length(clusts)
        all_spots{tma_i}(all_spots{tma_i} == clusts(i)) = i;
    end
    
    all_spots{tma_i} = sortrows(all_spots{tma_i},2, 'descend');
    clusts = unique(all_spots{tma_i}(:,6),'stable');
    for i=1:length(clusts)
        all_spots{tma_i}(all_spots{tma_i} == clusts(i)) = i;
    end
    
    %Give each spot an index starting from top-left towards bottom-right
    all_spots{tma_i} = sortrows(all_spots{tma_i},[6 5],'ascend');
    for i=1:length(all_spots{tma_i})
        all_spots{tma_i}(i,7) = all_spots{tma_i}(i,6)*n_cols - n_cols + all_spots{tma_i}(i,5);
    end
    
    all_spots{tma_i} = all_spots{tma_i}(:,[7 1:4]);
    
    %turn boundingBox centroid back to upper left corner
    all_spots{tma_i}(:,2) = all_spots{tma_i}(:,2) - all_spots{tma_i}(:,4)/2;
    all_spots{tma_i}(:,3) = all_spots{tma_i}(:,3) + all_spots{tma_i}(:,5)/2;
    
    %Rotate back
    x = all_spots{tma_i}(:,2)';
    y = all_spots{tma_i}(:,3)';
    x_tmp = x - x_center;
    y_tmp = y - y_center;
    theta = -all_angles{tma_i};
    R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
    point = R*[x_tmp;y_tmp];
    all_spots{tma_i}(:,2) = x_center + point(1,:)';
    all_spots{tma_i}(:,3) = y_center + point(2,:)';
    
end

end