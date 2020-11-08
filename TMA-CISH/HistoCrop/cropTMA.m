% Main code for cropping TMA spots from the output of mrxsdump.py
%
%INPUT:
%       -root: Folder of the extracted image from mrxs files using mrxsdump.py
%       -item: Name of TMA slide image you want to crop
%       -image_name = the name you prefer for your output 
%       -n_rows: Maximum number of rows in TMA
%       -n_cols: Maximum number of cols in TMA
%       -height: The bigger dimension of high resolution layer in mrxs image
%       -width: The smaller dimension of high resolution layer in mrxs image
%
% Written by Ariotta Valeria  & Pohjonen Joona
% Modified by Sanaz Jamalzadeh, Antti Häkkinen

%%
clc

image = imread( fullfile( root, item  ));

[spots, summaryImg, angle] = spot_coord(image , n_rows, n_cols);

%%
% GUI part
        [mat_coord] = spot_matrix(image);

all_summaries = { summaryImg };
    save('tmp_summaries','all_summaries','mat_coord');
    Spot_Cut_Gui;
    waitfor(Spot_Cut_Gui)
  
all_spots = get_Gui_results( all_summaries, {spots}, {angle}, load('List_Rect.mat'), n_rows, n_cols );

%%

x = ceil( all_spots{1}(:, 2) );
y = ceil( all_spots{1}(:, 3) );
w = all_spots{1}(:, 4);
h = all_spots{1}(:, 5);

th = height/ size(image, 1);     
tw = width / size(image, 2 ) ;   


xfull = tw*(x-1);
yfull = th*(y-1);

wfull = tw*w;
hfull = tw*h;

% 0-based coordinates
out_table = array2table( uint64(round( [ xfull, yfull, wfull, hfull ] )), ...
    'VariableNames', {'x', 'y', 'w', 'h'} );
num_spots = size( all_spots{1}, 1) ;

 out_table_head = table( strvcat(repmat({image_name}, num_spots, 1)), (1:num_spots).', ...
     'VariableNames', {'name', 'spot'} );



writetable([ out_table_head, out_table ], sprintf('%s.csv',item), 'Delimiter', 'tab');



