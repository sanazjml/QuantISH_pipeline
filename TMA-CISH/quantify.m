
function stats= quantify(img, Sig, labels, clazzes)
	%%
	% TODO: implement low pass filter etc. 
	% Cell expansion
            
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
	

	%%
	% get signal
        
        Sig = imcomplement(Sig);
        Sig = im2single(Sig);
        black_rad= 10;   % edge radius of black stuff
        black_tol= 5/256;     % tolerance : up to 5 bins away from total black
        SIG = Sig .* ~imdilate( mean( (( im2double(img) - 0 )).^2, 3 ) <= black_tol.^2, strel('disk', black_rad, 0) );
	
	% sum up the intensity
	stats= struct;
	stats.SumIntensity= accumarray( expanded_labels(expanded_labels > 0),  SIG(expanded_labels > 0), [], @sum );
	stats.Area= accumarray( expanded_labels(expanded_labels > 0),  1, [], @sum );
        stats.Normalized = stats.SumIntensity ./ stats.Area;


