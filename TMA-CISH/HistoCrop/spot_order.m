%This function is used to order the TMA spots from bottom-right to the
%upper-left.
%
%INPUT:
%       -Ibw_rotated: rotated mask
%       -angle: rotation angle
%       -n_rows: Maximum number of rows in TMA
%       -n_cols: Maximum number of cols in TMA
%
%OUTPUT:
%       -sorted: correct order of the TMA spots
%
% Ariotta Valeria  & Pohjonen Joona
% June 2019

function sorted = spot_order(Ibw_rotated, angle, n_rows, n_cols)

%Calculate connected components and calculate centroids of the elements
se = strel('disk',1,0);
Ibw_rotated = imdilate(Ibw_rotated,se);
CC = bwconncomp(Ibw_rotated);
S=regionprops(CC,'Centroid');
sorted =cat(1,S.Centroid);

%Find out how many columns there are
number_of_cols = 1:min(n_cols,ceil(length(sorted/7)+1));
eva_cols = evalclusters(sorted(:,1),'kmeans','silhouette','KList',number_of_cols);
sorted = [sorted,kmeans(sorted(:,1),eva_cols.OptimalK) + 100];

%Find out how many rows there are in the mask using kmeans silhouette
number_of_rows = 1:min(n_rows,ceil(length(sorted/7)+1));
eva_rows = evalclusters(sorted(:,2),'kmeans','silhouette','KList',number_of_rows);
sorted = [sorted,kmeans(sorted(:,2),eva_rows.OptimalK) + 200];

%Change kmeans cluster numbers
sorted = sortrows(sorted,1, 'descend');
clusts = unique(sorted(:,3),'stable');
for i=1:length(clusts)
    sorted(sorted == clusts(i)) = i;
end

sorted = sortrows(sorted,2, 'descend');
clusts = unique(sorted(:,4),'stable');
for i=1:length(clusts)
    sorted(sorted == clusts(i)) = i;
end

%Give each spot an index starting from top-left towards bottom-right
sorted = sortrows(sorted,[4 3],'ascend');
for i=1:length(sorted)
    sorted(i,5) = sorted(i,4)*n_cols - n_cols + sorted(i,3);
end

%Now we rotate the centroid coordinates around the center of the mask
x = sorted(:,1)';
y = sorted(:,2)';

%choose a point which will be the center of rotation
dim_of_Ibw = size(Ibw_rotated);
x_center = dim_of_Ibw(2)/2;
y_center = dim_of_Ibw(1)/2;

%move points to new origo
x_tmp = x - x_center;
y_tmp = y - y_center;

%create rotation matrix and rotate the centroids
theta = -angle;
R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
point = R*[x_tmp;y_tmp];

sorted(:,1) = x_center + point(1,:)';
sorted(:,2) = y_center + point(2,:)';

sorted = sorted(:,[5 1:2]);
end

