%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Verify that the prefix of the measurement data is correct.
2. Navigate to the executeFunctions directory.
3. Change some parameters (please refer to 'set param' section)
4. Please run this code

[role of this code]
This script reads EMG data from .nev files and ECoG & timing data from AlphaOmega files. 
It then concatenates all files for a single day and merges the data into a single file 
in the format <monkeyname><day>-<file number>.mat. This is useful for consolidating 
scattered experimental data into a unified format for further analysis.

[saved data location]
- Folder path for AllData_<monkeyname><exp_day>.mat: <root_dir>/saveFold/<realname>/data/EMG_ECoG/AllData_list/
- Folder path for <monkeyname><day>-<file number>.mat: <root_dir>/useDataFold/<realname>/

[execution procedure]
- Pre: None
- Post: extractAndSaveLinkageInfo.m

[Improvement point(Japanese)]
(ok!) concatenateDataで、error入った時に、そこで処理終了するんじゃなくて、関数抜けてcontinueして次の日付のiterationへ行くようにする
(ok!) error文を変えたほうがいい
+ CTTL002のUp,Downの数が異なる場合があるので、処理を追加(20250219がそれに対応している)
+ CTTL3と2のロジック部分がわからなすぎるので、リファクタリング
+ たまにCTTL関連のデータがセーブされない時があるので、原因を探る
+ データがデカすぎてセーブできないことがあるので、使ってないチャンネルを削るようにする(サルごとに設定)
+ ログが汚いので、治してもらう(composarに頼む)
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkeyname = 'Hu'; % prefix of recorded file name
down_SR = 1375; % which sampling rate do you want? (set this param below 1375)
select_type = 'manual'; % which folder selection type do you want? 'manual' / 'auto'

%% code section
% get the real monkey name
[realname] = get_real_name(monkeyname);
root_dir = fileparts(pwd);
base_dir = fullfile(root_dir, 'useDataFold', realname);

switch select_type
    case 'auto'
        folder_list = dirEx(base_dir);
        folder_name_list = {folder_list.name};
    case 'manual'
        disp('Please select all folders which contains the data you want to analyze')
        folder_name_list = uiselect(dirdir(base_dir),1,'Please select folders which contains the data you want to analyze');
end

if isempty(folder_name_list)
    disp("user press 'cancel'");
    return;
end

for idx = 1:length(folder_name_list)
    exp_day = folder_name_list{idx};
    disp(['start processing for the data in ' exp_day '...']);

    % generate EMG data
    [CEMG_struct, amplitude_unit, record_time] = generateEMG(base_dir, exp_day, down_SR);
    disp([exp_day ' EMG_RecordTime: ' num2str(record_time) '[s]']);
    
    try
        % generate(concatenate) ECoG & timing data.
        [CAI_struct, CLFP_struct, CRAW_struct, CTTL_struct] = concatenateData(base_dir, exp_day, monkeyname, down_SR, record_time);
    catch
        disp("skip to next day's data processing...")
        continue;
    end
    
    % save data
    save_dir = fullfile(root_dir, 'saveFold', realname, 'data', 'EMG_ECoG', 'AllData_list');
    if not(exist(save_dir, "dir"))
        makefold(save_dir)
    end
    all_data_file_path = fullfile(save_dir, ['AllData_' monkeyname exp_day '.mat']); % this file was made to provide Roland-san.
    row_data_file_path = fullfile(base_dir, [monkeyname exp_day(3:end) '-' sprintf('%04d', 1) '.mat']); % this file was made to align format with data obtained from 'Yachimun' or 'Seseki')

    saveRawData(all_data_file_path, CEMG_struct, CAI_struct, CRAW_struct, CLFP_struct, CTTL_struct);
    saveRawData(row_data_file_path, CEMG_struct, CAI_struct, CRAW_struct, CLFP_struct, CTTL_struct);
    disp(['The data for' exp_day 'was propely processed!!']);

    % clear only struct type
    vars = who;
    for var_id = 1:length(vars)
        if isstruct(eval(vars{var_id}))
            eval(['clear ' vars{var_id} ';']);
        end
    end
end
disp('All processing is completed');
