function [Re, focus_timing_num, Timing_ave_ratio] = alignDataEx(Data_in,Timing,range_struct,pre_per,TIME_W,EMG_num, monkeyname)
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

[In case of Hugo]
this function estimate that Timing is constructed by 5 kinds of timing.
1: start trial
2: drawer on 
3: drawer off
4: food on 
5: food off
6. end trial
7: success
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
% count the number of timing which is focused on analysis
focus_timing_num = (task_end_id - task_start_id)+1;

% Acquisition of EMG data and fieldnames of range_struct
aligned_data = Data_in;
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
            Re_sel.(['tD' num2str(timing_id)]){trial_id,1} = aligned_data{1,muscle_id}(trial_id, center_struct.(['centerP' num2str(timing_id)])(trial_id,1): center_struct.(['centerP' num2str(timing_id)])(trial_id,2));
        end
        center_struct.centerPTask(trial_id, :) = [round((ref_struct.ref_P1 - per_struct.pertask(1)) * TIME_W + 1), floor((ref_struct.ref_P1 + per_struct.pertask(2)) * TIME_W - 1)]; % Centered around 'task_start_id' timing
        Re_sel.tDTask{trial_id,1} = aligned_data{1, muscle_id}(trial_id, center_struct.centerPTask(trial_id, 1):center_struct.centerPTask(trial_id, 2));
    end

    for timing_id = 1:focus_timing_num
        data_name = ['tD' num2str(timing_id)];
        per_data = per_struct.(['per' num2str(timing_id)]);

        % align length between each trial
        [Re_sel.(data_name)]=AlignDatasets(Re_sel.(data_name), round(TIME_W*sum(per_data)));

        % store TimeNormalized data
        Re.(['tData' num2str(timing_id)]){muscle_id} = cell2mat(Re_sel.(data_name));
        
        ref_tData = Re.(['tData' num2str(timing_id)]){muscle_id};
        validate_ref_tData = ref_tData(any(ref_tData, 2), :);
        % store average data of all trials
        Re.(['tData' num2str(timing_id) '_AVE']){muscle_id} = mean(validate_ref_tData);
    end
    [Re_sel.tDTask]=AlignDatasets(Re_sel.tDTask,round(TIME_W*sum(per_struct.pertask)));
    Re.tDataTask{muscle_id} = cell2mat(Re_sel.tDTask);
    Re.tDataTask_AVE{muscle_id} = mean(Re.tDataTask{muscle_id});
end
Timing_ave_ratio = mean(TimingPer);
end