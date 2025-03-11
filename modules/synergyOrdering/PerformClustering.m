%{
condition_num: 188
cosine_distance_matrix: 188*188
syn_num: 4
session_num: 47

【以下、プロットするなら必要】
plot_setting: 1
labels: 1*188, cell array
period_type: 'post' (図の保存の際に必要)
save_fold_path

【注意点】
シナジー数と同じ数のクラスターに分ける時に、各クラスターの要素数は完全に一致していなければいけない
(例)
4 * 47 = 188の要素を4つのクラスターに分解する時、各クラスターの要素数は47でなければいけない。もし要素数が異なるのであればそれは、いずれかのクラスターが
同一セッションの複数のシナジーを要素として持っていることになるので、これはうまくいっていないと言うことになる。
%}

function [sort_idx, k_arr, coffen_coefficient] = PerformClustering(condition_num, cosine_distance_matrix, syn_num, session_num, plot_setting, labels, period_type, save_fold_path)
% transform cosine_distance_matrix into pairwize_distance_vector (to use as input argument of 'linkage')
pairwise_distance_vector = [];
for row_id = 1:condition_num-1
    ref_vector = cosine_distance_matrix(row_id, :);
    start_index = find(ref_vector==0) + 1;
    insert_vector = ref_vector(start_index:end);
    pairwise_distance_vector = [pairwise_distance_vector insert_vector];
end

% perform hierarchical clustering
Z = linkage(pairwise_distance_vector);
coffen_coefficient = cophenet(Z, pairwise_distance_vector);
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

    try
        k_arr(first_date_synergy_num, :) = stored_idx_list;
    catch
        % when multiple data form the same session is belonged in same cluster
        k_arr = [];
        break;
    end
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
    ylabel('cosine distance');
    title_str = sprintf(['cosine distance between synergies(' period_type ' ' num2str(session_num) 'sessions)(synNum = ' num2str(syn_num) ')' '\n' '(cophenetic correlation coefficient = ' num2str(coffen_coefficient) ')']);
    title(title_str, 'FontSize', 25);

    % save
    makefold(save_fold_path);
    saveas(gcf, fullfile(save_fold_path, ['dendrogram(' period_type '-synNum=' num2str(syn_num) ').png']));
    saveas(gcf, fullfile(save_fold_path, ['dendrogram(' period_type '-synNum=' num2str(syn_num) ').fig']));
    close all;
end
end