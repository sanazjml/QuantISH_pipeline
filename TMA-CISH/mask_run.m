
% read spot image
img= imread(src_spot);
Sig = imread(src_channel);

% mask
Mask= mask_fun(img, Sig);
imwrite( Mask, dest);