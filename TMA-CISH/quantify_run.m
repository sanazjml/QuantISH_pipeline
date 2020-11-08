
% read spot image
img= imread(src_spot);
Sig= imread(src_channel);
% read segmented image
rgb_labels= imread(src_segmented);
labels= rgb2label(rgb_labels);

% read classes
tab= readtable(src_classes, 'FileType', 'text', 'Delimiter', '\t');

% quantify signal
stats= quantify(img, Sig, labels, tab.class);

% add stats to the table
stat_keynames= fieldnames(stats);
for j= 1:numel(stat_keynames)
	tab.(stat_keynames{j})= stats.(stat_keynames{j});
end

% write output
writetable(tab, dest, 'FileType', 'text', 'Delimiter', '\t');
