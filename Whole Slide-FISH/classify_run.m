
% read spot image
img= imread(src_spot);

% read segmented image
rgb_labels= imread(src_merged);
labels= rgb2label(rgb_labels);

% classify
clazzes= classify_f(img, labels);
tab= table( (1:max(labels(:))).', clazzes, 'VariableNames', {'segment_id', 'class'} );
writetable(tab, dest, 'FileType', 'text', 'Delimiter', '\t');
