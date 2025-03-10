%{
[Function Description]
This function implements a sorting algorithm specifically designed for drawer task data.
It filters timing arrays according to specific conditions for the drawer task,
removing invalid event sequences and ensuring that all events occur within valid trial boundaries.
The function handles two main filtering steps: removing food-related events that occur
inappropriately, and ensuring all events are within trial start/end boundaries.

[Input Arguments]
input_task_timing_array: [double array] Timing array with dimensions [2 x events] where:
    - Row 1: Event timing (sample indices)
    - Row 2: Event ID (1=task start, 2=food on, 3=food off, 4=task end)

[Output Arguments]
filtered_task_timing_array: [double array] Filtered timing array with invalid events removed

[Improvement points(Japanese)]
%}

function [filtered_task_timing_array] = sortAlgorithmforDrawer(input_task_timing_array)
% If timing id is 1,4 (1 == 'task start', 2 == 'task end') and they are sandwiched between 2 and 3(2 == 'food on', 3 == 'food off'), erase 2 and 3
task_id_vector = input_task_timing_array(2, :);
use_id_flag = ones(1, length(task_id_vector));
for i = 2:(length(task_id_vector) - 1)
    if or(task_id_vector(i) == 1, task_id_vector(i) == 4) && and(task_id_vector(i-1)==2, task_id_vector(i+1)==3)
        use_id_flag(i-1) = 0;
        use_id_flag(i+1) = 0;
    end
end
filtered_task_timing_array = input_task_timing_array(:, find(use_id_flag));

% Delete timing data not sandwiched between timing 1 and 4. (because of these timing data is outside of the trial)
task_id_vector = filtered_task_timing_array(2, :);
use_id_flag = ones(1, length(filtered_task_timing_array));
delete_flag = 1;
for i = 1:length(filtered_task_timing_array)
    if task_id_vector(i) == 1
        delete_flag = 0;
    end

    if delete_flag
        use_id_flag(i) = 0;
    end

    if task_id_vector(i) == 4
        delete_flag = 1;
    end
end
filtered_task_timing_array = filtered_task_timing_array(:, find(use_id_flag));
end

