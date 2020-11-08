%This function removes spots that overlap with removed_spots or new_spots
%and adds new_spots to all_spots
%INPUT:
%       -all_spots: old TMA spots
%       -remove_spots: spots to be removed
%       -new_spots: spots to be replaced
%
% Ariotta Valeria  & Pohjonen Joona
% June 2019

function [all_spots] = get_new_spots(all_spots, remove_spots, new_spots)

% Go trough all old spots
for tma_i=1:length(all_spots)
    
    % See if remove_spots overlap with old spots
    if ~isempty(remove_spots{tma_i})
        for new_spot_i=1:length(remove_spots{tma_i}(:,1))
            for old_spot_i=1:length(all_spots{tma_i})
                all_spots{tma_i}(old_spot_i,5+new_spot_i) = bboxOverlapRatio(...
                    cell2mat(remove_spots{tma_i}(new_spot_i,:)),...
                    all_spots{tma_i}(old_spot_i,2:5));
            end
        end
        all_spots{tma_i}(:,6) = sum(all_spots{tma_i}(:,6:end),2);
        all_spots{tma_i} = all_spots{tma_i}(:,1:6);
        
    else
        all_spots{tma_i}(:,6) = 0;
    end
    
     % See if new_spots overlap with old spots
    if ~isempty(new_spots{tma_i})
        for new_spot_i=1:length(new_spots{tma_i}(:,1))
            for old_spot_i=1:length(all_spots{tma_i})
                all_spots{tma_i}(old_spot_i,6+new_spot_i) = bboxOverlapRatio(...
                    cell2mat(new_spots{tma_i}(new_spot_i,:)),...
                    all_spots{tma_i}(old_spot_i,2:5));
            end
        end
        all_spots{tma_i}(:,7) = sum(all_spots{tma_i}(:,7:end),2);
        all_spots{tma_i} = all_spots{tma_i}(:,1:7);  
    else
        all_spots{tma_i}(:,7) = 0;
    end
    
    % Remove spots that overlap with remove_spots
    all_spots{tma_i} = all_spots{tma_i}(all_spots{tma_i}(:,6) == 0,:);
    
    % Replace spots that overlap with new_spots
    all_spots{tma_i} = [all_spots{tma_i}(all_spots{tma_i}(:,7) == 0,2:5);...
        cell2mat(new_spots{tma_i})];
end
end
