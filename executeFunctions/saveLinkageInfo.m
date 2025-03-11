%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Navigate to the executeFunctions directory.
2. Change some parameters (please refer to 'set param' section)
3. Please run this code

[role of this code]
This script compiles and saves information necessary for concatenating multiple 
AlphaOmega files from the same experimental day. It creates structured metadata 
files that facilitate the integration of fragmented recordings into cohesive 
datasets for subsequent analysis.

[saved data location]
The location of the saved file is shown in the log when this function is executed.

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
full_monkey_name = getFullMonkeyName(monkey_prefix);
root_dir_path = fileparts(pwd);
useDataFold_path = fullfile(root_dir_path, 'useDataFold', full_monkey_name);

% get the name of files  which exists in useDataFold_path
file_list = dirPlus(fullfile(useDataFold_path, '*.mat'));

% Extract only 'date' part from file name
file_num = length(file_list);
experiment_day_list = zeros(file_num, 1);
for file_id = 1:file_num
    tentetive = regexp(file_list(file_id).name, '\d+', 'match');
    experiment_day_list(file_id,1) = str2double(tentetive{1});
end
experiment_day_list = unique(experiment_day_list);
day_num = length(experiment_day_list);

% save each date's linkageInfo(including imformation on monkey_prefix, experiment_day, file_num) to a .mat file
common_save_dir_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'EMG_ECoG', 'linkageInfo');
makefold(common_save_dir_path)
linkageInfo.monkey_prefix = monkey_prefix;
for day_id = 1:day_num
    linkageInfo.experiment_day = experiment_day_list(day_id);
    ref_file = dirPlus(fullfile(useDataFold_path, [monkey_prefix num2str(experiment_day_list(day_id)) '*.mat']));
    tentetive1 = regexp(ref_file(1).name, '\d+', 'match');
    tentetive2 = regexp(ref_file(end).name, '\d+', 'match');
    validate_file_range = [str2double(tentetive1{2}) str2double(tentetive2{2})];
    linkageInfo.validate_file_range = [validate_file_range(1),validate_file_range(2)];
    
    % save data
    makefold(common_save_dir_path)
    save(fullfile(common_save_dir_path, [monkey_prefix num2str(experiment_day_list(day_id)) '_linkageInfo']), 'linkageInfo')
    disp(['Saved linkage info for ' monkey_prefix num2str(experiment_day_list(day_id)) ' to: ' fullfile(common_save_dir_path, [monkey_prefix num2str(experiment_day_list(day_id)) '_linkageInfo.mat'])]);
end

