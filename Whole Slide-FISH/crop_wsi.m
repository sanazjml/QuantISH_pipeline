function [crop1, crop2, crop3, crop4] = crop_wsi(img)
% Enter an image
n = floor(size(img)/2);
m = size(img);
Lpic1 = img(1:n(1),1:n(2),:);
Rpic1 = img(1:n(1),n(2)+1:m(2),:);
Lpic2 = img(n(1)+1:m(1),1:n(2),:);
Rpic2 = img(n(1)+1:m(1),n(2)+1:m(2),:);
crop1 = Lpic1;
crop2 = Rpic1;
crop3 = Lpic2;
crop4 = Rpic2;
