%{

%}

function [Wt, k_arr] = OrderSynergy(syn_num, W_data, session_num, plot_clustering_result_flag, save_figure_dir, unique_name)
if plot_clustering_result_flag == 1
    % prepare empty list for labeling
    labels = {}; % name list of synergies before sorting
    sorted_labels = {}; % name list of synergies after sorting
    alphabet_string = 'A':'Z';

    for session_id = 1:session_num
        %append name of synergies for labeling
        [~, syn_num] = size(W_data{1});
        use_alphabet_str = alphabet_string(1:syn_num);
        for synergy_id = 1:length(use_alphabet_str)
            labels{end+1} = [use_alphabet_str(synergy_id) num2str(session_id)];
            sorted_labels{end+1} = [ num2str(session_id) '-' 'S' num2str(synergy_id) ];
        end
    end
end

% transform cell array to double array
W_data_for_Wt = W_data;
W_data = cell2mat(W_data);
[~, condition_num] = size(W_data);

%% calcurate cosine distance of all pairs of spatial pattern vectors & plot this as heatmap & store them in a square matrix
if plot_clustering_result_flag == true
    heatmap_save_fold_path = fullfile(save_figure_dir, 'cosine_distance_heatmap');
    clustering_save_fold_path = fullfile(save_figure_dir, 'hierarchical_clustering_dendrogram');
    title_str = ['cosine distance between each synergies' '\n' 'original order (' unique_name ' ' num2str(session_num) 'sessions)(synNum = ' num2str(syn_num) ')'];
    non_ordererd_heatmap_file_name =  ['original_order_heatmap(' unique_name ')_syn_num = ' num2str(syn_num)];
    cosine_distance_matrix = PerformCosineDistanceAnalysis(condition_num, W_data, plot_clustering_result_flag, labels, title_str, heatmap_save_fold_path, non_ordererd_heatmap_file_name);
else
    cosine_distance_matrix = PerformCosineDistanceAnalysis(condition_num, W_data, plot_clustering_result_flag);
end

%% perform clustering & plot dendrogram
if plot_clustering_result_flag == true
    [sort_idx, k_arr] = PerformClustering(condition_num, cosine_distance_matrix, syn_num, session_num, plot_clustering_result_flag, labels, unique_name, clustering_save_fold_path);
else
    [sort_idx, k_arr] = PerformClustering(condition_num, cosine_distance_matrix, syn_num, session_num, plot_clustering_result_flag);
end

% 
if isempty(k_arr)
    Wt = [];
    return
end

%%  plot cosine distance between each pair of synergy by grid after sorting synergies
if plot_clustering_result_flag==1
    sort_idx = cell2mat(sort_idx);
    sorted_cosine_distance_matrix = cosine_distance_matrix(sort_idx, sort_idx);
    
    % plot
    title_str = ['cosine distance between each synergies' '\n' 'sorted (' unique_name ' ' num2str(session_num) 'sessions)(synNum = ' num2str(syn_num) ')'];
    save_file_name = ['ordered_heatmap(' unique_name '-synNum=' num2str(syn_num) ')'];
    plotCosineDistance(sorted_cosine_distance_matrix, condition_num, sorted_labels, title_str, heatmap_save_fold_path, save_file_name)
end

%% make Wt
Wt = cell(1, session_num);
for day_id = 1:session_num
    Wt{day_id} = W_data_for_Wt{day_id}(:, k_arr(:, day_id));
end
end
