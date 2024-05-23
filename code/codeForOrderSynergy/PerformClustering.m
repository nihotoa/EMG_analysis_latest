function [sort_idx, k_arr] = PerformClustering(condition_num, cosine_distance_matrix, syn_num, session_num, plot_setting, labels, term_type, save_fold_path)
% transform cosine_distance_matrix into pairwize_distance_vector (to use as input argument of 'linkage')
paiwise_distance_vector = [];
for row_id = 1:condition_num-1
    ref_vector = cosine_distance_matrix(row_id, :);
    start_index = find(ref_vector==0) + 1;
    insert_vector = ref_vector(start_index:end);
    paiwise_distance_vector = [paiwise_distance_vector insert_vector];
end

% perform hierarchical clustering
Z = linkage(paiwise_distance_vector);
cluster_idx_list = cluster(Z, "maxclust", syn_num);

% save information of sort synergies acording to the result of clustering
k_arr = zeros(syn_num, session_num);
sort_idx = cell(1, syn_num);
for synergy_idx = 1:syn_num
    correspond_idx_list = find(cluster_idx_list == synergy_idx);
    stored_idx_list = mod(correspond_idx_list, syn_num);
    
    % change 0 value in 'stored_idx_list' to 'syn_num'
    changed_idx_list = find(stored_idx_list==0);
    stored_idx_list(changed_idx_list) = syn_num;
    first_date_synergy_num = stored_idx_list(1);
    
    % store the data
    sort_idx{first_date_synergy_num} = correspond_idx_list';
    k_arr(first_date_synergy_num, :) = stored_idx_list;
end

% plot dendrogram
if plot_setting == 1
    % make dendrogram(argument2 is involved in the number of data to display)
    figure('position', [100, 100, 1200, 800])
    if condition_num < 50
        dendrogram_fig = dendrogram(Z, 0, 'labels', labels);
    else
        dendrogram_fig = dendrogram(Z, 50, 'labels', labels);
    end

    % decoration of dendrogram
    hold on;
    grid on;
    set(dendrogram_fig, 'LineWidth', 1.5)
    dendrogram_axes = gca;
    dendrogram_axes.XTickLabelRotation = 90;
    dendrogram_axes.FontSize = 25;
    c = cophenet(Z, paiwise_distance_vector);
    title_str = sprintf(['cosine distance between synergies(' term_type ' ' num2str(session_num) 'days)' '\n' '(cophenetic correlation coefficient = ' num2str(c) ')']);
    title(title_str, 'FontSize', 25);

    % save
    saveas(gcf, fullfile(save_fold_path, ['dendrogram(' term_type ').png']));
    saveas(gcf, fullfile(save_fold_path, ['dendrogram(' term_type ').fig']));
    close all;
end
end