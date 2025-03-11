%{
[Function Description]
This function processes event data from drawer task experiments.
It extracts timing information from port input signals, identifies successful trials,
and calculates the timing of key events such as drawer opening/closing and food retrieval.
The function is specifically designed for the Hugo monkey's drawer task and handles
data from multiple recording files.

[Input Arguments]
full_monkey_name: [char] Full name of the monkey
monkey_prefix: [char] Prefix identifying the monkey (typically 'Hu' for Hugo)
experiment_day: [char] Date of experiment as a string
validate_file_range: [double array] Range of files to process
common_sample_rate: [double] Common sampling rate for all signals
success_button_count_threshold: [integer] Threshold for success button count
time_restriction_enabled: [logical] Flag to enable time restriction
trial_time_threshold: [double] Time limit for restriction (if enabled)

[Output Arguments]
transposed_success_timing: [double array] Timing data for successful trials with dimensions
    [trials x timing_events], containing sample indices for each timing event
%}
function [transposed_success_timing] = processDrawerTaskEvents(full_monkey_name, monkey_prefix, experiment_day, validate_file_range, common_sample_rate, success_button_count_threshold, time_restriction_enabled, trial_time_threshold)
raw_data_file_path = fullfile(fileparts(pwd), 'useDataFold', full_monkey_name, [monkey_prefix experiment_day '-' sprintf('%04d', validate_file_range(1))]);
timing_data_struct = load(raw_data_file_path, 'CAI*', 'CTTL*');
timing_struct = struct();
resampling_factor = common_sample_rate / (timing_data_struct.CTTL_002_KHz * 1000);

% make digitai timing matrix from CAI signal
CAI_signal = timing_data_struct.CAI_001;
start_end_timing_array_candidate = find(CAI_signal > -100);

% 1.extract 'start' and 'end' timing
task_start_timing_candidates = eliminate_consective_num(start_end_timing_array_candidate, 'front');
task_end_timing_candidates = eliminate_consective_num(start_end_timing_array_candidate, 'back');

% 2. make timing_id array
task_candidate_count = length(task_start_timing_candidates);
task_start_id_array = ones(1, task_candidate_count) * 1;
task_end_id_array = ones(1, task_candidate_count) * 4;

% 3.resample and make array (which is consist of timing and id)
task_start_timing_candidates = round(task_start_timing_candidates * resampling_factor);
timing_struct.task_start = [task_start_timing_candidates; task_start_id_array];
task_end_timing_candidates = round(task_end_timing_candidates * resampling_factor);
timing_struct.task_end = [task_end_timing_candidates; task_end_id_array];

% make 'drawer on', 'drawer off',  'food on', 'food off' timing.
%1. assign timing data in each array
touch_sensor_signal = sort([timing_data_struct.CTTL_002_Down; timing_data_struct.CTTL_002_Up], 1);
touch_on_timing_array = touch_sensor_signal(1, :);
touch_off_timing_array= touch_sensor_signal(2, :);

success_button_timing_array = timing_data_struct.CTTL_003_Down;

%2. assign id in each array
touch_on_id = ones(1, length(touch_on_timing_array)) * 2;
touch_off_id = ones(1, length(touch_off_timing_array)) * 3;
success_button_id = ones(1, length(success_button_timing_array)) * 5;

% 3.resample and make array (which is consist of timing and id)
touch_on_timing_array = round(touch_on_timing_array * resampling_factor);
timing_struct.touch_on = [touch_on_timing_array; touch_on_id];
touch_off_timing_array = round(touch_off_timing_array * resampling_factor);
timing_struct.touch_off = [touch_off_timing_array; touch_off_id];
success_button_timing_array = round(success_button_timing_array * resampling_factor);
timing_struct.success_button = [success_button_timing_array; success_button_id];

% merge and crearte all_timing_data
% 1st stage screening
basic_task_sequence = [timing_struct.task_start , timing_struct.touch_on, timing_struct.touch_off, timing_struct.task_end];
[~, sort_sequence] = sort(basic_task_sequence(1, :));
basic_task_sequence = basic_task_sequence(:, sort_sequence);
basic_task_sequence = sortAlgorithmforDrawer(basic_task_sequence);

% get the index of the element that matches the valid_event_sequence1
valid_event_sequence1 = [1, 2, 3, 2, 3, 4];
necessary_idx = [];
validate_length = length(valid_event_sequence1) - 1;
for ref_start_id = 1 : (length(basic_task_sequence) - validate_length)
    if all(basic_task_sequence(2, ref_start_id : (ref_start_id + validate_length)) == valid_event_sequence1)
        necessary_idx = [necessary_idx ref_start_id : (ref_start_id + validate_length)];
    end
end
filtered_basic_sequence = basic_task_sequence(:, necessary_idx);

% marge ref_timing_array and success_button_timing_array & update ref_timing_array which matches the valid_event_sequence2
success_button_count = length(timing_struct.success_button);
has_sufficient_success_events = false;
if success_button_count > success_button_count_threshold
    has_sufficient_success_events = true;
end

if has_sufficient_success_events
    extended_task_sequence = [filtered_basic_sequence timing_struct.success_button];
    [~, sort_sequence] = sort(extended_task_sequence(1, :));
    extended_task_sequence = extended_task_sequence(:, sort_sequence);
    
    % get the index of the element that matches the valid_event_sequence2
    valid_event_sequence2 = [1, 2, 3, 2, 3, 4, 5];
    necessary_idx = [];
    validate_length = length(valid_event_sequence2) - 1;
    for ref_start_id = 1:length(extended_task_sequence) - validate_length
        if all(extended_task_sequence(2, ref_start_id:ref_start_id + validate_length) == valid_event_sequence2)
            necessary_idx = [necessary_idx ref_start_id:ref_start_id + validate_length];
        end
    end
    filtered_extended_sequence = extended_task_sequence(:, necessary_idx);
    Timing = filtered_extended_sequence;
    final_valid_event_sequence = valid_event_sequence2;
else
    Timing = filtered_basic_sequence;
    final_valid_event_sequence = valid_event_sequence1;
end

% create output arguments
transposed_success_timing = reshape(Timing(1, :), length(final_valid_event_sequence), [])';

if time_restriction_enabled
    trial_duration = (transposed_success_timing(:,end) - transposed_success_timing(:,1)) / common_sample_rate;
    transposed_success_timing = transposed_success_timing(trial_duration(:, 1) < trial_time_threshold, :);
end

if has_sufficient_success_events
    % eliminate 'success_button' data
    transposed_success_timing = transposed_success_timing(:, 1:end-1);
end
end
