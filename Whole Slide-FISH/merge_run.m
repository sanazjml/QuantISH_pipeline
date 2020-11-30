% read spot image
img1= imread(src_spot1);
img2= imread(src_spot2);
img3= imread(src_spot3);
img4= imread(src_spot4);


% classify
[merge] = merge_wsi(img1, img2, img3, img4);
imwrite(merge, dest);

