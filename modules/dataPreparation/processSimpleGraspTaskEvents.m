%{
[Function Description]
This function processes event data from simple grasp task experiments.
It extracts timing information from port input signals, identifies successful trials,
and calculates the timing of key events such as grasp on/off. The function is specifically
designed for the Nibali monkey's simple grasping task and handles data from multiple
recording files.

[Input Arguments]
full_monkey_name: [char] Full name of the monkey
monkey_prefix: [char] Prefix identifying the monkey (typically 'Ni' for Nibali)
experiment_day: [char] Date of experiment as a string
validate_file_range: [double array] Range of files to process
downdata_to: [double] Downsampling rate

[Output Arguments]
transposed_success_timing: [double array] Timing data for successful trials with dimensions
    [trials x timing_events], containing sample indices for each timing event
%}
function [transposed_success_timing] = processSimpleGraspTaskEvents(full_monkey_name, monkey_prefix, experiment_day, validate_file_range, downdata_to)
load_file_path = fullfile(pwd, full_monkey_name, [monkey_prefix experiment_day '-' sprintf('%04d', validate_file_range(1))]);
make_timing_struct = load(load_file_path, 'CAI*', 'CTTL*');
timing_struct = struct();
multple_value = downdata_to / (make_timing_struct.CTTL_002_KHz * 1000);

% make digitai timing matrix from CAI signal
CAI_signal = make_timing_struct.CAI_001;
start_end_timing_array_candidate = find(CAI_signal > -100);

% 1.extract 'start' and 'end' timing
start_timing_array = eliminate_consective_num(start_end_timing_array_candidate, 'front');
end_timing_array = eliminate_consective_num(start_end_timing_array_candidate, 'back');

% 2. make timing_id array
start_end_num = length(start_timing_array);
start_id_array = ones(1, start_end_num) * 1;
end_id_array = ones(1, start_end_num) * 4;

% 3.resample and make array (which is consist of timing and id)
start_timing_array = round(start_timing_array * multple_value);
timing_struct.start_timing_array = [start_timing_array; start_id_array];
end_timing_array = round(end_timing_array * multple_value);
timing_struct.end_timing_array = [end_timing_array; end_id_array];

% make 'grasp on', 'grasp off' and 'success' timing
%1. assign timing data in each array
[grasp_signal, id_vector] = sort([make_timing_struct.CTTL_002_Down; make_timing_struct.CTTL_002_Up], 1);
if not(unique(id_vector(1, :)) == 1)
    error('Inconsistent sort order of "grasp on" and "grasp off"');
end
grasp_on_timing_array = grasp_signal(1, :);
grasp_off_timing_array = grasp_signal(2, :);
success_timing_array = make_timing_struct.CTTL_003_Down;

%2. assign id in each array
grasp_on_id = ones(1, length(grasp_on_timing_array)) * 2;
grasp_off_id = ones(1, length(grasp_off_timing_array)) * 3;
succcess_id = ones(1, length(success_timing_array)) * 5;

% 3.resample and make array (which is consist of timing and id)
grasp_on_timing_array = round(grasp_on_timing_array * multple_value);
timing_struct.grasp_on_timing_array = [grasp_on_timing_array; grasp_on_id];
grasp_off_timing_array = round(grasp_off_timing_array * multple_value);
timing_struct.grasp_off_timing_array = [grasp_off_timing_array; grasp_off_id];
success_timing_array = round(success_timing_array * multple_value);
timing_struct.success_timing_array = [success_timing_array; succcess_id];

% merge and crearte all_timing_data
% 1st stage screening
ref_timing_array1 = [timing_struct.start_timing_array , timing_struct.grasp_on_timing_array, timing_struct.grasp_off_timing_array, timing_struct.end_timing_array];
[~, sort_sequence] = sort(ref_timing_array1(1, :));
ref_timing_array1 = ref_timing_array1(:, sort_sequence);

% get the index of the element that matches the condition1
condition1 = [1, 2, 3, 4];
necessary_idx = [];
for ref_start_id = 1:length(ref_timing_array1)-3
    if all(ref_timing_array1(2, ref_start_id:ref_start_id+3) == condition1)
        necessary_idx = [necessary_idx ref_start_id:ref_start_id+3];
    end
end
match_1st_array = ref_timing_array1(:, necessary_idx);

% marge ref_timing_array and success_timing_array & update ref_timing_array which matches the condition2
ref_timing_array2 = [match_1st_array timing_struct.success_timing_array];
[~, sort_sequence] = sort(ref_timing_array2(1, :));
ref_timing_array2 = ref_timing_array2(:, sort_sequence);

% get the index of the element that matches the condition2
condition2 = [1, 2, 3, 4, 5];
necessary_idx = [];
for ref_start_id = 1:length(ref_timing_array2)-4
    if all(ref_timing_array2(2, ref_start_id:ref_start_id+4) == condition2)
        necessary_idx = [necessary_idx ref_start_id:ref_start_id+4];
    end
end
match_2nd_array = ref_timing_array2(:, necessary_idx);

% create output arguments
Timing = match_2nd_array;
transposed_success_timing = reshape(Timing(1, :), 5, [])';
end
