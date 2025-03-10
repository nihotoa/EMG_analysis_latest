function [selected_file_name_list, TT_surgery_day] = getGroupedDates(base_dir_path, monkey_prefix, term_select_type, term_type)

% define TT-syurgery date
switch monkey_prefix
    case {'Ya', 'F'}
        TT_surgery_day = '20170530';
    case 'Se'
        TT_surgery_day = '20200120';
    case 'Ni'
        TT_surgery_day = '20220530';
    case 'Hu'
        TT_surgery_day = '20250120';
end

% Create a list of folders containing the synergy data for each date.
switch term_select_type
    case 'auto'
        data_folders = dirPlus(base_dir_path);
        folderList = {data_folders.name};
        selected_file_name_list = folderList(startsWith(folderList, monkey_prefix));
        
        [prev_last_idx, post_first_idx] = get_term_id(selected_file_name_list, 1, TT_surgery_day);
        
        switch term_type
            case 'pre'
                selected_file_name_list = selected_file_name_list(1:prev_last_idx);
            case 'post'
                selected_file_name_list = selected_file_name_list(post_first_idx:end);
            case 'all'
                % no processing
        end
    case 'manual'
        disp('Please select date folders which contains the VAF data you want to plot');
        selected_file_name_list = uiselect(dirdir(base_dir_path),1,'Please select date folders which contains the VAF data you want to plot');
        if isempty(selected_file_name_list)
            return;
        end
end
end

