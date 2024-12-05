%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code

[role of this code]

[Saved figure location]

[procedure]
pre: makeEMGNMF_btcOya.m
post: SYNERGYPLOT.m

[Improvement points(Japanaese)]
・シナジーのクラスタリング処理が何回かあるが、その度に処理をコピペしていて冗長なので、関数にする。

[shared information]
・t-testによってshuffleデータのdVAFが実際のデータのdVAFよりも有意に大きいかどうか調べているが、正規分布とは限らないので
t-testを使用していいのかどうかは自信がない。(ノンパラメトリックな検定方法を使うべきかも)

・1日しか選択肢ないと、t-testに使うサンプル数が1になってttest関数でエラー吐くので修正する
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
term_select_type = 'manual'; %'auto' / 'manual'
term_type = 'pre'; %(if term_select_type == 'auto') pre / post / all 
monkeyname = 'Hu';
use_style = 'test'; % test/train
first_judge_type = 'dVAF'; % 'VAF' / 'dVAF'
VAF_threshold = 0.8; % param to draw threshold_line
coffen_coefficient_threshold = 0.95;
font_size = 20; % Font size of text in the figure
nmf_fold_name = 'new_nmf_result'; % name of nmf folder

%% code section
realname = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname, nmf_fold_name);
Allfiles_S = getGroupedDates(base_dir, monkeyname, term_select_type, term_type);
if isempty(Allfiles_S)
    disp('user pressed "cancel" button');
    return;
end

% create the data array of VAF & date array of spatial pattern
% some dates may not have synergy data files, so the method of appending to an empty cell array is adopted
VAF_data_list = {};
shuffle_VAF_data_list = {};
spatial_pattern_data_list = {};
eliminated_date_list = {};
day_num = length(Allfiles_S);

for day_id = 1:day_num
    VAF_data_path = fullfile(base_dir, Allfiles_S{day_id}, [Allfiles_S{day_id} '.mat']);
    spatial_pattern_data_path = fullfile(base_dir, Allfiles_S{day_id}, ['t_' Allfiles_S{day_id} '.mat']);

    % load VAF data & synergy data
    try
        VAF_data = load(VAF_data_path);
        synergy_data = load(spatial_pattern_data_path);
    catch
        disp([Allfiles_S{day_id} ' have no synergy data']);
        eliminated_date_list{end+1} = Allfiles_S{day_id};
        continue;
    end

    % calcurate the average value of VAF for all test (or train) data & shuffle data
    VAF_data_list{end+1} = mean(VAF_data.(use_style).r2, 2);
    shuffle_VAF_data_list{end+1} = mean(VAF_data.shuffle.r2, 2);
    spatial_pattern_data_list{end+1} = synergy_data.(use_style).W;
    if day_id == 1
        [muscle_num, kf] = size(synergy_data.(use_style).W);
    end
end
VAF_data_list = cell2mat(VAF_data_list);
shuffle_VAF_data_list = cell2mat(shuffle_VAF_data_list);

% update the list of sessions with reference to eliminated_date_list
Allfiles_S = setdiff(Allfiles_S, eliminated_date_list);
Allfiles = strrep(Allfiles_S, '_standard','');
AllDays = strrep(Allfiles, monkeyname, '');
day_num = length(Allfiles_S);

%% output optimal number of synergy for each session
% create strucutre to store optimal synergy number
optimal_synergy_num_struct = struct();

for day_id = 1:day_num
    ref_VAF_data = VAF_data_list(:, day_id);
    ref_spatial_pattern_data = spatial_pattern_data_list{day_id};
    
    % find candidate of optimal number of synergy by refer VAF value
    switch first_judge_type
        case 'VAF'
            optimal_synergy_num_candidate = find(ref_VAF_data > VAF_threshold, 1);
        case 'dVAF'
            dVAF_list = diff(ref_VAF_data, 1);
            shuffle_dVAF_data_list = diff(shuffle_VAF_data_list,1);

            % shuffle_dataのdVAFが実際のデータのdVAFのデータよりも有意に大きいかどうか判定する。
            optimal_synergy_num_candidate = 1;
            for dsynergy_id = 1: (muscle_num - 1)
                ref_num_shuffle_dVAF_datas = shuffle_dVAF_data_list(dsynergy_id, :);
                ref_dVAF = dVAF_list(dsynergy_id);

                % check if 'ref_num_shuffle_dVAF_datas' is significantly greater than 'ref_dVAF' by t-test
                [isSignificant, p_value] = ttest(ref_num_shuffle_dVAF_datas, ref_dVAF, 0.05, 'right');
                if not(isSignificant)
                    optimal_synergy_num_candidate = optimal_synergy_num_candidate + 1;
                else
                    break;
                end
            end
            a = 1;
    end

    % decide optimal number of synergy by refer the result of hierarcical clustering
    candidate_synergy_spatial_pattern = ref_spatial_pattern_data(optimal_synergy_num_candidate, :);
    W_data = cell2mat(candidate_synergy_spatial_pattern);
    [~, condition_num] = size(W_data);
    cosine_distance_matrix = PerformCosineDistanceAnalysis(condition_num, W_data, 0);
    [~, k_arr, coffen_coefficient] = PerformClustering(condition_num, cosine_distance_matrix, optimal_synergy_num_candidate, kf, 0);
    
    % if differences are found between segments(if multipe synergy from same session between same cluster)
    if isempty(k_arr)
        % the clustering is not working well, the coefficient treated as 0
        coffen_coefficient = 0;
    end

    if coffen_coefficient > coffen_coefficient_threshold
        % store the data in the structure
        optimal_synergy_num_struct.([monkeyname AllDays{day_id}]).VAF_cc = coffen_coefficient;
        optimal_synergy_num_struct.([monkeyname AllDays{day_id}]).optimal_synergy_num = optimal_synergy_num_candidate;
        optimal_synergy_num_struct.([monkeyname AllDays{day_id}]).best_cc =  coffen_coefficient;
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
            [~, k_arr, coffen_coefficient] = PerformClustering(condition_num, cosine_distance_matrix, candidate_synergy_num, kf, 0);
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
            optimal_synergy_num_struct.([monkeyname AllDays{day_id}]).optimal_synergy_num = optimal_synergy_num;
            optimal_synergy_num_struct.([monkeyname AllDays{day_id}]).VAF_cc = coffen_coefficient_list(2);
            optimal_synergy_num_struct.([monkeyname AllDays{day_id}]).best_cc =  best_cc_value;
        else
            % if the optimal number of synergy can not be found even though using this method
            % store the data in the structure
            optimal_synergy_num_struct.([monkeyname AllDays{day_id}]).optimal_synergy_num = NaN;
            optimal_synergy_num_struct.([monkeyname AllDays{day_id}]).VAF_cc = NaN;
            optimal_synergy_num_struct.([monkeyname AllDays{day_id}]).best_cc =  NaN;
        end
    end
end

optimal_synergyNum_list = extractOptimalSynergyNum(optimal_synergy_num_struct, 'optimal_synergy_num');
VAF_cc_list = extractOptimalSynergyNum(optimal_synergy_num_struct, 'VAF_cc');
best_cc_list = extractOptimalSynergyNum(optimal_synergy_num_struct, 'best_cc');

% save setting of optimal_synergy_num_struct
save_file_path = fullfile(base_dir, 'optimal_synergy_num_data');
makefold(save_file_path)
save_file_name = ['optimal_synergy_num_data(' Allfiles{1} '_to_' Allfiles{end} '_' num2str(length(Allfiles)) ').mat'];
save(fullfile(save_file_path, save_file_name), 'optimal_synergy_num_struct', 'VAF_cc_list', 'best_cc_list', 'optimal_synergyNum_list');

