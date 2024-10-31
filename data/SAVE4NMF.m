%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code & select data by following guidance (which is displayed in command window after Running this code)

[role of this code]
concatenate & create one-day EMG data (with resampling(5000Hz)) & save individual muscle data as '(uv).mat' 

[Saved data location]
location: Yachimun/new_nmf_result/'~_standard' (ex.) F170516_standard
file name: muscle_name(uV).mat (ex.) PL(uV).mat

[procedure]
pre:runningEasyfunc.m
post:filterBat_SynNMFPre.m

[Improvement points(Japanaese)]
・ファイルを連結する時に, 連番じゃ無いものは対応していないことを念頭に置いておく
(例)file 002, file004が使用するファイルだった時にはエラー吐く(002, 003, 004をloadしようとするから)
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkey_name = 'Hu'; % prefix of file
save_fold = 'new_nmf_result'; % not need to change

%% code section
real_name = get_real_name(monkey_name);

%  get the file name list of  '~standard.mat'
easyData_fold_path = fullfile(pwd, real_name, 'easyData');
disp('Please select all "_standard" folder you want to pre-process');
easyData_folder_list = uiselect(dirdir(easyData_fold_path), 1, 'Please select all "_standard" folder you want to  pre-process');

if isempty  (easyData_folder_list)
    disp('user press "cancel" button');
    return;
end

session_num = length(easyData_folder_list);
common_save_fold_path = fullfile(pwd, real_name, save_fold);
% combine multiple data for one day into a single data
for session_id = 1:session_num
   ref_easyData_folder = easyData_folder_list{session_id};
   common_file_name = strrep(ref_easyData_folder, '_standard', '');
   load(fullfile(easyData_fold_path, ref_easyData_folder, [common_file_name '_EasyData.mat']), 'AllData_EMG', 'SampleRate', 'EMGs', 'TimeRange_EMG', 'Tp', 'Unit'); 

   % concatenate experiment data and save each EMG as individual file
   MakeData4nmf(common_save_fold_path, ref_easyData_folder, EMGs, SampleRate, AllData_EMG, TimeRange_EMG, 'Unit')
end

%% define local function

% [role of this function] concatenate experiment data and save each EMG as individual file
function [] = MakeData4nmf(common_save_fold_path, unique_save_folder_name, EMGs, SampleRate, AllData_EMG, TimeRange, Unit)
EMG_num = length(EMGs);
% save EMG data as .mat file for nmf
save_fold_path = fullfile(common_save_fold_path, unique_save_folder_name);
makefold(save_fold_path)

% save each muscle EMG data to a file
Class = 'continuous channel';
for i = 1:EMG_num
    Name = cell2mat(EMGs(i,1));
    Data = AllData_EMG(:, i)';
    save(fullfile(save_fold_path, [cell2mat(EMGs(i,1)) '(uV).mat']), 'TimeRange', 'Name', 'Class', 'SampleRate', 'Data', 'Unit');
    disp([fullfile(save_fold_path, [cell2mat(EMGs(i,1)) '(uV).mat']) ' was generated successfully!!']);
end
end

