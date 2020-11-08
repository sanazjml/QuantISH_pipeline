%This function is used to cut and save each TMA spot from the reconstructed
%image.
%
%INPUT:
%       -Img: Reconstructed TMA image
%       -name: name for the summary image
%       -n_rows: Maximum number of rows in TMA
%       -n_cols: Maximum number of cols in TMA
%
% Ariotta Valeria  & Pohjonen Joona
% June 2019

function [spots, summaryImg, angle] = spot_coord(thumbnail, n_rows, n_cols)

%Grayscale conversion and resize to reduce computational time
Igray=rgb2gray(thumbnail);

%Operantion to create a mask
Igray = imadjust(Igray);
Ibw = ~imbinarize(Igray,0.9);
se = strel('disk',3,0);
% Ibw = imdilate(Ibw,se);
Ibw = imclose(Ibw,se);

%If the TMA is rotated get the rotation angle
angle = horizon(Ibw, 0.1, 'hough');

%Dilate spots
Ibw = bwareaopen(Ibw,500);
se = strel('disk',3,0);
% Ibw = imdilate(Ibw,se);
Ibw = imclose(Ibw,se);

%Filter elements of the mask based on area
SpotArea = regionprops(Ibw,'Area');
SpotArea = sort([SpotArea.Area]);
maxArea = SpotArea(end-4)*2; % ~200%
minArea = maxArea/6; % ~33%
Ibw = bwareafilt(Ibw,[minArea maxArea]);

%Calculate Centroids and BoundingBoxes of the elements
CC = bwconncomp(Ibw);
S=regionprops(CC,'BoundingBox');
spots = cat(1,S.BoundingBox);

%Rotate BoundingBox upper corner
x = spots(:,1)';
y = spots(:,2)';

%choose a point which will be the center of rotation
dim_img = size(Ibw);
x_center = dim_img(2)/2;
y_center = dim_img(1)/2;

%move points to new origo
x_tmp = x - x_center;
y_tmp = y - y_center;

%create rotation matrix and rotate the centroids
theta = angle;
R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
point = R*[x_tmp;y_tmp];
spots(:,1) = x_center + point(1,:)';
spots(:,2) = y_center + point(2,:)';

%turn boundingBox upper left corner to boundingBox centroid
spots(:,1) = spots(:,1) + spots(:,3)/2;
spots(:,2) = spots(:,2) - spots(:,4)/2;

%Kmeans silhouette to find right number of cols and rows
eva = evalclusters(spots(:,1),'kmeans','silhouette','KList',1:n_cols);
number_of_cols = eva.OptimalK;

number_of_rows = 1:min(n_rows,ceil(length(spots)/(n_cols-1)));
eva = evalclusters(spots(:,2),'kmeans','silhouette','KList',number_of_rows);
number_of_rows = eva.OptimalK;

%Hierarchial clustering works better for us
spots = [spots,clusterdata(spots(:,1),number_of_cols) + 1e6];
spots = [spots,clusterdata(spots(:,2),number_of_rows) + 2e6];

%Change cluster numbers
spots = sortrows(spots,1, 'descend');
clusts = unique(spots(:,5),'stable');
for i=1:length(clusts)
    spots(spots == clusts(i)) = i;
end

spots = sortrows(spots,2, 'descend');
clusts = unique(spots(:,6),'stable');
for i=1:length(clusts)
    spots(spots == clusts(i)) = i;
end

%Give each spot an index starting from top-left towards bottom-right
spots = sortrows(spots,[6 5],'ascend');
for i=1:length(spots)
    spots(i,7) = spots(i,6)*n_cols - n_cols + spots(i,5);
end

spots = spots(:,[7 1:4]);

%turn boundingBox centroid back to upper left corner
spots(:,2) = spots(:,2) - spots(:,4)/2;
spots(:,3) = spots(:,3) + spots(:,5)/2;

%Rotate back
x = spots(:,2)';
y = spots(:,3)';
x_tmp = x - x_center;
y_tmp = y - y_center;
theta = -angle;
R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
point = R*[x_tmp;y_tmp];
spots(:,2) = x_center + point(1,:)';
spots(:,3) = y_center + point(2,:)';

%If two spots still have same number add an index
spot_nums = spots(:,1);
ind = 1;
new_spot_nums = string([spot_nums(1);zeros(length(spot_nums)-1,1)]);
for i=2:length(spot_nums)
    if spot_nums(i) == spot_nums(i-1)
        if ind == 1
            new_spot_nums(i-1) = strcat(string(spot_nums(i-1)),'_',string(ind));
            ind = ind +1;
            new_spot_nums(i) = strcat(string(spot_nums(i)),'_',string(ind));
        else
            ind = ind +1;
            new_spot_nums(i) = strcat(string(spot_nums(i)),'_',string(ind));
        end
    else
        new_spot_nums(i) = string(spot_nums(i));
        ind = 1;
    end
end

summaryImg = imadjust(thumbnail, [0.01 0.65 0; 0.30 0.99 1]);

%Create image of the cutting areas and the order
summaryImg = insertShape(summaryImg,'Rectangle',spots(:,2:5),...
    'Color','red','LineWidth', 2);
for i=1:length(spots)
    summaryImg = insertText(summaryImg,[spots(i,2)+1,spots(i,3)+1],...
        new_spot_nums(i),'BoxOpacity',0,'TextColor','black','FontSize',18);
end
end


