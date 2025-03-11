%{
[Function Description]
This function extracts EMG data segments centered around specific timing events.
It processes time-normalized EMG data to create segments focused on key events
in the trial, such as lever pulls, grasps, or drawer operations. The function
handles different monkey-specific timing structures and creates standardized
data segments for each timing event.

[Input Arguments]
time_normalized_EMG: [cell array] Time-normalized EMG data from createTimeNormalizedTrialData function
resampled_timing_data: [double array] Resampled timing event data
cutout_range_struct: [struct] Contains cutout range information for each timing event
pre_task_percentage: [double] Percentage of trial duration included before trial start
average_trial_sample_num: [double] Average number of samples per trial
EMG_num: [integer] Number of EMG channels
monkey_prefix: [char] Prefix identifying the monkey (e.g., 'Ni', 'Hu', 'Ya')

[Output Arguments]
each_timing_cutout_EMG_struct: [struct] EMG data segments centered on each timing event
focus_timing_num: [integer] Number of timing events being analyzed

[Timing Data Structure for Each Monkey]

[Yachimun]
6 types of timing events:
1: Trial start
2: Lever 1 on
3: Lever 1 off
4: Lever 2 on
5: Lever 2 off
6: Trial end

[Nibali]
5 types of timing events:
1: Trial start
2: Grasp on
3: Grasp off
4: Trial end
5: Success

[Hugo]
7 types of timing events:
1: Trial start
2: Drawer on
3: Drawer off
4: Food on
5: Food off
6: Trial end
7: Success
%}
function [each_timing_cutout_EMG_struct, focus_timing_num] = extractEventCenteredSegments(time_normalized_EMG, resampled_timing_data, cutout_range_struct, pre_task_percentage, average_trial_sample_num, EMG_num, monkey_prefix)
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

% Calculate the number of timing events to focus on
focus_timing_num = (task_end_id - task_start_id) + 1;

% Format timing data - Convert to relative time from task start
[trial_num, timing_num] = size(resampled_timing_data);
trial_start_timing = resampled_timing_data(:, task_start_id);
resampled_timing_data = resampled_timing_data - repmat(trial_start_timing, 1, timing_num);

% Initialize structures
cutout_range_ratio_struct = struct();
center_offset_timing_struct = struct();
each_timing_cutout_EMG_struct = struct();
temp_EMG_data = struct();
timing_percentage = zeros(trial_num, timing_num);

% Convert percentages to ratios
cutout_range_ratio_struct.pre_task_percentage = pre_task_percentage / 100;
cutout_range_ratio_struct.whole_trial = cutout_range_struct.whole_trial_percentage / 100;

% Get field names list
timing_name_list = fieldnames(cutout_range_struct);

% Initialize structure fields for each timing event and whole trial
for timing_id = 1:focus_timing_num
    timing_name = ['timing' num2str(timing_id)];
    
    % Initialize structure fields
    center_offset_timing_struct.(timing_name) = zeros(trial_num, 2);
    each_timing_cutout_EMG_struct.(timing_name) = cell(1, EMG_num);
    each_timing_cutout_EMG_struct.([timing_name '_average']) = cell(1, EMG_num);
    temp_EMG_data.(timing_name) = cell(trial_num, 1);
    
    % Convert percentages to ratios
    cutout_range_ratio_struct.(timing_name) = cutout_range_struct.(timing_name_list{timing_id}) / 100;
end

% Initialize fields for whole trial
center_offset_timing_struct.whole_trial = zeros(trial_num, 2);
each_timing_cutout_EMG_struct.whole_trial = cell(1, EMG_num);
each_timing_cutout_EMG_struct.whole_trial_average = cell(1, EMG_num);
temp_EMG_data.whole_trial = cell(trial_num, 1);

% Process data for each muscle
for muscle_id = 1:EMG_num
    % Process data for each trial
    for trial_id = 1:trial_num
        % Calculate relative time based on task end time
        task_end_time = resampled_timing_data(trial_id, task_end_id);
        timing_percentage(trial_id, :) = resampled_timing_data(trial_id, :) ./ task_end_time;
        
        % Calculate reference points
        ref_points = calculateReferencePoints(timing_percentage(trial_id, :), task_start_id, focus_timing_num, cutout_range_ratio_struct);
        
        % Extract data segments for each timing event
        for timing_id = 1:focus_timing_num
            timing_name = ['timing' num2str(timing_id)];
            
            % Calculate segment range
            [start_idx, end_idx] = calculateSegmentRange(ref_points.(timing_name), cutout_range_ratio_struct.(timing_name), average_trial_sample_num);
            
            % Save segment range
            center_offset_timing_struct.(timing_name)(trial_id, :) = [start_idx, end_idx];
            
            % Extract EMG data segment
            temp_EMG_data.(timing_name){trial_id, 1} = time_normalized_EMG{1, muscle_id}(trial_id, start_idx:end_idx);
        end
        
        % Extract data segment for whole trial
        [whole_start_idx, whole_end_idx] = calculateSegmentRange(ref_points.timing1, cutout_range_ratio_struct.whole_trial, average_trial_sample_num);
        
        center_offset_timing_struct.whole_trial(trial_id, :) = [whole_start_idx, whole_end_idx];
        temp_EMG_data.whole_trial{trial_id, 1} = time_normalized_EMG{1, muscle_id}(trial_id, whole_start_idx:whole_end_idx);
    end
    
    % Process and store data for each timing event
    each_timing_cutout_EMG_struct = processAndStoreData(temp_EMG_data, each_timing_cutout_EMG_struct, cutout_range_ratio_struct, average_trial_sample_num, focus_timing_num, muscle_id);
end
end

%% Local functions
% Function to calculate reference points
function ref_points = calculateReferencePoints(timing_percentages, task_start_id, focus_timing_num, cutout_range_ratio_struct)
    ref_points = struct();
    
    for timing_id = 1:focus_timing_num
        timing_name = ['timing' num2str(timing_id)];
        ref_timing_id = (task_start_id + timing_id) - 1;
        ref_points.(timing_name) = cutout_range_ratio_struct.pre_task_percentage + timing_percentages(ref_timing_id);
    end
end

% Function to calculate segment range
function [start_idx, end_idx] = calculateSegmentRange(ref_point, margin_ratios, average_trial_sample_num)
    % Calculate start index
    start_point = ref_point - margin_ratios(1);
    start_idx = round(start_point * average_trial_sample_num + 1);
    
    % Calculate end index
    end_point = ref_point + margin_ratios(2);
    end_idx = floor(end_point * average_trial_sample_num - 1);
end

% Function to process and store data
function each_timing_cutout_EMG_struct = processAndStoreData(temp_EMG_data, each_timing_cutout_EMG_struct, cutout_range_ratio_struct, average_trial_sample_num, focus_timing_num, muscle_id)
    % Process data for each timing event
    for timing_id = 1:focus_timing_num
        timing_name = ['timing' num2str(timing_id)];
        margin_ratios = cutout_range_ratio_struct.(timing_name);
        
        % Calculate target data length
        target_length = round(average_trial_sample_num * sum(margin_ratios));
        
        % Align data lengths across trials
        [temp_EMG_data.(timing_name)] = resampleToUniformLength(temp_EMG_data.(timing_name), target_length);
        
        % Store time-normalized data
        each_timing_cutout_EMG_struct.(timing_name){muscle_id} = cell2mat(temp_EMG_data.(timing_name));
        
        % Extract valid data rows and calculate average
        current_data = each_timing_cutout_EMG_struct.(timing_name){muscle_id};
        valid_data = current_data(any(current_data, 2), :);
        
        % Store average data
        each_timing_cutout_EMG_struct.([timing_name '_average']){muscle_id} = mean(valid_data);
    end
    
    % Process data for whole trial
    whole_target_length = round(average_trial_sample_num * sum(cutout_range_ratio_struct.whole_trial));
    [temp_EMG_data.whole_trial] = resampleToUniformLength(temp_EMG_data.whole_trial, whole_target_length);
    
    % Store whole trial data
    each_timing_cutout_EMG_struct.whole_trial{muscle_id} = cell2mat(temp_EMG_data.whole_trial);
    each_timing_cutout_EMG_struct.whole_trial_average{muscle_id} = mean(each_timing_cutout_EMG_struct.whole_trial{muscle_id});
end