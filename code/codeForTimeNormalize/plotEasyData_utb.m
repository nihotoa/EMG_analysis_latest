%{
[explanation of this func]:
this function is used in 'runnningEasyfunc.m'
Cut out EMG for each trial & Focusing on various timings and cut out EMG around them

[input arguments]:
monkeyname: prefix of data
xpdate_num: [double], date of experiment
save_fold: [char], 'easyData', you dont need to change
task:  [char], 'standard', you dont need to change
real_name: [char], full name of monkey

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

function [alignedDataAVE,alignedData,taskRange,AllT,Timing_ave,TIME_W,Res,D, focus_timing_num] = plotEasyData_utb(monkeyname, xpdate_num, save_fold, task ,real_name)
%% get informations(path of save_folder, EMG data, timing data ,etc...)
xpdate = sprintf('%d',xpdate_num);
disp(['START TO MAKE & SAVE ' monkeyname xpdate '_Plot Data']);

% get the path of save_fold
save_fold_path = fullfile(pwd, real_name, save_fold, [monkeyname xpdate '_' task]);

%load EasyData
EMG_data_struct = load(fullfile(save_fold_path, [monkeyname xpdate '_EasyData.mat'])); 

% get EMG data & timing data & SamplingRate 
EMGd = EMG_data_struct.AllData_EMG;
TimingT1 = EMG_data_struct.Tp;
SR = EMG_data_struct.SampleRate;

EMGs = EMG_data_struct.EMGs; % name list of EMG
EMG_num = length(EMGs);% the number of EMGs
TimingT1 = TimingT1(1:end-1,:);
[trial_num, ~] = size(TimingT1);  % number of success trial 

%% filter EMG
filt_mode = 3;% the method of filter(1: Takei method, 2: Roland method, 3: Uchida method)
[filtData_EMG,Timing_EMG,filtP] = filterEMG(EMGd,filt_mode,SR,EMG_num,TimingT1);

%% Cut out EMG data for each trial(& perform time normalization(Normalize from 'lever1 on' to 'lever1 off' as 100%))

%define time window
pre_per = 50; % How long do you want to see the signals before 'lever1 on' starts.
post_per = 50; % How long do you want to see the signals after 'lever2 off' starts.

% Trim EMG data for each trial & perform time normalization for each trial
[alignedData, alignedDataAVE,AllT,Timing_ave,TIME_W] = alignData(filtData_EMG, Timing_EMG,trial_num,pre_per,post_per, EMG_num, monkeyname);

% Setting the range to be cut out around each timing
taskRange = [-1*pre_per, 100+post_per];
D = struct();

% change the range of trimming for each monkey
switch monkeyname
    case 'Nibali'
        D.trig1_per = [50 50];
        D.trig2_per = [50 50];
        D.trig3_per = [50 50];
        D.trig4_per = [50 50];
        D.task_per = [25,105];
    otherwise
        D.trig1_per = [50 50];
        D.trig2_per = [50 50];
        D.trig3_per = [50 50];
        D.trig4_per = [50 50];
        D.task_per = [25,105];
end

% Centering on each timing, trim & get EMG data around it
[Res, focus_timing_num] = alignDataEX(alignedData,Timing_EMG, D,pre_per,TIME_W,EMG_num, monkeyname);

% Summary of trimming details(length of trimmed data, cut out range around each timing)
for timing_id = 1:focus_timing_num
    D.(['Ld' num2str(timing_id)]) = length(Res.(['tData' num2str(timing_id) '_AVE']){1});
    D.(['Range' num2str(timing_id)]) = D.(['trig' num2str(timing_id) '_per']);
end
D.RangeTask = D.task_per;
D.filtP = filtP;

% save data
save(fullfile(save_fold_path, [monkeyname xpdate '_alignedData_' filtP.whose '.mat']), 'monkeyname', 'xpdate','EMGs', ...
                                          'alignedData', 'alignedDataAVE','filtP','trial_num','taskRange','Timing_ave'...
                                                  );
disp(['END TO MAKE & SAVE ' monkeyname xpdate '_Plot Data']);
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

% --------------------------------------------------------------------------------------------------------------------------------------------

function [alignedData, alignedDataAVE,AllT,Timing_ave,TIME_W] = alignData(Data_in, Timing,trial_num,pre_per,post_per, EMG_num, monkeyname)
%{
[In case of Yachimun]
this function estimate that Timing is constructed by 6 kinds of timing.
1:start trial
2:lever1 on 
3:lever1 off
4:lever2 on
5:lever2 off
6:success

[In case of Nibali]
this function estimate that Timing is constructed by 5 kinds of timing.
1: start trial
2: grasp on 
3: grasp off
4. end trial
5: success
%}

% Tie id and timing of attention to each monkey
switch monkeyname
    case 'Ni'
        task_start_id = 1;
        task_end_id = 4;
    otherwise
        task_start_id = 2;
        task_end_id = 5;
end

%Please comfirm this construction is correct.  
Data = Data_in';
per1 = pre_per / 100;
per2 = post_per / 100;

TIME_W = round(sum(Timing(:,task_end_id)-Timing(:,task_start_id) + 1)/trial_num); % Find mean number of sample in 1 trial
pre1_TIME = round(per1*sum(Timing(:,task_end_id)-Timing(:,task_start_id) + 1)/trial_num); % Mean number of samples in pre direction
post2_TIME = round(per2*sum(Timing(:,task_end_id)-Timing(:,task_start_id) + 1)/trial_num);
trialData = cell(trial_num,3); %3 means range of each section(pre-trial, trial, post-trial)
AllT = pre1_TIME+TIME_W+post2_TIME; % Average number of samples in the range to be trimmed ((pre_per + 100 + post_per)%)

% Create an empty array for the output argument
outData = cell(trial_num,EMG_num);
alignedData = cell(1,EMG_num);
alignedDataAVE = cell(1,EMG_num);

% Time Normalize
for j = 1:EMG_num
    DataA = zeros(trial_num,AllT);
    for i = 1:trial_num
        % Find the number of samples for each trial.
        time_w = round(Timing(i,task_end_id) - Timing(i,task_start_id) +1);

        % Resampling from average frames of all task (time_w) to the frames of this task(time_W)
        if time_w == TIME_W
            trialData{i,1} = Data(j,floor(Timing(i,task_start_id)-time_w*per1):floor(Timing(i,task_start_id)-1)); % pre trial data
            trialData{i,2} = Data(j,floor(Timing(i,task_start_id)):floor(Timing(i,task_end_id))); % trial_data
            trialData{i,3} = Data(j,floor(Timing(i,task_end_id)+1):floor(Timing(i,task_end_id)+time_w*per2)); % post trial data
        
        elseif time_w<TIME_W 
            trialData{i,1} = interpft(Data(j,floor(Timing(i,task_start_id)-time_w*per1):floor(Timing(i,task_start_id)-1)),pre1_TIME);
            trialData{i,2} = interpft(Data(j,floor(Timing(i,task_start_id)):floor(Timing(i,task_end_id))),TIME_W);
            trialData{i,3} = interpft(Data(j,floor(Timing(i,task_end_id)+1):floor(Timing(i,task_end_id)+time_w*per2)),post2_TIME);
        
        else
            trialData{i,1} = resample(Data(j,floor(Timing(i,task_start_id)-time_w*per1):floor(Timing(i,task_start_id)-1)),pre1_TIME,round(time_w*per1));
            trialData{i,2} = resample(Data(j,floor(Timing(i,task_start_id)):floor(Timing(i,task_end_id))),TIME_W,time_w);
            trialData{i,3} = resample(Data(j,floor(Timing(i,task_end_id)+1):floor(Timing(i,task_end_id)+time_w*per2)),post2_TIME,round(time_w*per2));
        end
        
        % Concatenate pre_trial, trial, post_trial data and save in list
        outData{i,j} = [trialData{i,1} trialData{i,2} trialData{i,3}];
        size_out = size(outData{i,j});

        % Check if the data after concatenation matches AllT(Prevent data length from varying depending on trial)
        if size_out(2) == AllT
            DataA(i,:) = outData{i,j}(1,:);
        else
            DataA(i,:) = resample(outData{i,j}(1,:),AllT,size_out(2));
            outData{i,j} = resample(outData{i,j}(1,:),AllT,size_out(2));
        end
    end 

    % Store each time-normalized EMG data
    alignedData{1,j} = DataA;
    alignedDataAVE{1,j} = mean(DataA,1);
end

% Calculate the average number of samples elapsed from the 'lever1 on' (task_start_id) to each timing
[~, timing_num] = size(Timing);
Ti = [];
for ii = 1:timing_num
    Ti = [Ti Timing(:,task_start_id)];
end
Timing_ave = mean(Timing - Ti);
end

%------------------------------------------------------------------------------
function [Re, focus_timing_num] = alignDataEX(Data_in,Timing,range_struct,pre_per,TIME_W,EMG_num, monkeyname)
%{
[In case of Yachimun]
this function estimate that Timing is constructed by 6 kinds of timing.
1:start trial
2:lever1 on 
3:lever1 off
4:lever2 on
5:lever2 off
6:success

[In case of Nibali]
this function estimate that Timing is constructed by 5 kinds of timing.
1: start trial
2: grasp on 
3: grasp off
4. end trial
5: success
%}

% Tie id and timing of attention to each monkey
switch monkeyname
    case 'Ni'
        task_start_id = 1;
        task_end_id = 4;
    otherwise
        task_start_id = 2;
        task_end_id = 5;
end
% count the number of timing which is focused on analysis
focus_timing_num = (task_end_id - task_start_id)+1;

% Acquisition of EMG data and fieldnames of range_struct
D = Data_in;
fieldname_list = fieldnames(range_struct);

% Formatting timing data
[trial_num, timing_num] = size(Timing);
Ti = [];
for ii = 1:timing_num
    Ti = [Ti Timing(:,task_start_id)];
end
Timing = Timing - Ti;

% Creating an empty array to store data & Creating a structure for output arguments
per_struct = struct();
center_struct = struct();
Re = struct();
Re_sel = struct();
TimingPer = zeros(trial_num, timing_num);

per_struct.pre_per = pre_per/100;
for timing_id = 1:focus_timing_num
    % prepare empty array
    center_struct.(['centerP' num2str(timing_id)]) = zeros(trial_num,2);
    Re.(['tData' num2str(timing_id)]) = cell(1,EMG_num);
    Re.(['tData' num2str(timing_id) '_AVE']) = cell(1,EMG_num);
    Re_sel.(['tD' num2str(timing_id)]) = cell(trial_num, 1);

    % change from percentage to ratio
    per_struct.(['per' num2str(timing_id)]) = range_struct.(fieldname_list{timing_id}) / 100;
end
center_struct.centerPTask = zeros(trial_num,2);
Re.tDataTask = cell(1,EMG_num);
Re.tDataTask_AVE = cell(1,EMG_num);
per_struct.pertask = range_struct.task_per/100;
Re_sel.tDTask = cell(trial_num,1);

for muscle_id = 1:EMG_num
    for trial_id = 1:trial_num
        % Time elapsed from 'lever1 on' to each timing, assuming time elapsed from 'lever1 on' to 'lever2 off' as 1
        TimingPer(trial_id,:) = Timing(trial_id,:)./Timing(trial_id, task_end_id);
        
        ref_struct = struct();
        for timing_id = 1:focus_timing_num
            % Find the reference point for each timing (note that pre_per + TimingPer(trial_id,j) is the center of timing j in trial trial_id)
            ref_timing_id = (task_start_id + timing_id) - 1;
            ref_struct.(['ref_P' num2str(timing_id)]) = per_struct.pre_per + TimingPer(trial_id, ref_timing_id);

            % Setting the cropping range around each timing(P1(timing1) ~ P4(timing4))
            center_struct.(['centerP' num2str(timing_id)])(trial_id, :) = [round((ref_struct.(['ref_P' num2str(timing_id)]) - per_struct.(['per' num2str(timing_id)])(1)) * TIME_W + 1), floor((ref_struct.(['ref_P' num2str(timing_id)]) + per_struct.(['per' num2str(timing_id)])(2)) * TIME_W - 1)]; % Centered around 'timing_id' timing

            % Cut out EMG according to the set range
            Re_sel.(['tD' num2str(timing_id)]){trial_id,1} = D{1,muscle_id}(trial_id, center_struct.(['centerP' num2str(timing_id)])(trial_id,1): center_struct.(['centerP' num2str(timing_id)])(trial_id,2));
        end
        center_struct.centerPTask(trial_id, :) = [round((ref_struct.ref_P1 - per_struct.pertask(1)) * TIME_W + 1), floor((ref_struct.ref_P1 + per_struct.pertask(2)) * TIME_W - 1)]; % Centered around 'task_start_id' timing
        Re_sel.tDTask{trial_id,1} = D{1, muscle_id}(trial_id, center_struct.centerPTask(trial_id, 1):center_struct.centerPTask(trial_id, 2));
    end

    for timing_id = 1:focus_timing_num
        data_name = ['tD' num2str(timing_id)];
        per_data = per_struct.(['per' num2str(timing_id)]);

        % align length between each trial
        [Re_sel.(data_name)]=AlignDatasets(Re_sel.(data_name), round(TIME_W*sum(per_data)));

        % store TimeNormalized data
        Re.(['tData' num2str(timing_id)]){muscle_id} = cell2mat(Re_sel.(data_name));
        
        % store average data of all trials
        Re.(['tData' num2str(timing_id) '_AVE']){muscle_id} = mean(Re.(['tData' num2str(timing_id)]){muscle_id});
    end
    [Re_sel.tDTask]=AlignDatasets(Re_sel.tDTask,round(TIME_W*sum(per_struct.pertask)));
    Re.tDataTask{muscle_id} = cell2mat(Re_sel.tDTask);
    Re.tDataTask_AVE{muscle_id} = mean(Re.tDataTask{muscle_id});
end

end