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

[shared information]
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
term_type = 'all'; %pre / post / all 
monkeyname = 'Ni';
use_style = 'test'; % test/train
VAF_plot_type = 'stack'; %'stack' or 'mean'
VAF_threshold = 0.8; % param to draw threshold_line
coffen_coefficient_threshold = 0.95;
font_size = 20; % Font size of text in the figure
nmf_fold_name = 'new_nmf_result'; % name of nmf folder

%% code section
[realname] = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname, nmf_fold_name);

% Create a list of folders containing the synergy data for each date.
data_folders = dir(base_dir);
folderList = {data_folders([data_folders.isdir]).name};
Allfiles_S = folderList(startsWith(folderList, monkeyname));

% Further refinement by term_type
switch monkeyname
    case {'Ya', 'F'}
        TT_day = '20170530';
    case 'Ni'
        TT_day = '20220530';
end

[prev_last_idx, post_first_idx] = get_term_id(Allfiles_S, 1, TT_day);

switch term_type
    case 'pre'
        Allfiles_S = Allfiles_S(1:prev_last_idx);
    case 'post'
        Allfiles_S = Allfiles_S(post_first_idx:end);
    case 'all'
        % no processing
end

Allfiles = strrep(Allfiles_S, '_standard','');
AllDays = strrep(Allfiles, monkeyname, '');
day_num = length(Allfiles_S);

% create the data array of VAF & date array of spatial pattern
% some dates may not have synergy data files, so the method of appending to an empty cell array is adopted
VAF_data_list = {};
spatial_pattern_data_list = {};
eliminated_date_list = {};

for day_id = 1:day_num
    VAF_data_path = fullfile(base_dir, Allfiles_S{day_id}, [Allfiles_S{day_id} '.mat']);
    spatial_pattern_data_path = fullfile(base_dir, Allfiles_S{day_id}, ['t_' Allfiles_S{day_id} '.mat']);

    % load VAF data & synergy data
    try
        VAF_data = load(VAF_data_path, use_style);
        synergy_data = load(spatial_pattern_data_path, use_style);
    catch
        disp([Allfiles_S{day_id} ' have no synergy data']);
        eliminated_date_list{end+1} = Allfiles_S{day_id};
        continue;
    end

    % calcurate the average value of VAF for all test (or train) data & shuffle data
    VAF_data_list{end+1} = mean(VAF_data.(use_style).r2, 2);
    spatial_pattern_data_list{end+1} = synergy_data.(use_style).W;
    if day_id == 1
        [muscle_num, kf] = size(synergy_data.(use_style).W);
    end
end
VAF_data_list = cell2mat(VAF_data_list);

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
    optimal_synergy_num_candidate = find(ref_VAF_data > VAF_threshold, 1);

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
        optimal_synergy_num_struct.([monkeyname AllDays{day_id}]).optimal_synergy_num = optimal_synergy_num_candidate;
        optimal_synergy_num_struct.([monkeyname AllDays{day_id}]).VAF_cc = coffen_coefficient;
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

