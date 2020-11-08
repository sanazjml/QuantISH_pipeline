
% read spot image
%img= imread(src_spot);
chan1= src_channel1;
chan2= src_channel2;
chan3= src_channel3;

% read segmented image
rgb_labels= imread(src_merged);
labels= rgb2label(rgb_labels);

% read classes
tab= readtable(src_classes, 'FileType', 'text', 'Delimiter', '\t');

% quantify signal
stats= quantify(labels, chan1, chan2, chan3, tab.class);

% add stats to the table
stat_keynames= fieldnames(stats);
for j= 1:numel(stat_keynames)
	tab.(stat_keynames{j})= stats.(stat_keynames{j});
end

% write output
writetable(tab, dest, 'FileType', 'text', 'Delimiter', '\t');
