%{ 
[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code

[role of this code]
get the information which is used for merge data

[Saved data location]
location: Yachimun/easyData/
file name: ~_standard.mat (ex.) F170516_standard.mat

[procedure]
pre: (if you want to Nibali's data) generateRawData.m
post : (if you want to conduct synergy analysis) SAVE4NMF.m
       (if you want to conduct EMG analysis) runnningEasyfunc.m

[correction Point]
made 'makefold.m' & add this function berore saving
%}
clear;
%% set param
monkeyname = 'Hu' ; % prefix of recorded file(ex. F1710516-0002)

%% code section
% get the real monkey name
[realname] = get_real_name(monkeyname);
root_dir = fileparts(pwd);
useDataFold_path = fullfile(root_dir, 'useDataFold', realname);

% get the name of files  which exists in useDataFold_path
file_list = dirEx(fullfile(useDataFold_path, '*.mat'));

% Extract only 'date' part from file name
file_num = length(file_list);
day_list = zeros(file_num, 1);
for file_id = 1:file_num
    exp_day = regexp(file_list(file_id).name, '\d+', 'match');
    day_list(file_id,1) = str2double(exp_day{1});
end
day_list = unique(day_list);
day_num = length(day_list);

% save each date's linkageInfo(including imformation on monkeyname, xpdate, file_num) to a .mat file
common_save_fold_path = fullfile(root_dir, 'saveFold', realname, 'data', 'EMG_ECoG', 'linkageInfo_list');
makefold(common_save_fold_path)
linkageInfo.monkeyname = monkeyname;
for day_id = 1:day_num
    linkageInfo.xpdate = day_list(day_id);
    ref_file = dirEx(fullfile(useDataFold_path, [monkeyname num2str(day_list(day_id)) '*.mat']));
    temp_start = regexp(ref_file(1).name, '\d+', 'match');
    temp_end = regexp(ref_file(end).name, '\d+', 'match');
    tarfiles = [str2double(temp_start{2}) str2double(temp_end{2})];
    linkageInfo.file_num = [tarfiles(1),tarfiles(2)];
    % save data
    makefold(common_save_fold_path)
    save(fullfile(common_save_fold_path, [monkeyname num2str(day_list(day_id)) '_linkageInfo']), 'linkageInfo')
end
disp(['data is saved in ' common_save_fold_path])

