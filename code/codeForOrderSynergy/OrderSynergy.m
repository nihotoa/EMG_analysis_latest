%{

%}

function [Wt, k_arr] = OrderSynergy(EMG_num, syn_num, W_data, monkeyname, days, base_dir, plot_clustering_result, term_type)
if not(exist('term_type', 'var')) || not(exist("plot_clustering_result", 'var')) || plot_clustering_result == 0
    plot_setting = 0;
else
    plot_setting = 1;
    % setting of save_folder
    hierarchical_cluster_result_path = fullfile(base_dir, 'hierarchical_cluster_result');
    makefold(hierarchical_cluster_result_path);
end

%% find session_num
if exist('days', 'var')
    session_num = length(days);
else % currently, this situation is estimated when using 'test' data in 'SYNERGYPLOT'
    session_num = length(W_data);
end

% prepare empty list for labeling
labels = {}; % name list of synergies before sorting
sorted_labels = {}; % name list of synergies after sorting
alphabet_string = 'A':'Z';

%% Create an empty array to store synergy W values
if isempty(W_data)
    W_data =  cell(1,session_num);
    % Read the daily synergy W values & create an array.
    for date_id = 1:session_num
        % Load the W synergy data created by SYNERGYPLOT
        synergy_W_file_path = fullfile(base_dir, [monkeyname mat2str(days(date_id)) '_standard'], [monkeyname mat2str(days(date_id)) '_syn_result_' sprintf('%d',EMG_num)], [monkeyname mat2str(days(date_id)) '_W'], [monkeyname mat2str(days(date_id)) '_aveW_' sprintf('%d',syn_num) '.mat']);
        load(synergy_W_file_path, 'aveW');
        W_data{date_id} = aveW;
        
        % % append name of synergies for labeling
        [~, syn_num] = size(aveW);
        use_alphabet_str = alphabet_string(1:syn_num);
        for synergy_id = 1:length(use_alphabet_str)
            labels{end+1} = [use_alphabet_str(synergy_id) num2str(date_id)];
            sorted_labels{end+1} = [ num2str(date_id) '-' 'S' num2str(synergy_id) ];
        end
    end
end

% transform cell array to double array
W_data_for_Wt = W_data;
W_data = cell2mat(W_data);
[~, condition_num] = size(W_data);

%% calcurate cosine distance of all pairs of spatial pattern vectors & plot this as heatmap & store them in a square matrix
if plot_setting == 1
    title_str = ['cosine distance between each synergies' '\n' 'original order (' term_type ' ' num2str(session_num) 'days)'];
    save_file_name =  ['original_order_heatmap(' term_type ')'];
    cosine_distance_matrix = PerformCosineDistanceAnalysis(condition_num, W_data, plot_setting, labels, title_str, hierarchical_cluster_result_path, save_file_name);
else
    cosine_distance_matrix = PerformCosineDistanceAnalysis(condition_num, W_data, plot_setting);
end

%% perform clustering & plot dendrogram
if plot_setting == 1
    [sort_idx, k_arr] = PerformClustering(condition_num, cosine_distance_matrix, syn_num, session_num, plot_setting, labels, term_type, hierarchical_cluster_result_path);
else
    [sort_idx, k_arr] = PerformClustering(condition_num, cosine_distance_matrix, syn_num, session_num, plot_setting);
end

%%  plot cosine distance between each pair of synergy by grid after sorting synergies
if plot_setting==1
    sort_idx = cell2mat(sort_idx);
    sorted_cosine_distance_matrix = cosine_distance_matrix(sort_idx, sort_idx);
    
    % plot
    title_str = ['cosine distance between each synergies' '\n' 'sorted (' term_type ' ' num2str(session_num) 'days)'];
    save_file_name = ['ordered_heatmap(' term_type ')'];
    plotCosineDistance(sorted_cosine_distance_matrix, condition_num, sorted_labels, title_str, hierarchical_cluster_result_path, save_file_name)
end

%% make Wt
Wt = cell(1, session_num);
for day_id = 1:session_num
    Wt{day_id} = W_data_for_Wt{day_id}(:, k_arr(:, day_id));
end
end
