function clazzes= classify_fun(img, labels)
%%
%%
gray_img = rgb2gray( img );
%%
     
%%
% compute object properties
props = regionprops(labels, 'Area', 'Centroid', 'PixelIdxList', 'Eccentricity', 'Circularity', ...
    'MinorAxisLength', 'MajorAxisLength', 'PixelList', 'Image', 'Perimeter');


% compute more stuff from img
for j= 1:numel(props)
    props(j).MeanIntensity= mean( gray_img( props(j).PixelIdxList ) );
end


V = [ log([props.Area].'), [props.MeanIntensity].', log( 1 - [props.Eccentricity].' ) ];

%%
load('training_data.mat')
table = Table_Training ;
V_total = cell2mat(table(:,5:7));
L_total = cell2mat(table(:,2));
%%

L_TREE = fitcdiscr (V_total,  L_total, 'DiscrimType','quadratic', 'Prior', 'uniform');
[Label, score, cost] = predict(L_TREE, V);
% 

score_for_pix_of_cell = score ./ [ props.Area ].';  % tune kernels


L_pix = zeros(size(labels));
L_pix(labels > 0 ) = Label(labels(labels > 0));

clear gray_img;
num = numel(props);
clear props;
nonzero_pix= ismember( L_pix, 1:5);


prob_maps = zeros( size(img, 1) , size(img, 2) , size(score,2) );
for k = 1:size(score, 2)
    v= accumarray( find(nonzero_pix), score_for_pix_of_cell( labels(nonzero_pix) , k ), [numel(labels), 1], @sum );
    prob_maps(:, : , k ) = reshape( v, size(prob_maps, 1), size(prob_maps, 2) );    
end

prior_w= sum( reshape( prob_maps, [], size(prob_maps, 3) ), 1 ).';

% disk kernel
kern= fspecial('disk', 100 );


filt_prob_maps= nan(size(prob_maps));
for k = 1:size(prob_maps,3)
	filt_prob_maps(:,:,k)= convnfft( prob_maps(:,:,k), kern(end:-1:1, end:-1:1), 'same' );
end

size_prop = size(prob_maps, 3);
clear prop_maps;
Labels_filt= nan(num, 1);
v = nan( num, size_prop );
cross_coefs = [ 1,1,1,0,0,0; 1,1,1,0,0,0; 1,1,1,0,0,0; 1,1,1,1,1,1 ; 1,1,1,1,1,1 ];
for k = 1:size_prop     
    v(:, k)= accumarray( labels(labels >0), filt_prob_maps( find(labels > 0) + (k-1)*numel(filt_prob_maps(:,:,k)) ) .* ...
        cross_coefs( L_pix(labels > 0) , k ) / prior_w(k) , [ num, 1] , @sum );    
end
    [~, Labels_filt]= max( v, [] , 2) ;

%%
clazzes = Labels_filt;
