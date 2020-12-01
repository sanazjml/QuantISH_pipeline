
% author: Antti Häkkinen
% PRINCOMPGEN Non-orthogonal basis analysis using power iteration.
%   [coeff, score, latent, center]= PRINCOMPGEN(X, ...)

function [coeff, score, latent, center]= princompgen(X, varargin)
	%%
	% get dimensions
	[~, n]= size(X);
	
	% set up defaults
	opts= struct( ...
		'maxiter', 100, ...
		'start', eye(n, 'like', X));
	
	% parse options
	for j= 1:2:numel(varargin)
		opts.(lower(varargin{j}))= varargin{j+1};
	end
	
	%%
	% create outputs
	coeff= nan(size(opts.start), 'like', opts.start);
	center= nan(n, 1, 'like', X);
	
	% optimize
	[coeff(:), center(:)]= princompgenmex( single(X), ...
		single(opts.start), single(opts.maxiter) );
	
	%%
	% compute score & variance if they were requested
	if nargout >= 2
		score= (( X - center.' )) / coeff.';
	end
	if nargout >= 3
		latent= var( score, [], 1 );
	end
