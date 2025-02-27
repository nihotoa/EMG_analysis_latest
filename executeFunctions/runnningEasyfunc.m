%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{

[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code & select data by following guidance (which is displayed in command window after Running this code)

[role of this code]
the role of this code is to perform various processing(trimming for each task-trials, filtering, etc...) to raw EMG data
& save these data

[Saved data location]
1.
location: data/Yachimun/easyData/~_standard/
file_name: ~_EasyData.mat:  timing data & EMGdata (muscle_name: 'EMGs', EMG: 'AllData_EMG', taiming_data: 'Tp')
                 ~_CTcheckData.mat:  about the data of cross-talk of EMG
                 ~_CTR.mat:  about the data of cross-talk of EMG
                 ~_alignedData_uchida: 

2.
location: data/Yachimun/easyData/P-DATA/
file_name: ~_Pdata.mat:  contains some data for synergy analysis (timing_data, trimmed_EMG, etc...)
                 ~_PdataTrigEMG.mat:  (not used in any process)
                 ~_PdataTrigEMG_NDfilt.mat:  (not used in any process)
                 ~_PdataTrigSyn.mat:  (not used in any process)

[procedure]
pre: extractAndSaveLinkageInfo.m
post: 
        if you want to peform... 
        => EMG analysis: plotTarget.m 
        => Synergy analysis: SYNERGYPLOT.m
        => Assesment of error between trials: ConfirmError.m
        => Assesment of quality of EMG signal: PerformFFT.m


(If you want to get the information shown below, you can get it by executing following function)
�Eif you want to visually confirm the difference of filtered EMG which is caused by the difference of filtering
    => PerformFFT.m
�EIf you want to confirm the effect of time normalization on activity pattern
    => ConfirmError.m

[caution!!]
Sometimes the function 'uigetfile' is not executed and an error occurs
-> please reboot MATLAB

[Improvement points(Japanaese)]
�E����Ȃ����̏���������
�EmakeEasyData_all��Tp�����Ƃ���ŁACTTL_002��Up��Down�̃T�C�Y�������ĂȂ��ăG���[�f�����Ƃ�����̂ŁA�Ώ�����(20250219������ɑΉ�)
�E���s�v�l�̒�`���l���Ď�������
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear 
%% set param
% which monkey?
monkeyname = 'Hu';  % 'Ya', 'F'
mE = struct();
mE.downdata_to = 1375; % (if down_E ==1)sampling rate of after resampling
mE.time_restriction_flag = false; % true/false
mE.time_restriction_threshold = 3;  %[s]

% set param for 'makeEasyData_all'

mE.make_EMG = 1; % whether you want to make EMG data
mE.save_E = 1; % wheter you want to save EMG data
mE.down_E = 1; % whether you want to perform down sampling
mE.make_Timing = 1; % whether you want to make timing data

% which save pttern?(if you set all of them to 1, there is basically no problem.)
saveP = 1; 
saveE = 0;  
saveS = 0; 
saveE_filt = 0; 

%% code section
% get target files(select standard.mat files which contain file information, e.g. file numbers)
realname = get_real_name(monkeyname);
root_dir = fileparts(pwd);
linkageInfo_fold_path = fullfile(root_dir, 'saveFold', realname, 'data', 'EMG_ECoG', 'linkageInfo_list');
disp(['�yPlease select all "~_linkageInfo.mat" of all dates you want to analyze�z'])
Allfiles_S = uigetfile('*.mat', 'Select One or More Files', 'MultiSelect', 'on', linkageInfo_fold_path);

if isequal(Allfiles_S, 0)
    disp('user press canceled')
    return
end

%change 'char' to 'cell'
if ischar(Allfiles_S)
    Allfiles_S={Allfiles_S};
end
    
day_num = length(Allfiles_S);
Allfiles = strrep(Allfiles_S, '_linkageInfo.mat','');
%% RUNNING FUNC LIST (make data)
common_save_fold_path = fullfile(root_dir, 'saveFold', realname, 'data', 'EMG_ECoG');
for day_id = 1:day_num
    load(fullfile(linkageInfo_fold_path, Allfiles_S{day_id}), 'linkageInfo');
    xpdate = linkageInfo.xpdate;
    file_num = linkageInfo.file_num;
    
    % Perform all preprocessing with 3 functions
    % 1. Perform data concatenation & filtering processing & Obtain information on each timing for EMG trial-by-trial extraction
    [EMGs,Tp,Tp3] = makeEasyData_all(monkeyname, realname, xpdate, file_num, common_save_fold_path, mE); 

    % 2. Check for cross-talk between measured EMGs
    [Yave,Y3ave] = CTcheck(monkeyname, xpdate, common_save_fold_path, realname);

    % 3. Cut out EMG for each trial & Focusing on various timings and cut out EMG around them
    [alignedDataAVE,alignedData_all,taskRange,AllT,Timing_ave,TIME_W,Res,D, focus_timing_num] = plotEasyData_utb(monkeyname, xpdate, common_save_fold_path);
    
    % create struct(Store the EMG trial average data around each timing in another structure)
    ResAVE = struct();
    for timing_id = 1:focus_timing_num
        ResAVE.(['tData' num2str(timing_id) '_AVE']) = Res.(['tData' num2str(timing_id) '_AVE']);
        alignedData_trial.(['tData' num2str(timing_id)]) = Res.(['tData' num2str(timing_id)]);
    end
    ResAVE.tDataTask_AVE = Res.tDataTask_AVE;
    alignedData_trial.tDataTask = Res.tDataTask;
    
    %% save data(location: easyData/P-Data)
    % get folder path & make folder
    P_Data_fold_path = fullfile(common_save_fold_path, 'P-DATA');
    makefold(P_Data_fold_path);
    % save data as .mat file
    if saveP == 1
        % dataset for synergy analysis 
        save(fullfile(P_Data_fold_path, [monkeyname sprintf('%d',xpdate) '_Pdata.mat']), 'monkeyname', 'xpdate', 'file_num','EMGs',...
                                               'Tp','Tp3',... 
                                               'Yave','Y3ave',...
                                               'alignedDataAVE','taskRange','AllT','Timing_ave','TIME_W','ResAVE','D'...,
                                               );
    end
    if saveE == 1
        %dataset for synergy analysis after'trig data' filtered by TakeiMethod same as his paper
        save(fullfile(P_Data_fold_path, [monkeyname sprintf('%d',xpdate) '_dataTrigEMG.mat']), ...
                                               'alignedData_trial','alignedData_all',...
                                               'D'...
                                               );
    end
    if saveE_filt == 1
        %dataset for synergy analysis after'trig data' filtered by Uchida same as his paper
        save(fullfile(P_Data_fold_path, [monkeyname sprintf('%d',xpdate) '_dataTrigEMG_NDfilt.mat']), ...
                                               'alignedData_trial','alignedData_all',...
                                               'D'...
                                               );
    end
    if saveS == 1
        %dataset for synergy analysis after'trig data' filtered by TakeiMethod same as his paper
        save(fullfile(P_Data_fold_path, [monkeyname sprintf('%d',xpdate) '_dataTrigSyn.mat']), ...
                                               'alignedData_trial','D'...
                                               );
    end
end