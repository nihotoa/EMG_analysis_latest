%{
condition_num: 188
W_data: 10*188
plot_setting: 1

【以下plot_setting==1なら必要】
labels:
title_str:
save_fold_path:
save_file_name:
%}

function [cosine_distance_matrix] = PerformCosineDistanceAnalysis(condition_num, W_data, plot_setting, labels, title_str, save_fold_path, save_file_name)
% calcurate cosine distance of all pairs of spatial pattern vectors and sotre them in a square matrix
cosine_distance_matrix = zeros(condition_num, condition_num);
for ref1_id = 1:condition_num
    ref1_W_vector = W_data(:, ref1_id);
    for ref2_id = 1:condition_num
        ref2_W_vector = W_data(:, ref2_id);

        % calcurate_cosine distance
        denumerator_value = dot(ref1_W_vector, ref2_W_vector);
        denomitor_value = norm(ref1_W_vector) * norm(ref2_W_vector);
        cosine_distance_value = 1 - (denumerator_value / denomitor_value);
        cosine_distance_value = round(cosine_distance_value, 5);
        cosine_distance_matrix(ref1_id, ref2_id) = cosine_distance_value;
    end
end

% plot cosine distance between each pair of synergy by grid
if plot_setting == 1
    plotCosineDistance(cosine_distance_matrix, condition_num, labels, title_str, save_fold_path, save_file_name)
end
end