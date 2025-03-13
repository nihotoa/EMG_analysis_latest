%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code

[role of this code]

[Saved figure location]

[procedure]
pre: synergyExtractionByNMF.m
post: compileSynergyData.m

[Improvement points(Japanase)]
+ 使用した筋電の数を考慮する必要があるので、ディレクトリをもう一階層追加する
+ dVAFを使用したシナジー数の候補の決定において、検定のデータが選択実験日ごとに変わるので固定する
+ TT_surgery_dayを手動で決めているけど、サルによって固定なので、それ用の関数を作る
+ 序盤でシナジーデータがなかった日付のデータをeliminated_date_listを使って取り除く処理をしているが、分かりにくいかつ冗長なので抜本的に変える

[shared information]
・t-testによってshuffleデータのdVAFが実際のデータのdVAFよりも有意に大きいかどうか調べているが、これが適切な方法か自信がない
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
term_select_type = 'manual'; %'auto' / 'manual'
period_type = 'pre'; %(if term_select_type == 'auto') pre / post / all 
use_EMG_type = 'only_trial'; %' full' / 'only_trial'
monkey_prefix = 'Hu';
use_style = 'test'; % test/train
first_judge_type = 'dVAF'; % 'VAF' / 'dVAF'
VAF_threshold = 0.8; % param to draw threshold_line
coffen_coefficient_threshold = 0.95;
font_size = 20; % Font size of text in the figure
significant_level = 0.01;
TT_surgery_day = 20250120;
make_figure_flag = true;

%% code section
% get date_list by GUI operation
full_monkey_name = getFullMonkeyName(monkey_prefix);
root_dir_path = fileparts(pwd);
base_dir_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'Synergy');
synergy_detail_data_dir = fullfile(base_dir_path, 'synergy_detail', use_EMG_type);
extracted_synergy_data_dir = fullfile(base_dir_path, 'extracted_synergy', use_EMG_type);
selected_file_name_list = getGroupedDates(synergy_detail_data_dir, monkey_prefix, term_select_type, period_type);
if isempty(selected_file_name_list)
    disp('user pressed "cancel" button');
    return;
end

date_list = strrep(selected_file_name_list, monkey_prefix, '');
date_num = length(selected_file_name_list);

% load (or crate) data about optimal number of synergy
save_data_fold_path = fullfile(base_dir_path, 'optimal_synergy_num_data', first_judge_type, use_EMG_type);
save_data_file_name = ['optimal_synergy_num_data(' selected_file_name_list{1} '_to_' selected_file_name_list{end} '_' num2str(length(selected_file_name_list)) ').mat'];

if not(exist(fullfile(save_data_fold_path, save_data_file_name), "file"))
    % some dates may not have synergy data files, so the method of appending to an empty cell array is adopted
    VAF_data_list = {};
    shuffle_VAF_data_list = {};
    spatial_pattern_data_list = {};
    eliminated_date_list = {};
    date_num = length(selected_file_name_list);
    
    for day_id = 1:date_num
        unique_name = selected_file_name_list{day_id};
        VAF_data_path = fullfile(synergy_detail_data_dir, unique_name, [unique_name '.mat']);
        spatial_pattern_data_path = fullfile(extracted_synergy_data_dir, unique_name, ['t_' unique_name '.mat']);
    
        % load VAF data & synergy data
        try
            VAF_data = load(VAF_data_path);
            synergy_data = load(spatial_pattern_data_path);
        catch
            disp([unique_name ' have no synergy data']);
            eliminated_date_list{end+1} = unique_name;
            continue;
        end
    
        % calcurate the average value of VAF for all test (or train) data & shuffle data
        VAF_data_list{end+1} = VAF_data.(use_style).r2;
        shuffle_VAF_data_list{end+1} = VAF_data.shuffle.r2;
        spatial_pattern_data_list{end+1} = synergy_data.(use_style).W;
        if day_id == 1
            [muscle_num, segment_num] = size(synergy_data.(use_style).W);
        end
    end
    
    shuffle_VAF_data_list = cell2mat(shuffle_VAF_data_list);
    
    % update the list of sessions with reference to eliminated_date_list
    selected_file_name_list = setdiff(selected_file_name_list, eliminated_date_list);
    date_list = strrep(selected_file_name_list, monkey_prefix, '');
    date_num = length(selected_file_name_list);
    
    %% output optimal number of synergy for each session
    % create strucutre to store optimal synergy number
    optimal_synergy_num_struct = struct();
    
    for day_id = 1:date_num
        ref_VAF_data = VAF_data_list{day_id};
        ref_spatial_pattern_data = spatial_pattern_data_list{day_id};
        
        % find candidate of optimal number of synergy by refer VAF value
        switch first_judge_type
            case 'VAF'
                optimal_synergy_num_candidate_list = zeros(1, segment_num);
                for segment_id = 1:segment_num
                    optimal_synergy_num_candidate_list(1, segment_id) = find(ref_VAF_data(:, segment_id) > VAF_threshold, 1);
                end
                optimal_synergy_num_candidate = round(mean(optimal_synergy_num_candidate_list));
            case 'dVAF'
                dVAF_list = diff(ref_VAF_data, 1);
                shuffle_dVAF_data_list = diff(shuffle_VAF_data_list,1);
    
                % shuffle_dataのdVAFが実際のデータのdVAFのデータよりも有意に大きいかどうか判定する。
                optimal_synergy_num_candidate = 1;
                for dsynergy_id = 1: (muscle_num - 1)
                    ref_num_shuffle_dVAF_datas = shuffle_dVAF_data_list(dsynergy_id, :);
                    shuffle_mean_population = mean(ref_num_shuffle_dVAF_datas);
                    ref_num_dVAFs = dVAF_list(dsynergy_id, :);
    
                    % check if 'ref_num_dVAFs' is significantly less than 'shuffle_mean_population' by t-test
                    [isSignificant, p_value] = ttest(ref_num_dVAFs, shuffle_mean_population, significant_level, 'left');
                    if not(isSignificant)
                        optimal_synergy_num_candidate = optimal_synergy_num_candidate + 1;
                    else
                        break;
                    end
                end            
        end
    
        % decide optimal number of synergy by refer the result of hierarcical clustering
        candidate_synergy_spatial_pattern = ref_spatial_pattern_data(optimal_synergy_num_candidate, :);
        W_data = cell2mat(candidate_synergy_spatial_pattern);
        [~, condition_num] = size(W_data);
        cosine_distance_matrix = PerformCosineDistanceAnalysis(condition_num, W_data, 0);
        [~, k_arr, coffen_coefficient] = PerformClustering(condition_num, cosine_distance_matrix, optimal_synergy_num_candidate, segment_num, 0);
        
        % if differences are found between segments(if multipe synergy from same session between same cluster)
        if isempty(k_arr)
            % the clustering is not working well, the coefficient treated as 0
            coffen_coefficient = 0;
        end
    
        if coffen_coefficient > coffen_coefficient_threshold
            % store the data in the structure
            optimal_synergy_num_struct.([monkey_prefix date_list{day_id}]).VAF_cc = coffen_coefficient;
            optimal_synergy_num_struct.([monkey_prefix date_list{day_id}]).optimal_synergy_num = optimal_synergy_num_candidate;
            optimal_synergy_num_struct.([monkey_prefix date_list{day_id}]).best_cc =  coffen_coefficient;
        else
            candidate_synergy_num_list = [optimal_synergy_num_candidate - 1, optimal_synergy_num_candidate, optimal_synergy_num_candidate+1];
            coffen_coefficient_list = zeros(1, 3);
            coffen_coefficient_list(2) = coffen_coefficient;
            for candidate_synergy_id = 1:2:3
                candidate_synergy_num = candidate_synergy_num_list(candidate_synergy_id);
    
                candidate_synergy_spatial_pattern = ref_spatial_pattern_data(candidate_synergy_num, :);
                W_data = cell2mat(candidate_synergy_spatial_pattern);
                [~, condition_num] = size(W_data);
                cosine_distance_matrix = PerformCosineDistanceAnalysis(condition_num, W_data, 0);
                [~, k_arr, coffen_coefficient] = PerformClustering(condition_num, cosine_distance_matrix, candidate_synergy_num, segment_num, 0);
                if isempty(k_arr)
                    % the clustering is not working well, the coefficient treated as 0
                    coffen_coefficient = 0;
                end
                coffen_coefficient_list(candidate_synergy_id) = coffen_coefficient;
            end
            [best_cc_value, best_cc_value_idx] = max(coffen_coefficient_list); 
            if best_cc_value > coffen_coefficient_threshold
                optimal_synergy_num = candidate_synergy_num_list(best_cc_value_idx);
        
                % store the data in the structure
                optimal_synergy_num_struct.([monkey_prefix date_list{day_id}]).optimal_synergy_num = optimal_synergy_num;
                optimal_synergy_num_struct.([monkey_prefix date_list{day_id}]).VAF_cc = coffen_coefficient_list(2);
                optimal_synergy_num_struct.([monkey_prefix date_list{day_id}]).best_cc =  best_cc_value;
            else
                % if the optimal number of synergy can not be found even though using this method
                % store the data in the structure
                optimal_synergy_num_struct.([monkey_prefix date_list{day_id}]).optimal_synergy_num = NaN;
                optimal_synergy_num_struct.([monkey_prefix date_list{day_id}]).VAF_cc = NaN;
                optimal_synergy_num_struct.([monkey_prefix date_list{day_id}]).best_cc =  NaN;
            end
        end
    end
    
    optimal_synergyNum_list = extractOptimalSynergyNum(optimal_synergy_num_struct, 'optimal_synergy_num');
    VAF_cc_list = extractOptimalSynergyNum(optimal_synergy_num_struct, 'VAF_cc');
    best_cc_list = extractOptimalSynergyNum(optimal_synergy_num_struct, 'best_cc');
    
    % save setting of optimal_synergy_num_struct
    makefold(save_data_fold_path)
    save(fullfile(save_data_fold_path, save_data_file_name), 'optimal_synergy_num_struct', 'VAF_cc_list', 'best_cc_list', 'optimal_synergyNum_list', 'muscle_num');
else
    load(fullfile(save_data_fold_path, save_data_file_name), 'optimal_synergyNum_list', 'muscle_num');
end

%% plot result
if make_figure_flag
    elapsed_day_list = makeElapsedDateList(date_list, TT_surgery_day);
    
    figure();
    hold on;
    plot(elapsed_day_list, optimal_synergyNum_list, 'o', LineWidth=2, MarkerEdgeColor='blue', MarkerFaceColor='blue');
    plot(elapsed_day_list, optimal_synergyNum_list, LineWidth=2);
    
    elapsed_first = 0;
    if any(elapsed_day_list < 0)
        elapsed_first = elapsed_day_list(1);
        elapsed_post_first = elapsed_day_list(find(elapsed_day_list > 0, 1));
        rectangle('Position', [0 0, elapsed_post_first - 1, muscle_num], 'FaceColor',[1, 1, 1], 'EdgeColor', 'K', 'LineWidth',1.2);
    end
    
    % decoration
    grid on;
    xlim([elapsed_first elapsed_day_list(end)]);
    ylim([0 muscle_num]);
    set(gca, FontSize=15)
    
    ylabel('optimal number of syenrgy');
    xlabel('elapsed date since recoring begin')
    
    % save setting
    save_figure_fold_path = strrep(save_data_fold_path, 'data', 'figure');
    save_figure_file_name = ['optimal_synergy_num_' date_list{1} '_to_' date_list{end} '_' num2str(date_num)];
    
    makefold(save_figure_fold_path);
    
    saveas(gcf, fullfile(save_figure_fold_path, [save_figure_file_name '.png']))
    saveas(gcf, fullfile(save_figure_fold_path, [save_figure_file_name '.fig']))
    disp(['figure is saved in:' save_figure_fold_path])
    close all;
end