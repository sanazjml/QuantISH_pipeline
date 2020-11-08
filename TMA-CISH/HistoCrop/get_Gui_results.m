
function all_spots = get_Gui_results(all_summaries, all_spots, all_angles, List_Rect, n_rows, n_cols )
    %%
    add_rect_data = List_Rect.add_rect_data;
    rem_rect_data = List_Rect.rem_rect_data;
    add_Img_num = List_Rect.add_Img_num;
    rem_Img_num = List_Rect.rem_Img_num;
    
    % Initialize
    new_spots = cell(length(all_summaries),1);
    remove_spots = cell(length(all_summaries),1);
    
    % Change format for new spots
    for i=1:length(all_summaries)
        try
            %find the right coordinates for each image
            add_index = add_Img_num == i;
            new_spots{i} = {add_rect_data{add_index}};
        catch
            new_spots{i} = cell(1);
        end
        new_spots{i} = new_spots{i}';
    end
    
    %Cell to mat conversion
    for i=1:length(all_summaries)
        for ii=1:size(new_spots{i},1)
            tmp =  new_spots{i}{ii};
            new_spots{i}{ii,1} = tmp(1);
            new_spots{i}{ii,2} = tmp(2);
            new_spots{i}{ii,3} = tmp(3);
            new_spots{i}{ii,4} = tmp(4);
        end
    end
    
    % Change format for remove spots
    for i=1:length(all_summaries)
        try
            rem_index = rem_Img_num == i;
            remove_spots{i} = {rem_rect_data{rem_index}};
        catch
            remove_spots{i} = cell(1);
        end
        remove_spots{i} = remove_spots{i}';
    end
    
    %Cell to mat
    for i=1:length(all_summaries)
        for ii=1:size(remove_spots{i},1)
            tmp =  remove_spots{i}{ii};
            remove_spots{i}{ii,1} = tmp(1);
            remove_spots{i}{ii,2} = tmp(2);
            remove_spots{i}{ii,3} = tmp(3);
            remove_spots{i}{ii,4} = tmp(4);
        end
    end
    
    %Get new spots based on user input
    all_spots = get_new_spots(all_spots,remove_spots,new_spots);
    
    %Find the correct order
    all_spots = get_order(all_spots, all_summaries, all_angles,...
        n_rows, n_cols);
    