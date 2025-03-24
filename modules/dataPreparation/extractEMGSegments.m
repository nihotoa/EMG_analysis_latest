%{
[Function Description]
This function extracts segments of EMG data based on specified event timings.
It cuts out portions of EMG data around events of interest, applies padding,
and concatenates the segments into a continuous dataset. The function also
adjusts event timing data to match the new segmented data structure.

[Input Arguments]
concatenated_EMG_data: [double array] Original EMG data with dimensions [samples x channels]
event_timing_data: [double array] Event timing data with dimensions [trials x event_types]
trim_start_end_timings: [double array] Indices [start_idx, end_idx] specifying which event columns to use
common_sample_rate: [double] Sampling rate in Hz
padding_time: [double] Time in seconds to add before and after each segment

[Output Arguments]
extracted_EMG: [double array] Extracted and concatenated EMG segments with dimensions [channels x samples]
event_timings_after_trimmed: [double array] Adjusted event timing data matching the extracted segments
%}

function [extracted_EMG, event_timings_after_trimmed] = extractEMGSegments(concatenated_EMG_data, event_timing_data, trim_start_end_timings, common_sample_rate, padding_time)
if numel(trim_start_end_timings) ~= 2
    error('trim_start_end_timings must be a 1x2 array with [start_index, end_index]');
end
trim_start_timing = trim_start_end_timings(1);
trim_end_timing = trim_start_end_timings(2);

% Extract segment start and end timings
segment_start_event_timing = event_timing_data(:, trim_start_timing);
segment_end_event_timing = event_timing_data(:, trim_end_timing);
segment_start_end_timing_list = [segment_start_event_timing, segment_end_event_timing];

% Get dimensions
[~, EMG_num] = size(concatenated_EMG_data);
[trial_num, timing_num] = size(event_timing_data);

% Initialize arrays
extracted_EMG = cell(EMG_num, 1);
event_timings_after_trimmed = zeros(size(event_timing_data));

% Calculate cutout boundaries and adjust event timings once
cutout_boundaries = zeros(trial_num, 2);
current_position = 1;

for trial_id = 1:trial_num
    % Extract segment start and end timings for this trial
    ref_trial_range = segment_start_end_timing_list(trial_id, :);
    ref_segment_start_timing = ref_trial_range(1);
    ref_segment_end_timing = ref_trial_range(2);
    
    % Calculate padding in samples
    padding_sample_num = common_sample_rate * padding_time;
    
    % Calculate cutout boundaries with padding
    cutout_start_timing = max(1, ref_segment_start_timing - ceil(padding_sample_num));
    cutout_end_timing = ref_segment_end_timing + floor(padding_sample_num);
    
    % Store boundaries for later use
    cutout_boundaries(trial_id, :) = [cutout_start_timing, cutout_end_timing];
    
    % Adjust event timing data
    ref_event_timing_data = event_timing_data(trial_id, :);
    event_timing_in_this_trial = ref_event_timing_data - cutout_start_timing + 1;
    event_timings_after_trimmed(trial_id, :) = event_timing_in_this_trial + current_position - 1;
    
    % Calculate segment length
    segment_length = cutout_end_timing - cutout_start_timing + 1;
    
    % Update current position for next trial (add 1 for gap)
    current_position = current_position + segment_length;
end

% Zero out event timings that are outside the segment of interest
if trim_start_timing > 1
    event_timings_after_trimmed(:, 1:(trim_start_timing-1)) = 0;
end

if trim_end_timing < timing_num
    event_timings_after_trimmed(:, (trim_end_timing+1):end) = 0;
end

% Process each EMG channel
for EMG_id = 1:EMG_num
    ref_EMG = transpose(concatenated_EMG_data(:, EMG_id));
    trimmed_EMG = cell(1, trial_num);
    
    % Process each trial
    for trial_id = 1:trial_num
        % Get cutout boundaries
        cutout_start = cutout_boundaries(trial_id, 1);
        cutout_end = cutout_boundaries(trial_id, 2);
        
        % Extract EMG segment
        cut_out_EMG = ref_EMG(cutout_start:cutout_end);
        trimmed_EMG{trial_id} = cut_out_EMG;
    end
    
    % Concatenate all trials for this EMG channel
    extracted_EMG{EMG_id} = cell2mat(trimmed_EMG);
end

% Concatenate all EMG channels
extracted_EMG = cell2mat(extracted_EMG);
end