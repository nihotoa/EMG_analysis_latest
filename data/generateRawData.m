%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code

[role of this code]
1, Read EMG data from ,nev files (contains EMG data)
2. Read AlphaOmega file (contains ECoG & timing data) & concatenate all files for one day
3. merge all data which is created 1 & 2 and save as <monkeyname><day>-<file number>.mat

[Saved data location]
folder path: <pwd>/Nibali/
file name: <monkeyname><day>-<file number>.mat  (ex.)Ni220420-0001.mat

[procedure]
pre: nothing
post : SaveFileInfo.m

[Improvement point(Japanese)]

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
base_dir = fullfile(pwd, realname);

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
    % generate EMG data
    [CEMG_struct, amplitude_unit, record_time] = generateEMG(base_dir, exp_day, down_SR);
    disp([exp_day ' EMG_RecordTime: ' num2str(record_time) '[s]']);

    % generate(concatenate) ECoG & timing data.
    [CAI_struct, CLFP_struct, CRAW_struct, CTTL_struct] = concatenateData(base_dir, exp_day, monkeyname, down_SR, record_time);
    
    % save data
    saveRawData(base_dir, exp_day, monkeyname, CEMG_struct, CAI_struct, CRAW_struct, CLFP_struct, CTTL_struct);

    % clear only struct type
    vars = who;
    for var_id = 1:length(vars)
        if isstruct(eval(vars{var_id}))
            eval(['clear ' vars{var_id} ';']);
        end
    end
end
