
% author: Antti Häkkinen
% CONVNFFT N-D convolution using fast Fourier transform.
%   C= CONVNFFT(A, B) computes an N-dimensional convolution, like
%   CONVN(A, B), but using a fast Fourier transform.

function C= convnfft(A, B, shape)
	%%
	% apply defaults
	if nargin < 3 || isempty(shape)
		shape= 'full';
	end
	
	%%
	% compute padding
	siz= size(A) + size(B) - 1;
	
	% compute the FFTs & invert
	C= ifftn( fftn(A, siz) .* fftn(B, siz) );
	
	% slice out the part of interest
	switch shape
		case 'same'
			C= extract_( C, fix( size(B)/2 ), size(A) );
		case 'valid'
			C= extract_( C, size(B)-1, size(A) - (( size(B)-1 )) );
	end
	
	% real problem?
	if isreal(A) && isreal(B)
		C= real(C);
	end
	
function C= extract_(C, ptr, siz)
	%%
	% make slicing indices
	args= repmat({':'}, 1, ndims(C));
	for k= 1:ndims(C)
		args{k}= ptr(k) + (1:siz(k));
	end
	
	% extract part
	C= C(args{:});
