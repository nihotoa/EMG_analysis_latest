%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code

[role of this code]
・verify the change in spatial synergy by statistical test

[Saved data location]

[procedure]
pre: dispNMF_W.m
post: nothing

[Improvement points(Japanaese)]
3種類のanovaでswitchして処理を行なっているが、被っている部分があるので、共通部分は共通して書くように改善する
ヒートマップの中に数字書くやつも、commonCodeとして実装する

[caution!!]
・シナジー数は全セッションを通して固定されている前提で検定を行なっている(じゃないと比較できない)
・2元配置分散分析の因子が2つとも固定されているので、選択できるように変更する
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

%% set param
monkeyname = 'Se';  % Name prefix of the folder containing the synergy data for each date
nmf_fold_name = 'new_nmf_result'; % name of nmf folder
session_group_name_list = {'pre', 'post'};
display_synergy = false; % wherer you want to output spatial pattern to be compared
figure_file_name_pattern = '^W.*\.fig$'; % 読み込みたい.figファイルの正規表現
test_type = 'muscle-one-way-anova' ; % 'one-way-anova', 'muscle-one-way-anova', 'two-way-anova', 'MANOVA', 'comprehensive_test' 
test_type_for_comprehensive_test = 'two-way-anova';  % 'two-way-anova', 'friedman'
display_cosine_distance = false;
significant_level_threshold = 0.05;

%% code section
realname = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname, nmf_fold_name);
Wdata_dir = fullfile(base_dir, 'W_synergy_data');
W_figure_dir = fullfile(base_dir, 'syn_figures');
common_save_dir = fullfile(base_dir, 'anova_result');
makefold(common_save_dir);
candidate_file_list = dirEx(Wdata_dir);
session_group_num = length(session_group_name_list);

%% plot synergy to be compared by anova
if display_synergy == true
    save_figure_name = 'compared_synergy_for_anova';
    figure_fold_path_list = {};
    for session_group_id = 1:session_group_num
        disp('【Please select the following session group figure folder】')
        disp(['session group: ' session_group_name_list{session_group_id}])
        folder_path = uigetdir(W_figure_dir);
        figure_fold_path_list{session_group_id} = folder_path;
    end

    % 使用する全てのfigureファイルのpathを格納したcell配列を作成する
    % figure objectを渡すと、値渡しではなく参照渡しであり
    group_num = length(figure_fold_path_list);
    for group_id = 1:group_num
        ref_figure_fold_path = figure_fold_path_list{group_id};
        candidate_figure_list = dirEx(ref_figure_fold_path);
        figure_file_struct = candidate_figure_list(~cellfun('isempty', regexp({candidate_figure_list.name}, figure_file_name_pattern)));
        if group_id == 1
            synergy_num = length(figure_file_struct);
            figure_file_path_list = cell(synergy_num, group_num);
        end
        for synergy_id = 1:synergy_num
            ref_figure_path = fullfile(ref_figure_fold_path, figure_file_struct(synergy_id).name);
            % ref_figure = openfig(ref_figure_path, 'invisible');
            figure_file_path_list{synergy_id, group_id} = ref_figure_path;
            % close(ref_figure)
        end
    end
    
    synergy_name_list = arrayfun(@(i) sprintf('synergy%d', i), 1:synergy_num, 'UniformOutput', false);
    % create new figure  by combining .fig file
    mergeFigures(figure_file_path_list, common_save_dir, save_figure_name, synergy_name_list, session_group_name_list)
end

%% conduct anova
% make structure object(structure array) for anova for each session_group & store it in 'main_structure'
main_structure = struct();
for session_group_id = 1:session_group_num
    ref_session_group = session_group_name_list{session_group_id};
    ref_file_name = candidate_file_list(contains({candidate_file_list.name}, ref_session_group)).name;
    ref_structure = load(ref_file_name);
    ref_structure.session_group = ref_session_group;
    [~, session_num] = size(ref_structure.WDaySynergy{1});
    ref_structure.session_num = session_num;
    main_structure.(['group' num2str(session_group_id)]) = ref_structure;
end
synergy_num = length(ref_structure.WDaySynergy);

% perform anova
save_fold_path = fullfile(common_save_dir, test_type, [session_group_name_list{1} '_vs_' session_group_name_list{end}]);
session_group_elements_char = join(session_group_name_list, ', ');
session_group_elements_char = session_group_elements_char{1};
disp(['【test_type: ' test_type ', session_group: ' session_group_elements_char '】'])
for synergy_id = 1:synergy_num
    [examined_data, label_array, cosine_distance_list] = AnovaPreparation(main_structure, synergy_id, test_type);
    [tbl, p_value_array, stats_struct] = executeAnova(examined_data, label_array, test_type, synergy_id, test_type_for_comprehensive_test);

    % (if test_type == 'comprehensive_test') visualize the results of multiple testing
    if not(isempty(stats_struct))
        factor_list = fieldnames(stats_struct);
        for factor_id = 1:length(factor_list)
            ref_factor = factor_list{factor_id};
            if stats_struct.(ref_factor).hasSigDiff == false
                continue;
            end
            ref_stats = stats_struct.(ref_factor).stats;
            multcompare_result = multcompare(ref_stats, "CriticalValueType","bonferroni", "Display","off");

            % make tables
            ColNames = {'Synergy ID1', 'Synergy ID2', 'confidence interval(lower lim)', 'Difference of means', 'confidence interval(upper lim)', 'p_value'};
            multcompare_result_tbl = array2table(multcompare_result, 'VariableNames',ColNames);

            % save_setting
            multcompare_result_file_name = ['multcompare_result(vs_preSynergy' num2str(synergy_id) ')(' test_type_for_comprehensive_test '_to_bonferroni).csv'];
            SaveAnovaResult(save_fold_path, multcompare_result_file_name, multcompare_result_tbl);
        end
    end

    % (if test_type == 'comprehensive_test') combine cosine distance data (for visualize)
    if not(isempty(cosine_distance_list))
        if synergy_id == 1
            all_cosine_distance_list = cell(synergy_num, 1);
        end
        all_cosine_distance_list{synergy_id} = cosine_distance_list;
    end
    
    % save result of static test as csv file
    if not(isempty(p_value_array))
        p_value_array_list{synergy_id, 1} = p_value_array;
    else
        % save result
        save_file_name = ['synergy' num2str(synergy_id) '_result(' test_type '(' test_type_for_comprehensive_test ')).csv'];
        SaveAnovaResult(save_fold_path, save_file_name, tbl)
    end
end

% (if test_type=='comprehensive_test') visualize cosine distance between 'each_control_spatial_pattern' VS all each post spatial pattern
% session_group_name_list = {'pre', 'post'}しか想定していないので注意
if strcmp(test_type, 'comprehensive_test') && display_cosine_distance
    cosine_distance_figure_name = 'cosine_distance_plot';
    x_labels = arrayfun(@(i) sprintf('synergy%d', i), 1:synergy_num, 'UniformOutput', false);
    x_labels = categorical(x_labels);
    zeroBar = zeros(synergy_num,1);

    figure('position', [100, 100, 800, 800])
    hold on;
    for synergy_id = 1:synergy_num
        subplot(synergy_num, 1, synergy_id)
        bar(x_labels, [zeroBar all_cosine_distance_list{synergy_id}],'b','EdgeColor','none');

        % decoration
        ylim([0 1]);
        title(['vs pre-synergy' num2str(synergy_id)]);
        ylabel('cosine distance');
        set(gca, 'FontSize', 15);
    end
    
    % whole title
    sgtitle('Cosine distance (each control synergy VS all post synergy)', fontsize=20);
    hold off

    % save settingv
    saveas(gcf, fullfile(save_fold_path, [cosine_distance_figure_name '.fig']));
    saveas(gcf, fullfile(save_fold_path, [cosine_distance_figure_name '.png']));
    close all;
end

% (if test_type=='muscle-one-way-anova') create heatmap to display result
if exist("p_value_array_list", "var")
    p_value_data = cell2mat(p_value_array_list);
    customColormap = [1 1 1; 1 0 0]; % white, red
    [synergy_num, muscle_num] = size(p_value_data);
    ref_background_color = ones(synergy_num, muscle_num);
    ref_background_color(p_value_data < significant_level_threshold) = 2;
    x_labels = cellstr(ref_structure.x);
    y_labels = arrayfun(@(i) sprintf('synergy%d', i), 1:synergy_num, 'UniformOutput', false);
    title_str = sprintf(['one-way anova result(for each muscle, α = ' num2str(significant_level_threshold) ')']);
    save_file_name = 'one-way_anova_result(for_each_muscle)';
    
    % create annotatedHeatmap
    CreateAnnotatedHeatmap(customColormap, p_value_data, ref_background_color, x_labels, y_labels, title_str, save_fold_path, save_file_name)
end