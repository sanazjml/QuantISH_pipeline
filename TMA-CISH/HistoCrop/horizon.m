function [angle] = horizon(image, varargin)
% HORIZON estimates the horizon rotation in the image.
%   ANGLE=HORIZON(I) returns rotation of an estimated horizon
%   in the image I. The returned value ANGLE is in the
%   range <-45,45> degrees.
%
%   ANGLE=HORIZON(I, PRECISION) aligns the image I with
%   the predefined precision. The default value is 1 degree. If higher
%   precision is required, 0.1 could be a good value.
%
%   ANGLE=HORIZON(I, PRECISION, METHOD, DISKSIZE) aligns the image I with
%   the specified METHOD. Following methods are supported:
%       'fft' - Fast Fourier Transform, the default method,
%       'hough' - Hough transform, which finds lines in the image,
%       'blot' - Finds blots and estimates their's orientation.
%                Blot method allows additional parameter DISKSIZE that 
%                defines the filter size of morphological transformations.
%                The default value is 7. Note that this method 
%                may not work for all kind of pictures.
%
%   Example
%   -------
%       image = imread('board.tif');
%       angle = horizon(rgb2gray(image), 0.1, 'fft')
%       imshow(imrotate(image, -angle, 'bicubic'));
%
%   The example aligns the default image in Image Processing Toolbox.


% Parameter checking.
numvarargs = length(varargin);
if numvarargs > 3                   % only want 3 optional inputs at most
    error('myfuns:somefun2Alt:TooManyInputs', ...
        'requires at most 2 optional inputs');
end
optargs = {1, 'fft', 2};            % set defaults for optional inputs
optargs(1:numvarargs) = varargin;
[precision, method, diskSize] = optargs{:};  % use memorable variable names

% Check image dimension.
if ndims(image)~=2
    error('The image must be two-dimensional (i.e. grayscale).')
end

% Call the selected method
if strcmpi(method, 'fft')
    angle = horizonFFT(image, precision);
elseif strcmpi(method, 'hough')
    angle = horizonHough(image, precision);
else
    angle = horizonBlobs(image, precision, diskSize);
end

% Return the angle
angle = mod(45+angle,90)-45;            % rotation in -45..45 range
end

function angle = horizonFFT(image, precision)
% FFT.
maxsize = max(size(image));
T = fftshift(fft2(image, maxsize, maxsize)); % create rectangular transform
T = log(abs(T)+1);                           % get magnitude in <0..inf)  

% Combine two FFT quadrants together (another two quadrants are symetric).
center = ceil((maxsize+1)/2);
evenS = mod(maxsize+1, 2);
T = (rot90(T(center:end, 1+evenS:center), 1) + T(center:end, center:end));
T = T(2:end, 2:end);    % remove artifacts for expense of inaccuracy

% Find the dominant orientation
angles = floor(90/precision);
score = zeros(angles, 1);
maxDist = maxsize/2-1;

for angle = 0:angles-1
    [y,x] = pol2cart(deg2rad(angle*precision), 0:maxDist-1); % all [x,y]
    for i = 1:maxDist
        score(angle+1) = score(angle+1) + T(round(y(i)+1), round(x(i)+1));
    end
end

% Return the most dominant direction.
[~, position] = max(score);
angle = (position-1)*precision;
end

function angle = horizonHough(image, precision)
    % Detect edges.
    BW = edge(image,'prewitt');

    % Perform the Hough transform.
    [H, T, ~] = hough(BW,'Theta',-90:precision:90-precision);  

    % Find the most dominant line direction.
    data=var(H);                      % measure variance at each angle 
    fold=floor(90/precision);         % assume right angles & fold data
    data=data(1:fold) + data(end-fold+1:end);
    [~, column] = max(data);          % the column with the crispiest peaks
    angle = -T(column);               % column to degrees 
end

function angle = horizonBlobs(image, precision, diskSize)
% perform morphological operations
bw = im2bw(image);
bw = imopen(bw, strel('disk', diskSize));       % fill holes
bw = imclose(bw, strel('disk', diskSize));      % remove spackles

% get region properties
stat = regionprops(~bw, 'Area', 'BoundingBox', 'Orientation');

% select only some blobs
dimensions = cat(1, stat.BoundingBox);
area = cat(1, stat.Area);
boundingBoxArea = dimensions(:,3).*dimensions(:,4);
areaRatio = boundingBoxArea./area;

% create histogram of orientations in the picture
histogram = hist(cat(1, stat(areaRatio>1.2).Orientation), -90:precision:90);

% fold the histogram
len = ceil(length(histogram)/2);
histogram = histogram(1:len)+histogram(len:end);

% find the peak and return the dominant orientation
[~, index] = max(histogram);
angle = mod(-precision*(index-1)+45,90)-45;    % index -> angle
end