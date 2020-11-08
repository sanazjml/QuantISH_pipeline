%This function is used to find the spot matrix coordinates from mrxs
%thumbnail image
%
%INPUT:
%       -thumbnail: thumbnail image
%       -img_path: path for the output of mrxs_convert.py
%
%OUTPUT:
%       -thumbnail_scale: Spot matrix coordinates [xmin xmax ymin ymax]
%
% Ariotta Valeria  & Pohjonen Joona
% June 2019

function [thumbnail_scale] = get_thumbnail_scale(thumbnail, img_path)

%First we must find image dimensions from x and y coordinates
tmp = dir(img_path);
all_coord = cell(1,length(tmp)-2);
for j=3:length(tmp)
    all_coord{j-2} = cat(1,strcat(tmp(j).name));
end

%Find the last image
coord = char(all_coord(end));

%Get dimensions from the name
ind=find(coord=='_');
x_coord = str2double(regexp(coord(ind(end)+1:end),...
    '[0-9]\w+','match'));
y_coord = str2double(regexp(coord(ind(end-1)+1:ind(end)-1),...
    '[0-9]\w+','match'));

%Find out the individual image dimensions and add that to x and y
coord = char(all_coord(end-1));
ind=find(coord=='_');
x_coord_2 = str2double(regexp(coord(ind(end)+1:end),...
    '[0-9]\w+','match'));
small_image_dim = x_coord - x_coord_2;
x_coord = x_coord + small_image_dim;
y_coord = y_coord + small_image_dim;

%Get the scale
thumb_dim = size(thumbnail);
x_thumb = thumb_dim(2);
y_thumb = thumb_dim(1);
thumbnail_scale =  y_coord/y_thumb;

end