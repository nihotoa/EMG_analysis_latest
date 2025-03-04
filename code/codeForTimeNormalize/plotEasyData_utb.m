%{
[explanation of this func]:
this function is used in 'prepareEMGAndTimingData.m'
Cut out EMG for each trial & Focusing on various timings and cut out EMG around them

[input arguments]:
monkey_prefix: prefix of data
xpdate_num: [double], date of experiment
save_fold: [char], 'easyData', you dont need to change

[output arguments]:
alignedDataAVE: [cell array], each cell contains the average activity of all trials of that EMG
alignedData: [cell array], each cell contains the cut-out EMG of all trials in that EMG
taskRange: [double array],  range of cutout (ex.) [-50 150]
AllT : [double], average sample size of cropped range
Timing_ave: [double array(vector)], average number of samples it takes from 'lever1 on' to each timing
TIME_W: [double], average sample size of trial
Res: [struct], this contains EMG data cenreted on each timing
D: [struct], this contains information about cutout range centered on each timing.

[Improvement points(Japanese)]
pwdじゃなくて,  inputにbase_dir指定してそれを使った方がいいかも
%}

function [alignedDataAVE,alignedData,taskRange,AllT,Timing_ave,TIME_W,Res,D, focus_timing_num] = plotEasyData_utb(monkey_prefix, xpdate_num, save_fold)
%% get informations(path of save_folder, EMG data, timing data ,etc...)
xpdate = sprintf('%d',xpdate_num);
disp(['START TO MAKE & SAVE ' monkey_prefix xpdate '_Plot Data']);

% get the path of save_fold
%load EasyData
EMG_data_struct = load(fullfile(save_fold, 'cutout_EMG_data_list', [monkey_prefix xpdate '_cutout_EMG_data.mat'])); 

% get EMG data & timing data & SamplingRate 
EMGd = EMG_data_struct.AllData_EMG;
TimingT1 = EMG_data_struct.Tp;
SR = EMG_data_struct.SampleRate;

EMGs = EMG_data_struct.EMGs; % name list of EMG
EMG_num = length(EMGs);% the number of EMGs
TimingT1 = TimingT1(1:end,:);
[trial_num, ~] = size(TimingT1);  % number of success trial 

%% filter EMG
filt_mode = 3;% the method of filter(1: Takei method, 2: Roland method, 3: Uchida method)
[filtData_EMG,Timing_EMG,filtP] = filterEMG(EMGd,filt_mode,SR,EMG_num,TimingT1);

%% Cut out EMG data for each trial(& perform time normalization(Normalize from 'lever1 on' to 'lever1 off' as 100%))

%define time window
pre_per = 50; % How long do you want to see the signals before 'lever1 on' starts.
post_per = 50; % How long do you want to see the signals after 'lever2 off' starts.

% Trim EMG data for each trial & perform time normalization for each trial
[alignedData, alignedDataAVE, AllT, Timing_ave, Timing_std, Timing_std_diff,TIME_W] = alignData(filtData_EMG, Timing_EMG,trial_num,pre_per,post_per, EMG_num, monkey_prefix);

% Setting the range to be cut out around each timing
taskRange = [-1*pre_per, 100+post_per];
D = struct();

% change the range of trimming for each monkey
switch monkey_prefix
    case 'Ni'
        D.trig1_per = [50 50];
        D.trig2_per = [50 50];
        D.trig3_per = [50 50];
        D.trig4_per = [50 50];
        D.task_per = [25,105];
    case 'Hu'
        D.trig1_per = [50 50];
        D.trig2_per = [50 50];
        D.trig3_per = [50 50];
        D.trig4_per = [50 50];
        D.trig5_per = [50 50];
        D.trig6_per = [50 50];
        D.task_per = [25,105];
    otherwise
        D.trig1_per = [50 50];
        D.trig2_per = [50 50];
        D.trig3_per = [50 50];
        D.trig4_per = [50 50];
        D.task_per = [25,105];
end

% Centering on each timing, trim & get EMG data around it
[Res, focus_timing_num, Timing_ave_ratio] = alignDataEx(alignedData,Timing_EMG, D,pre_per,TIME_W,EMG_num, monkey_prefix);

% Summary of trimming details(length of trimmed data, cut out range around each timing)
for timing_id = 1:focus_timing_num
    D.(['Ld' num2str(timing_id)]) = length(Res.(['tData' num2str(timing_id) '_AVE']){1});
    D.(['Range' num2str(timing_id)]) = D.(['trig' num2str(timing_id) '_per']);
end
D.RangeTask = D.task_per;
D.filtP = filtP;
down_Hz = filtP.down;

save_fold_path = fullfile(save_fold, 'alignedData_list');
makefold(save_fold_path);
% save data
save(fullfile(save_fold_path, [monkey_prefix xpdate '_alignedData_' filtP.whose '.mat']), 'monkey_prefix', 'xpdate','EMGs', ...
                                          'alignedData', 'alignedDataAVE','filtP','trial_num','taskRange', 'down_Hz', 'TIME_W', 'Timing_ave', 'Timing_std', 'Timing_std_diff','Timing_ave_ratio');


disp(['END TO MAKE & SAVE ' monkey_prefix xpdate '_Plot Data']);
end


%% define local function

function [filtData,newTiming,filtP] = filterEMG(filtData,filt_mode,SR,EMG_num,Timing)
%{
explanation of output arguments:
filtData: EMG data after filtering
newTiming: Timing data for filtered EMG (supports downsampling)
filtP: A structure containing content about the filter contents, such as the cutoff frequency of a high-pass filter
%}

switch filt_mode
    case 1 %Takei filter
        filt_h = 50; %cut off frequency [Hz]
        filt_l = 20; %cut off frequency [Hz]
        np = 100;%smooth num
        kernel = ones(np,1)/np; 
        downdata_to = 100; %sampling frequency [Hz]
        
        for i = 1:EMG_num
            filtData(:,i) = filtData(:,i)-mean(filtData(:,i));
        end
        
        [B,A] = butter(6, (filt_h .* 2) ./ SR, 'high');
        for i = 1:EMG_num
            filtData(:,i) = filter(B,A,filtData(:,i));
        end

        filtData = abs(filtData);

        [B,A] = butter(6, (filt_l .* 2) ./ SR, 'low');
        for i = 1:EMG_num
            filtData(:,i) = filter(B,A,filtData(:,i));
        end

        for i = 1:EMG_num
            filtData(:,i) = conv2(filtData(:,i),kernel,'same');
        end

        filtData = resample(filtData,downdata_to,SR);
        newSR = downdata_to;
        newTiming = Timing*newSR/SR;
        filtP = struct('whose','TTakei','Hp',filt_h, 'Rect','on','Lp',filt_l,'smooth',np,'down',downdata_to);
    case 2 %Roland filter
        np = round(5000*0.22);%smooth num
        kernel = ones(np,1)/np; 
        downdata_to = 1000; %sampling frequency [Hz]

        for i=1:EMG_num
            filtData(:,i) = abs(filtData(:,i)-mean(filtData(:,i)));
        end

        for i = 1:EMG_num
            filtData(:,i) = conv2(filtData(:,i),kernel,'same');
        end

        filtData = resample(filtData,downdata_to,SR);
        newSR = downdata_to;
        newTiming = Timing*newSR/SR;
        filtP = struct('whose','Roland','Hp','no', 'Rect','on','Lp','no','smooth',np,'down',downdata_to);
   case 3 %Uchida filtfilt
        filt_h = 50; %cut off frequency [Hz]
        filt_l = 20; %cut off frequency [Hz]
        downdata_to = 100; %sampling frequency [Hz]
        
        % offset
        for i = 1:EMG_num
            filtData(:,i) = filtData(:,i)-mean(filtData(:,i));
        end

        %high-pass filter
        [B,A] = butter(6, (filt_h .* 2) ./ SR, 'high');
 
        for i = 1:EMG_num
            filtData(:,i) = filtfilt(B,A,filtData(:,i));
        end
        
        %rect
        filtData = abs(filtData);

        % low-pass filter
        [B,A] = butter(6, (filt_l .* 2) ./ SR, 'low');
        for i = 1:EMG_num
            filtData(:,i) = filtfilt(B,A,filtData(:,i));
        end

        %down sampling
        filtData = resample(filtData,downdata_to,SR);
        newSR = downdata_to;
        newTiming = Timing*newSR/SR;
        filtP = struct('whose','Uchida','Hp',filt_h, 'Rect','on','Lp',filt_l,'down',downdata_to);
end
end
