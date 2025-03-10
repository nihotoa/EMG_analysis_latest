%{
[Function Description]
This function aligns and normalizes EMG data across multiple trials.
It processes filtered EMG data by time-normalizing each trial to a common time scale,
adjusting for variations in trial duration, and adding pre/post-trial margins.
The function handles different monkey-specific timing structures and resamples
data to ensure consistent lengths across all trials.

[Input Arguments]
filtered_EMG_data: [double array] Filtered EMG data with dimensions [channels x samples]
timing_event_data: [double array] Timing event data with dimensions [trials x events]
trial_num: [integer] Number of trials
pre_task_percentage: [double] Percentage of trial duration to include before trial start
post_task_percentage: [double] Percentage of trial duration to include after trial end
EMG_num: [integer] Number of EMG channels
monkey_prefix: [char] Prefix identifying the monkey (e.g., 'Ni', 'Hu', 'Ya')

[Output Arguments]
time_normalized_EMG: [cell array] Time-normalized EMG data for each channel
time_normalized_EMG_average: [cell array] Average of time-normalized EMG data across trials
average_visualized_range_sample_num: [double] Total number of samples in normalized data
average_trial_sample_num: [double] Average number of samples per trial
%}
function [time_normalized_EMG, time_normalized_EMG_average, average_visualized_range_sample_num, average_trial_sample_num] = createTimeNormalizedTrialData(filtered_EMG_data, timing_event_data, trial_num, pre_task_percentage, post_task_percentage, EMG_num, monkey_prefix)
% Set task start and end IDs based on monkey type
switch monkey_prefix
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

% Please confirm this construction is correct.  
filtered_EMG_data = filtered_EMG_data';
pre_task_ratio = pre_task_percentage / 100;
post_task_ratio = post_task_percentage / 100;

% Calculate trial duration
each_trial_sample_num_list = timing_event_data(:,task_end_id) - timing_event_data(:,task_start_id) + 1;
average_trial_sample_num = round(mean(each_trial_sample_num_list));

pre_margin_sample_num = round(pre_task_ratio * average_trial_sample_num);
post_margin_sample_num = round(post_task_ratio * average_trial_sample_num);

% Calculate total time length
average_visualized_range_sample_num = pre_margin_sample_num + average_trial_sample_num + post_margin_sample_num; 

% Create empty arrays for output arguments
time_normalized_EMG = cell(1, EMG_num);
time_normalized_EMG_average = cell(1, EMG_num);

% Time Normalize
for EMG_id = 1:EMG_num
    ref_muscle_normalized_EMG_matrix = zeros(trial_num, average_visualized_range_sample_num);
    for trial_id = 1:trial_num
        ref_start_timing = timing_event_data(trial_id, task_start_id);
        ref_end_timing = timing_event_data(trial_id, task_end_id);

        % Find the number of samples for each trial
        ref_trial_sample_num = round(ref_end_timing - ref_start_timing + 1);
        pre_margin = ref_trial_sample_num * pre_task_ratio;
        post_margin = ref_trial_sample_num * post_task_ratio;
        
        % Create conditions to avoid errors (reject if cutout range exceeds data length)
        pre_start_idx = ref_start_timing - pre_margin;
        post_end_idx = ref_end_timing + post_margin;
        
        condition1 = (pre_start_idx < 0);
        condition2 = (post_end_idx > size(filtered_EMG_data, 2));
        if or(condition1, condition2)
            continue;
        end

        % Calculate indices
        pre_start = floor(ref_start_timing - pre_margin);
        pre_end = floor(ref_start_timing - 1);
        trial_start = floor(ref_start_timing);
        trial_end = floor(ref_end_timing);
        post_start = floor(ref_end_timing + 1);
        post_end = floor(ref_end_timing + post_margin);
        
        % Get data for current trial
        ref_trial_pre_margin_data = filtered_EMG_data(EMG_id, pre_start:pre_end);
        ref_trial_data = filtered_EMG_data(EMG_id, trial_start:trial_end);
        ref_trial_post_margin_data = filtered_EMG_data(EMG_id, post_start:post_end);

        % Resampling from average frames of all task (ref_trial_sample_num) to the frames of this task(time_W)
        if ref_trial_sample_num == average_trial_sample_num
            % If trial duration equals average, use as is
            pre_segment_data = ref_trial_pre_margin_data;
            trial_segment_data = ref_trial_data;
            post_segment_data = ref_trial_post_margin_data;
        
        elseif ref_trial_sample_num < average_trial_sample_num 
            % If trial is shorter than average, interpolate to expand
            pre_segment_data = interpft(ref_trial_pre_margin_data, pre_margin_sample_num);
            trial_segment_data = interpft(ref_trial_data, average_trial_sample_num);
            post_segment_data = interpft(ref_trial_post_margin_data, post_margin_sample_num);
        
        else
            % If trial is longer than average, downsample
            pre_segment_data = resample(ref_trial_pre_margin_data, pre_margin_sample_num, round(pre_margin));
            trial_segment_data = resample(ref_trial_data, average_trial_sample_num, ref_trial_sample_num);
            post_segment_data = resample(ref_trial_post_margin_data, post_margin_sample_num, round(post_margin));
        end
        
        % Concatenate pre_trial, trial, post_trial data
        combined_data = [pre_segment_data trial_segment_data post_segment_data];
        data_length = length(combined_data);

        % Resample if data length doesn't match expected length
        if data_length ~= average_visualized_range_sample_num
            combined_data = resample(combined_data, average_visualized_range_sample_num, data_length);
        end
        
        % Save normalized data
        ref_muscle_normalized_EMG_matrix(trial_id,:) = combined_data;
    end

    % Store each time-normalized EMG data
    time_normalized_EMG{1, EMG_id} = ref_muscle_normalized_EMG_matrix;
    
    % Extract and calculate average of valid data rows only
    validate_trial_indices = any(ref_muscle_normalized_EMG_matrix, 2);
    validate_EMG_matrix = ref_muscle_normalized_EMG_matrix(validate_trial_indices, :);
    time_normalized_EMG_average{1,EMG_id} = mean(validate_EMG_matrix, 1);
end
end
