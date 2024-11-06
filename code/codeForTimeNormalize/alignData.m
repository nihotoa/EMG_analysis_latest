function [alignedData, alignedDataAVE,AllT,Timing_ave, Timing_std, Timing_std_diff, TIME_W] = alignData(Data_in, Timing,trial_num,pre_per,post_per, EMG_num, monkeyname)
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
    case 'Hu'
        task_start_id = 1;
        task_end_id = 6;
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
        ref_start_timing = Timing(i,task_start_id);
        ref_end_timing = Timing(i,task_end_id);

        % Find the number of samples for each trial.
        time_w = round(ref_end_timing - ref_start_timing +1);
        pre_margin = time_w*per1;
        post_margin = time_w*per2;
        
        % エラー避けるための条件の作成.(切り出し範囲がData長の範囲外にならないようにここで弾く)
        condition1 = (ref_start_timing - pre_margin) < 0;
        condition2 = (ref_end_timing + post_margin) > size(Data, 2);
        if or(condition1, condition2)
            continue;
        end

        % Resampling from average frames of all task (time_w) to the frames of this task(time_W)
        if time_w == TIME_W
            trialData{i,1} = Data(j,floor(ref_start_timing-pre_margin):floor(ref_start_timing-1)); % pre trial data
            trialData{i,2} = Data(j,floor(ref_start_timing):floor(ref_end_timing)); % trial_data
            trialData{i,3} = Data(j,floor(ref_end_timing+1):floor(ref_end_timing+post_margin)); % post trial data
        
        elseif time_w<TIME_W 
            trialData{i,1} = interpft(Data(j,floor(ref_start_timing-pre_margin):floor(ref_start_timing-1)),pre1_TIME);
            trialData{i,2} = interpft(Data(j,floor(ref_start_timing):floor(ref_end_timing)),TIME_W);
            trialData{i,3} = interpft(Data(j,floor(ref_end_timing+1):floor(ref_end_timing+post_margin)),post2_TIME);
        
        else
            trialData{i,1} = resample(Data(j,floor(ref_start_timing-pre_margin):floor(ref_start_timing-1)),pre1_TIME,round(pre_margin));
            trialData{i,2} = resample(Data(j,floor(ref_start_timing):floor(ref_end_timing)),TIME_W,time_w);
            trialData{i,3} = resample(Data(j,floor(ref_end_timing+1):floor(ref_end_timing+post_margin)),post2_TIME,round(post_margin));
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
    alignedData{1, j} = DataA;
    validate_DataA = DataA(any(DataA, 2), :);
    alignedDataAVE{1,j} = mean(validate_DataA,1);
end

% Calculate the average number of samples elapsed from the 'lever1 on' (task_start_id) to each timing
[~, timing_num] = size(Timing);
Ti = [];
for ii = 1:timing_num
    Ti = [Ti Timing(:,task_start_id)];
end
offset_Timing = Timing - Ti;
 
Timing_ave = mean(offset_Timing);
Timing_std = std(offset_Timing);
Timing_std_diff = std(diff(offset_Timing, 1, 2));
end
