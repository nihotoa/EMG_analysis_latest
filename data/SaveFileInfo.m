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
taskname = 'standard'; %you don't need to change
save_fold = 'easyData'; %you don't need to change

%% code section
% get the real monkey name
[realname] = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname);

% get the name of files  which exists in base_dir
file_list = dir(fullfile(base_dir, [monkeyname '*.mat']));

% Extract oonly 'date' part from file name
for ii = 1:length(file_list)
    exp_day = regexp(file_list(ii).name, '\d+', 'match');
    tarsessions(ii,1) = str2double(exp_day{1});
end
tarsessions = unique(tarsessions);

% save each date's fileInfo(including imformation on monkeyname, xpdate, file_num) to a .mat file
common_save_fold_path = fullfile(base_dir, save_fold);
for tarN = 1:length(tarsessions)
    fileInfo.monkeyname = monkeyname;
    fileInfo.xpdate = tarsessions(tarN);
    ref_file = dir(fullfile(base_dir, [monkeyname num2str(tarsessions(tarN)) '*.mat']));
    temp_start = regexp(ref_file(1).name, '\d+', 'match');
    temp_end = regexp(ref_file(end).name, '\d+', 'match');
    tarfiles = [str2double(temp_start{2}) str2double(temp_end{2})];
    fileInfo.file_num = [tarfiles(1),tarfiles(2)];
    % save data
    makefold(common_save_fold_path)
    save(fullfile(common_save_fold_path, [monkeyname num2str(tarsessions(tarN)) '_' taskname '.mat']), 'fileInfo')
end
disp(['data is saved in ' common_save_fold_path])

