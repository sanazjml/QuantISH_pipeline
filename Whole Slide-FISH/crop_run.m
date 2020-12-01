
% read spot image
img= imread(src_spot);

% crop each image to 4 subimage
[crop1 , crop2, crop3, crop4] = crop_wsi(img);
imwrite(crop1, dest1);
imwrite(crop2, dest2);
imwrite(crop3, dest3);
imwrite(crop4, dest4);


