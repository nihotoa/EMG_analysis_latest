function [filtered_task_timing_array] = sortAlgorithmforHugo(input_task_timing_array)
% 1と6を挟むような[2, 3]を消す
task_id_vector = input_task_timing_array(2, :);
use_id_flag = ones(1, length(task_id_vector));
for i = 2:(length(task_id_vector) - 1)
    if or(task_id_vector(i) == 1, task_id_vector(i) == 6) && and(task_id_vector(i-1)==2, task_id_vector(i+1)==3)
        use_id_flag(i-1) = 0;
        use_id_flag(i+1) = 0;
    end
end
filtered_task_timing_array = input_task_timing_array(:, find(use_id_flag));

% 1-6の範囲外のものを消す
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

    if task_id_vector(i) == 6
        delete_flag = 1;
    end
end
filtered_task_timing_array = filtered_task_timing_array(:, find(use_id_flag));
end

