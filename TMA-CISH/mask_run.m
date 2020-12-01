
% read spot image
img= imread(src_spot);
Sig = imread(src_channel);

% make the mask of color channel
Mask= mask_fun(img, Sig);
imwrite( Mask, dest);
