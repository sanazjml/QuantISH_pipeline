function stats= quantify(labels, chan1, chan2, chan3, clazzes)

% cell expansion to include cytoplasm
expansion_radii = [ 20, 5, 5 ] ;
Labels_filt = clazzes;
cancerindex = find(ismember(Labels_filt, 1)).';
cancernuclei = ismember(labels, cancerindex);

se = strel('disk', expansion_radii(1), 0);
cancercells = imdilate(cancernuclei, se);


immuneindex = find(ismember(Labels_filt, 2)).';
immunenuclei = ismember(labels, immuneindex);

se = strel('disk', expansion_radii(2), 0);
immunecells = imdilate(immunenuclei, se);


stromaindex = find(ismember(Labels_filt, 3)).';
stromanuclei = ismember(labels, stromaindex);

se = strel('disk', expansion_radii(3), 0);
stromacells = imdilate(stromanuclei, se);

finalImage = cancercells | immunecells | stromacells ;

D= Inf(size(labels));
IDX = reshape( 1:numel(labels), size(labels) );
for k= 1:numel(expansion_radii)
    [ D1, IDX1 ]= bwdist( ismember( labels, find(Labels_filt == k) ));
    D1= D1 / expansion_radii(k);
    D1( labels > 0 )= inf;
    IDX( D1 < D )= IDX1( D1 < D );
    D( D1 < D )= D1( D1 < D );
end

expanded_labels= zeros(size(labels), 'like', labels); 
expanded_labels(:)= labels(IDX);
expanded_labels( ~( finalImage | labels > 0 ) )= 0;

% read multiple channels per each image
srcs = {chan1, chan2, chan3};
	
	for j= numel(srcs) : -1 : 1
		X(:, :, j)= mean( im2single( imread(srcs{j}) ), 3 );
    end
	
% remove cross-channel effects
    V = reshape( X, [], size(X, 3) );

    c0= median( V, 1 );
    [U, Z, ~, c]= princompgen( V - c0, 'MaxIter', 1 );
    c= c0.' + c;
    clear V;
 

     Z( ~(( Z == max( Z, [], 2 ) )) )= 0;
     Z= reshape( Z, size(X) );
     %clear X;  % we can give up some memory here
	
     % quantify RNA expression
       lsigma= 1; lr= 15;  % log kernel sd & radius
       for j= 1:size(Z, 3)
	      Z(:, :, j)= max( imfilter( Z(:, :, j), -fspecial('log', lr, lsigma) ), 0 );
	end
	
  ch1 = Z(:, :, 1);
  ch2 = Z(:, :, 2);
  ch3 = Z(:, :, 3);

  stats= struct;
  stats.SumIntensity_Cy5= accumarray( expanded_labels(expanded_labels > 0), ch1(expanded_labels > 0), [], @sum );
  stats.SumIntensity_FITC= accumarray( expanded_labels(expanded_labels > 0), ch2(expanded_labels > 0), [], @sum );
  stats.SumIntensity_TRITC= accumarray( expanded_labels(expanded_labels > 0), ch3(expanded_labels > 0), [], @sum );
  stats.Area= accumarray( expanded_labels(expanded_labels > 0),  1, [], @sum );   
  
  
  
