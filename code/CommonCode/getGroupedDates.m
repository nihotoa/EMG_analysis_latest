function [Allfiles_S] = getGroupedDates(base_dir, monkeyname, term_select_type, term_type)

% define TT-syurgery date
switch monkeyname
    case {'Ya', 'F'}
        TT_day = '20170530';
    case 'Ni'
        TT_day = '20220530';
end

% Create a list of folders containing the synergy data for each date.
switch term_select_type
    case 'auto'
        data_folders = dir(base_dir);
        folderList = {data_folders([data_folders.isdir]).name};
        Allfiles_S = folderList(startsWith(folderList, monkeyname));
        
        [prev_last_idx, post_first_idx] = get_term_id(Allfiles_S, 1, TT_day);
        
        switch term_type
            case 'pre'
                Allfiles_S = Allfiles_S(1:prev_last_idx);
            case 'post'
                Allfiles_S = Allfiles_S(post_first_idx:end);
            case 'all'
                % no processing
        end
    case 'manual'
        disp('Please select date folders which contains the VAF data you want to plot');
        Allfiles_S = uiselect(dirdir(base_dir),1,'Please select date folders which contains the VAF data you want to plot');
        if isempty(Allfiles_S)
            disp('user pressed "cancel" button');
            return;
        end
end
end

