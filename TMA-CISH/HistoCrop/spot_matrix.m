%This function is used to find the spot matrix coordinates from mrxs
%thumbnail image
%
%INPUT:
%       -thumbnail: Thumbnail file path
%       -img_path: path for the output of mrxs_convert.py
%
%OUTPUT:
%       -mat_coord: Spot matrix coordinates [xmin xmax ymin ymax]
%
% Ariotta Valeria  & Pohjonen Joona
% June 2019

function [mat_coord] = spot_matrix(thumbnail, img_path)

%Grayscale conversion
Igray=rgb2gray(thumbnail);

%Operantion to create a mask in which the spots are well visible
Igray = imadjust(Igray);
Ibw=~imbinarize(Igray);

%Remove small specs
Ibw = bwareaopen(Ibw,100);

%Detect the matrix
se = strel('disk',35,0);
Ibw_mat = imdilate(Ibw,se);
Ibw_mat = bwareafilt(Ibw_mat,1);

%Caclulate bounding box
bb = regionprops(Ibw_mat,'BoundingBox');

% %Find out what scaling was used for thumbnail. First we must find image
% %dimensions from x and y coordinates
% tmp = dir(img_path);
% all_coord = cell(1,length(tmp)-2);
% for j=3:length(tmp)
%     all_coord{j-2} = cat(1,strcat(tmp(j).name));
% end
% 
% %Find the last image
% coord = char(all_coord(end));
% 
% %Get dimensions from the name
% ind=find(coord=='_');
% x_coord = str2double(regexp(coord(ind(end)+1:end),...
%     '[0-9]\w+','match'));
% y_coord = str2double(regexp(coord(ind(end-1)+1:ind(end)-1),...
%     '[0-9]\w+','match'));
% 
% %Find out the individual image dimensions and add that to x and y
% coord = char(all_coord(end-1));
% ind=find(coord=='_');
% x_coord_2 = str2double(regexp(coord(ind(end)+1:end),...
%     '[0-9]\w+','match'));
% small_image_dim = x_coord - x_coord_2;
% y_coord = y_coord + small_image_dim;
% 
% %Get the scale
% thumb_dim = size(thumbnail);
% y_thumb = thumb_dim(1);
% thumbnail_scale = y_coord/y_thumb;

%Bounding box to min and max values for x and y
xMin = ceil(bb.BoundingBox(1));
xMax = xMin + bb.BoundingBox(3) - 1;
yMin = ceil(bb.BoundingBox(2));
yMax = yMin + bb.BoundingBox(4) - 1;

% xMin = xMin*thumbnail_scale;
% xMax = xMax*thumbnail_scale;
% yMin = yMin*thumbnail_scale;
% yMax = yMax*thumbnail_scale;

%Ceil or floor to closest multiple of small_image_dim
% xMin = floor(xMin / small_image_dim) * small_image_dim;
% xMax = ceil(xMax / small_image_dim) * small_image_dim;
% yMin = floor(yMin / small_image_dim) * small_image_dim;
% yMax = ceil(yMax / small_image_dim) * small_image_dim;

%Save coordinates
mat_coord = [xMin xMax yMin yMax];
end


