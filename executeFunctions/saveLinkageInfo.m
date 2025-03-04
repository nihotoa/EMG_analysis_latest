%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Navigate to the executeFunctions directory.
2. Change some parameters (please refer to 'set param' section)
3. Please run this code

[role of this code]
This script extracts and saves linkage information for each experimental day, including monkey name, experiment date, and file numbers. This information is crucial for organizing and accessing experimental data efficiently.

[saved data location]
- Folder path for linkage information: <root_dir>/saveFold/<full_monkey_name>/data/EMG_ECoG/linkageInfo_list/

[execution procedure]
- Pre: None
- Post: prepareEMGAndTimingData.m

%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkey_prefix = 'Hu' ; % prefix of recorded file(ex. F1710516-0002)

%% code section
% get the real monkey name
[full_monkey_name] = getFullMonkeyName(monkey_prefix);
root_dir = fileparts(pwd);
useDataFold_path = fullfile(root_dir, 'useDataFold', full_monkey_name);

% get the name of files  which exists in useDataFold_path
file_list = dirPlus(fullfile(useDataFold_path, '*.mat'));

% Extract only 'date' part from file name
file_num = length(file_list);
day_list = zeros(file_num, 1);
for file_id = 1:file_num
    exp_day = regexp(file_list(file_id).name, '\d+', 'match');
    day_list(file_id,1) = str2double(exp_day{1});
end
day_list = unique(day_list);
day_num = length(day_list);

% save each date's linkageInfo(including imformation on monkey_prefix, xpdate, file_num) to a .mat file
common_save_fold_path = fullfile(root_dir, 'saveFold', full_monkey_name, 'data', 'EMG_ECoG', 'linkageInfo_list');
makefold(common_save_fold_path)
linkageInfo.monkey_prefix = monkey_prefix;
for day_id = 1:day_num
    linkageInfo.xpdate = day_list(day_id);
    ref_file = dirPlus(fullfile(useDataFold_path, [monkey_prefix num2str(day_list(day_id)) '*.mat']));
    temp_start = regexp(ref_file(1).name, '\d+', 'match');
    temp_end = regexp(ref_file(end).name, '\d+', 'match');
    tarfiles = [str2double(temp_start{2}) str2double(temp_end{2})];
    linkageInfo.file_num = [tarfiles(1),tarfiles(2)];
    % save data
    makefold(common_save_fold_path)
    save(fullfile(common_save_fold_path, [monkey_prefix num2str(day_list(day_id)) '_linkageInfo']), 'linkageInfo')
end
disp(['data is saved in ' common_save_fold_path])

