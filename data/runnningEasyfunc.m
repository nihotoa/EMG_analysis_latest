%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
coded by Naoki Uchida
modified by Naohito Ota

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
pre: SaveFileInfo.m
post: 
        if you want to peform... 
        => EMG analysis: plotTarget.m 
        => Synergy analysis: SYNERGYPLOT.m
        => Assesment of error between trials: ConfirmError.m
        => Assesment of quality of EMG signal: PerformFFT.m


(If you want to get the information shown below, you can get it by executing following function)
・if you want to visually confirm the difference of filtered EMG which is caused by the difference of filtering
    => PerformFFT.m
・If you want to confirm the effect of time normalization on activity pattern
    => ConfirmError.m

[caution!!]
Sometimes the function 'uigetfile' is not executed and an error occurs
-> please reboot MATLAB

[Improvement points(Japanaese)]
makeEasyData_all/makeEasyTiming内のSu, Seの条件分岐の意味を把握していない => Sesekiで試す or チュートリアル用のリポジトリを作った後に消す
・この関数の中で使われている関数の中で使われているplotEasyData_utbとMakeDataForPlot_H_utb.mが激似なので関数ファイルを作って外から呼び出すように変更する
try catchのせいで、エラーが起きてもエラー文章が表示されずに実行が進んでしまうので、廃止する or エラーが起きていることをログとして出す。
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear 
%% set param
% which monkey?
realname = 'Yachimun';  % 'Yachimun', 'SesekiL', 'Nibali' , 'Hugo'
task = 'standard'; % you don't need to change
save_fold = 'easyData'; % you don't need to change

% set param for 'makeEasyData_all'
mE = struct();
mE.make_EMG = 1; % whether you want to make EMG data
mE.save_E = 1; % wheter you want to save EMG data
mE.down_E = 1; % whether you want to perform down sampling
mE.make_Timing = 1; % whether you want to make timing data
mE.downdata_to = 1375; % (if down_E ==1)sampling rate of after resampling

% which save pttern?(if you set all of them to 1, there is basically no problem.)
saveP = 1; 
saveE = 0;  
saveS = 0; 
saveE_filt = 0; 

%% code section
% get target files(select standard.mat files which contain file information, e.g. file numbers)

easyData_fold_path = fullfile(pwd, realname, 'easyData');
disp(['【Please select files(select all ~_standard.mat of all dates you want to analyze (files path: ' realname ' /easyData/)】'])
[Allfiles_S,path] = uigetfile('*.mat', 'Select One or More Files', 'MultiSelect', 'on', easyData_fold_path);

if isequal(Allfiles_S, 0)
    disp('user press canceled')
    return
end

%change 'char' to 'cell'
if ischar(Allfiles_S)
    Allfiles_S={Allfiles_S};
end
    
[~, session_num] = size(Allfiles_S);
Allfiles = strrep(Allfiles_S,['_' task '.mat'],'');
%% RUNNING FUNC LIST (make data)
for i = 1:session_num
    load(fullfile(easyData_fold_path, Allfiles_S{i}), 'fileInfo');
    monkeyname = fileInfo.monkeyname;
    xpdate = fileInfo.xpdate;
    file_num = fileInfo.file_num;
    
    % Perform all preprocessing with 3 functions
    
    try 
    % 1. Perform data concatenation & filtering processing & Obtain information on each timing for EMG trial-by-trial extraction
    [EMGs,Tp,Tp3] = makeEasyData_all(monkeyname, realname, xpdate, file_num, save_fold, mE, task); 
    catch
        continue
    end

    % 2. Check for cross-talk between measured EMGs
    [Yave,Y3ave] = CTcheck(monkeyname, xpdate, save_fold, 1, task, realname);

    % 3. Cut out EMG for each trial & Focusing on various timings and cut out EMG around them
    [alignedDataAVE,alignedData_all,taskRange,AllT,Timing_ave,TIME_W,Res,D, focus_timing_num] = plotEasyData_utb(monkeyname, xpdate, save_fold, task, realname);
    
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
    P_Data_fold_path = fullfile(easyData_fold_path, 'P-DATA');
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