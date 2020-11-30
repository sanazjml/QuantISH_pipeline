function Mask = mask_fun(img, Sig)
Sig = imcomplement(Sig);
Sig = im2single(Sig);
black_rad= 10;   % edge radius of black stuff
black_tol= 5/256;
Sig = Sig .* ~imdilate( mean( (( im2double(img) - 0 )).^2, 3 ) <= black_tol.^2, strel('disk', black_rad, 0) );
SIG = imdilate( Sig, strel('disk', 4, 0));
%% fill holes
mask = zeros(size(img,1), size(img,2) );
mask (SIG ~= 0 ) = 1;
Mask = mask;