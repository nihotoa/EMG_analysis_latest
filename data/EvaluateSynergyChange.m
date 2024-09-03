%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Go to the directory where this code is stored
2. Change some parameters(Please refer to 'setparam' section)
3. Please run this code

[role of this code]
> Evaluate changes in spatial synergy using PCA(Principle Component Analysis)
> This allows us to  quantify which weight of muscle affect changes in synergy
> This also allows us to  explain changes in the spatial synergy in lower dimention

[Saved data location]
<figures for contribution and coefficient vector of each principle component>
    [path]: /EMG_analysis_latest/data/Yachimun/new_nmf_result/evaluate_synergy_change_result/contribution_and_coeff

<plot of each spatial synergy on a dimension-reduced space>
    [path]:
    /EMG_analysis_latest/data/Yachimun/new_nmf_result/evaluate_synergy_change_result/pc_plot

[procedure]
pre: dispNMF_W.m
post: nothing

[improvement point]
All the japanese characters ara garbled, so refer to past commits and fix them
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

%% set param
monkeyname = 'Ya';  % Name prefix of the folder containing the synergy data for each date
nmf_fold_name = 'new_nmf_result'; % name of nmf folder
session_group_name_list = {'pre', 'post'};
variance_threshld = 0.8; % 累積�?与率の閾値
cluster_num = 2;

%% code section
realname = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname, nmf_fold_name);
Wdata_dir = fullfile(base_dir, 'W_synergy_data');
common_save_dir = fullfile(base_dir, 'evaluate_synergy_change_result');
makefold(common_save_dir);
candidate_file_list = dirEx(Wdata_dir);
session_group_num = length(session_group_name_list);

% make structure object(structure array) for permutation for each session_group & store it in 'main_structure'
main_structure = struct();
for session_group_id = 1:session_group_num
    ref_session_group = session_group_name_list{session_group_id};
    ref_file_name = candidate_file_list(contains({candidate_file_list.name}, ref_session_group)).name;
    ref_structure = load(ref_file_name);
    ref_structure.session_group = ref_session_group;
    [~, session_num] = size(ref_structure.WDaySynergy{1});
    ref_structure.session_num = session_num;
    main_structure.(session_group_name_list{session_group_id}) = ref_structure;
end
synergy_num = length(ref_structure.WDaySynergy);

%% conduct PCA for each synergy
[~, pre_day_num] = size(main_structure.pre.WDaySynergy{1});
W_data = cellfun(@(pre_synergy, post_synergy) [pre_synergy, post_synergy], main_structure.pre.WDaySynergy, main_structure.post.WDaySynergy, UniformOutput=false);

% �?空間シナジーを長�?1に正規化(単位�?�クトルにする)
W_data = cellfun(@(x) normalizeVectors(x), W_data, 'UniformOutput', false);

% シナジーごとにPCAとクラスタリングを行って図示する
for synergy_id = 1:synergy_num
    ref_W_data = transpose(W_data{synergy_id});
    % coeff => �?列が�?種成�?の係数ベクトル, score => �?列が,そ�?�主成�?に対する�?ータの投�?した値(主成�?得点),
    % explained=> �?種成�?の�?与率
    [coeff, score, ~, ~, explained, ~] = pca(ref_W_data);

    % 使用する主成�?の数を決定す�?
    variance_total = 0;
    for pc_num = 1:length(explained)
        variance_total = variance_total + (explained(pc_num) / 100);
        if variance_total > variance_threshld
            use_pc_num = pc_num;
            break;
        end
    end
    use_coeff = coeff(:, 1:use_pc_num);
    use_score = score(:, 1:use_pc_num);

    % 主成�?得点�?2主成�? or 3主成�?でプロ�?�?
    if use_pc_num>=3
        plot_dim = 3;
        use_score = use_score(:, 1:3);
        plot_func = @plot3;
    else
        plot_dim = 2;
        plot_func = @plot;
    end

    % 主成�?スコアを用�?てk-meansクラスタリング
    [cluster_idx_list, C_list] = kmeans(use_score, cluster_num, 'Distance', 'cityblock', 'Replicates', 5, 'Options', statset('Display', 'final'));
    point_shape_list = {'o', '^', 'square', 'v', 'pentagram'};

    % 実際にプロ�?トす�?
    figure('position', [100, 100, 800, 600])
    hold on;
    [data_num, ~] = size(use_score);
    for data_id = 1:data_num
        % 色の決�?
        if data_id <= pre_day_num
            color_vector = [0 0 1];
        else
            color_vector = [50+205*((data_id - pre_day_num) / (data_num-pre_day_num)) 0 0]/255;
        end
        if plot_dim == 3
            plot_func(use_score(data_id, 1), use_score(data_id, 2), use_score(data_id, 3), point_shape_list{cluster_idx_list(data_id)}, 'color', color_vector, 'MarkerSize', 10, linewidth=1.5);
        else
            plot_func(use_score(data_id, 1), use_score(data_id, 2), point_shape_list{cluster_idx_list(data_id)}, 'color', color_vector,  'MarkerSize', 10, linewidth=1.5);
        end
    end
    % 重�?のプロ�?�?
    if plot_dim == 3
        plot_func(C_list(:, 1), C_list(:, 2), C_list(:, 3), 'kx', 'MarkerSize', 15, 'LineWidth', 3, 'color', 'g');
        xlim([-1 1]);
        ylim([-1 1]);
        zlim([-1 1])
    elseif plot_dim==2
        plot_func(C_list(:, 1), C_list(:, 2), 'kx', 'MarkerSize', 15, 'LineWidth', 3, 'color', 'g');
        xlim([-1 1]);
        ylim([-1 1]);
    else
        % not edited
    end

    % decoration
    grid on;
    title(['plot for each principal component(cluster-num=' num2str(cluster_num) ')']);
    xlabel('principle component score for "pc1"');
    ylabel('principle component score for "pc2"');
    xlim([-1 1]);
    ylim([-1 1]);
    xline(0, LineWidth=1.5)
    yline(0, LineWidth=1.5)
    if plot_dim == 3
        zlim([-1 1]);
    end
    set(gca, 'FontSize', 15);

    % save setting
    plot_save_dir = fullfile(common_save_dir, 'pc_plot');
    makefold(plot_save_dir)
    saveas(gcf, fullfile(plot_save_dir, ['pc_plot(' num2str(plot_dim) 'D)_synergy' num2str(synergy_id) ').png']))
    saveas(gcf, fullfile(plot_save_dir, ['pc_plot(' num2str(plot_dim) 'D)_synergy' num2str(synergy_id) ').fig']))
    close all;

    % 主成�?の係数ベクトルと�?与率を別途図示する(絶対値が�?番大きいも�?�を赤にする)
    % 2*1のsubplotを作�?�して?�?1個目に係数ベクトルを�?2個目に累積�?与率を�?�ロ�?トす�?
    figure('position', [100, 100, 800, 1200])
    subplot(2,1,1);
    hold on;
    cmap_matrix = [1 1 1; 1 0 0];
    plot_coeff = transpose(use_coeff);
    [~, max_indicies] = max(abs(plot_coeff), [], 2);
    colormap_id_matrix = ones(size(plot_coeff));
    for pc_id = 1:use_pc_num
        colormap_id_matrix(pc_id, max_indicies(pc_id)) = 2;
    end
    x_labels = cellstr(main_structure.post.x);
    y_labels = arrayfun(@(i) sprintf('pc%d', i), 1:use_pc_num, 'UniformOutput', false);
    title_str = 'Coefficient for each princical component';
    CreateAnnotatedHeatmap(cmap_matrix, plot_coeff, colormap_id_matrix, x_labels, y_labels, title_str)
    
    subplot(2, 1, 2)
    barh(categorical("contribution"), transpose(explained/100), "stacked")
    ax = gca;
    ax.YTickLabelRotation = 90;
    xlim([0 1])
    title('Contribution of each principal component');
    set(gca, 'FontSize', 15);

    % save setting
    coeff_save_dir = fullfile(common_save_dir, 'contribution_and_coeff');
    makefold(coeff_save_dir)
    saveas(gcf, fullfile(coeff_save_dir, ['contribution_and_coeff_of_pc(synergy' num2str(synergy_id) ')_variance_threshold=' num2str(variance_threshld) '.png']))
    saveas(gcf, fullfile(coeff_save_dir, ['contribution_and_coeff_of_pc(synergy' num2str(synergy_id) ')_variance_threshold=' num2str(variance_threshld) '.fig']))
    close all;
end

%% define local function
% matrixは10*51の行�??, 列ごとにベクトルとして処�?を行う
function normalizedMatrix = normalizeVectors(matrix)
% �?列�?�クトルにつ�?て?��ノル�?を計�?
norms = sqrt(sum(matrix.^2, 1));

% �?列に対して?��ノル�?で割る�?��?を適用
normalizedMatrix = bsxfun(@rdivide, matrix, norms);
end
