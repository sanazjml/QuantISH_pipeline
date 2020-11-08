
% RGB2LABEL Convert an RGB image to labels
%   [labels, cc]= RGB2LABEL(img)

function [labels, cc]= rgb2label(img)
	%%
	% check input
	assert( ndims(img) == 3 && size(img, 3) == 3, ...
		'The input must be a M-by-N-by-3 matrix.' );
	
	%% 
	% mask out background
	mask= ~all( img == img(:, :, 1), 3 );
	
	% find labels
	data= reshape( img, [], size(img, 3) );
	inds= zeros( size(img, 1), size(img, 2), 'uint32' );
	[~, ~, inds(mask)]= unique( data(mask, :), 'rows', 'stable' );
	
	%%
	% set up 
	cc= struct('Connectivity', 8, 'ImageSize', size(inds), ...
		'NumObjects', 0, 'PixelIdxList', { cell(0, 1) } );
	
	% trace connected
	for j= 1:max(inds(:))
		cc_j= bwconncomp(inds == j, cc.Connectivity);
		cc.NumObjects= cc.NumObjects + cc_j.NumObjects;
		cc.PixelIdxList= [ cc.PixelIdxList, cc_j.PixelIdxList ];
	end
	
	%%
	% get labels
	labels= labelmatrix(cc);
