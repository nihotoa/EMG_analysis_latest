%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code

[role of this code]
�EOutput a single figure of the spatial pattern of each synergy for all dates selected by the UI operation.
�EStore data on the mapping of each synergy on each date and on the spatial pattern of synergies (synergy W) summarised.

[Saved data location]
    As for figure:
        Yachimun/new_nmf_result/syn_figures/F170516to170526_4/      (if you selected 'pre' for 'term_type')

    As for synergy order data:
        Yachimun/new_nmf_result/order_tim_list/F170516to170526_4/     (if you selected 'pre' for 'term_type')

    As for synergy W data (for anova):
        Yachimun/new_nmf_result/W_synergy_data/

    As for synergy W data:
        Yachimun/new_nmf_result/spatial_synergy_data/dist-dist/

[procedure]
pre: SYNERGYPLOT.m
post: (if you want to cutout temporal pattern of synergy)prepareSynergyTemporalData.m

[Improvement points(Japanaese)]
+ �g�p�����ؓd�̐����l������K�v������̂ŁA�f�B���N�g����������K�w�ǉ�����
+ �V�����\���ɂ����āAday_num > 1�̏ꍇ�̋������m���߂ĂȂ�
+ auto�̏�������
+ �V�i�W�[�̏��Ԃ������ɍ��킹��(pre��post�ŕς���Ă��܂��̂ŁA�ǂ̏������Q�Ƃ��邩���p�����[�^�Őݒ肷��('pre', 'post'))
+ VisualizeSynergyWeights�̃f�[�^�́A�I�����ꂽ�O���[�v���Ƃł͂Ȃ��A�e���t���ƂɃZ�[�u����

[caution]
�K�w�N���X�^�����O���s�������ɁA�S�ẴN���X�^�̗v�f������v���Ă��Ȃ��ꍇ�̓G���[�f���B
(�V�i�W�[�����ω����Ȃ� & �V�i�W�[�̍\�����ω����Ȃ��O��ō���Ă���)
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

%% set param
term_select_type = 'manual'; %'auto' / 'manual'
term_type = 'all'; %(if term_select_type == 'auto') pre / post / all 
use_EMG_type = 'only_task'; %' full' / 'only_task'
normalize_flag = true;
monkey_prefix = 'Hu';
syn_num = 4; % number of synergy you want to analyze
plot_clustering_result = 1; % whether to plot cosine distance & dendrogram of hierarcical clustering
save_WDaySynergy = 1;% Whether to save synergy W (to be used for ANOVA)
save_data = 1; % Whether to store data on synergy orders in 'order_tim_list' folder (should basically be set to 1).

%% code section
full_monkey_name = getFullMonkeyName(monkey_prefix);
root_dir = fileparts(pwd);
base_dir_path = fullfile(root_dir, 'saveFold', full_monkey_name, 'data', 'Synergy');
synergy_detail_data_dir = fullfile(base_dir_path, 'synergy_detail', use_EMG_type);
daily_synergy_data_dir = fullfile(base_dir_path, 'daily_synergy_analysis_results');

Allfiles_S = getGroupedDates(synergy_detail_data_dir, monkey_prefix, term_select_type, term_type);
if isempty(Allfiles_S)
    disp('user pressed "cancel" button');
    return;
end

% extract only date portion from 'Allfiles_S' and store it into a list
selected_days = get_days(Allfiles_S);
day_num = length(selected_days);
if and(strcmp(term_select_type, 'auto'), strcmp(term_type, 'post'))
    pre_file_list = getGroupedDates(base_dir_path, monkey_prefix, term_select_type, 'pre');
    pre_days = get_days(pre_file_list);
end

% make folder to save figures
common_save_figure_dir = strrep(base_dir_path, 'data', 'figure');
save_W_figure_dir_path = fullfile(common_save_figure_dir, 'synergy_across_sessions', use_EMG_type, ['synergy_num==' num2str(syn_num)], [monkey_prefix mat2str(selected_days(1)) 'to' mat2str(selected_days(end)) '_' sprintf('%d',day_num)], 'W_figures');
makefold(save_W_figure_dir_path);
save_heatmap_figure_dir_path = fullfile(common_save_figure_dir, 'synergy_across_sessions', use_EMG_type, ['synergy_num==' num2str(syn_num)], [monkey_prefix mat2str(selected_days(1)) 'to' mat2str(selected_days(end)) '_' sprintf('%d',day_num)], 'figures_for_sort');
makefold(save_heatmap_figure_dir_path);

%% Get the name of the EMG used for the synergy analysis
first_date_fold_name = Allfiles_S{1};

% Get the path of the file that has name information of EMG used for muscle synergy analysis
first_date_file_path = fullfile(synergy_detail_data_dir, first_date_fold_name, [first_date_fold_name '.mat']);

% get name information of EMG used for muscle synergy analysis
load(first_date_file_path, 'TargetName');
EMGs = get_EMG_name(TargetName);
EMG_num = length(EMGs);


%% Reorder the synergies to match the synergies on the first day.

% align the order of synergies
% 1. load W_data
if day_num > 1
    W_data = cell(1, day_num);
    for day_id = 1:day_num
        unique_name = Allfiles_S{day_id};
        synergy_W_file_path = fullfile(daily_synergy_data_dir, unique_name, ['synergy_num==' num2str(syn_num)], use_EMG_type, 'W_data', 'mean_W_data.mat');
        load(fullfile(synergy_W_file_path), 'aveW');
        if not(normalize_flag)  
            load(fullfile(synergy_W_file_path), 'Wt_coefficient_matrix');
            coefficinet_list = mean(cell2mat(cellfun(@(x) x(:), Wt_coefficient_matrix, 'UniformOutput', false)), 2)';
            aveW = aveW .* coefficinet_list;
        end
        W_data{day_id} = aveW;
        clear aveW;
    end
    
    term_unique_name = [monkey_prefix num2str(selected_days(1)) '-to-' monkey_prefix num2str(selected_days(end))];
    [Wt, k_arr] = OrderSynergy(syn_num, W_data, day_num, plot_clustering_result, save_heatmap_figure_dir_path, term_unique_name);
    %{
     %Seseki�p(0117, 0212, 0226, 0305, 0310, 0326)�Ȃ̂Ō�ŏ�����
     k_arr = [[1;2;3;4], [1;3;2;4], [1;4;3;2], [1;4;3;2], [1;3;2;4], [1;4;2;3]];
     for day_id = 1:day_num
        Wt{day_id} = W_data{day_id}(:, k_arr(:, day_id));
    end
    %}

    if isempty(k_arr)
        warning('We were unable to match all synergies. We recommend reducing the number of synergy');
        return; 
    end
else
    k_arr = transpose(1:syn_num);
    W_data =  cell(1,1);

    % Load the W synergy data created by SYNERGYPLOT
    synergy_W_file_path = fullfile(daily_synergy_data_dir, first_date_fold_name, ['synergy_num==' num2str(syn_num)], use_EMG_type, 'W_data', 'mean_W_data.mat');
    load(synergy_W_file_path, 'aveW');
    Wt{1} = aveW;
end

%{
if and(strcmp(term_select_type, 'auto'), strcmp(term_type, 'post'))
    % align the order of synergies with the 1st day of 'pre'
    compair_days = [pre_days(1); selected_days(1)];
    representative_data = cell(1, 2);
    for day_id = 1:2
        use_W_folder_path = fullfile(base_dir_path, [common_name '_standard'], [common_name '_syn_result_' num2str(EMG_num)], [common_name '_W']);
        use_W_file_name = [common_name '_aveW_' num2str(syn_num)];
        load(fullfile(use_W_folder_path, use_W_file_name), 'aveW');
        representative_data{day_id} = aveW;
        clear aveW;
    end
    [~, order_list] = OrderSynergy(EMG_num, syn_num, representative_data, monkey_prefix, compair_days, base_dir_path, plot_clustering_result);
    synergy_order = order_list(:, 2);

    % align with using 'synergy_order'
    k_arr = k_arr(synergy_order, :);
    Wt = cellfun(@(x) x(:, synergy_order), Wt, 'UniformOutput', false);
end
%}

% Expand Wt & rearrange columns
Walt = cell2mat(Wt);
Wall = Walt;
for synergy_id = 1:syn_num
    for day_id=1:day_num
        Wall(:,(synergy_id-1)*day_num+day_id) = Walt(:,(day_id-1)*syn_num+synergy_id);
    end
end

%% plot figure(Synergy_W)
% Organize the information needed for plot.
x = categorical(EMGs');
muscle_name = x; 
zeroBar = zeros(EMG_num,1);

for synergy_id=1:syn_num 
    ref_figure_obj = figure('Position',[300,250*synergy_id,750,400]);
    hold on;
    
    % create plotted_W
    plotted_W = nan(EMG_num, day_num);
    for day_id = 1:day_num
        plotted_W(:, day_id) = Wt{day_id}(:, synergy_id);
    end
    bar(x,[zeroBar plotted_W],'b','EdgeColor','none');

    % decoration
    ylim([0 1])
    a = gca;
    a.FontSize = 30;
    a.FontWeight = 'bold';
    a.FontName = 'Arial';

    % save setting
    save_figure_name = ['spatial_synergy(synergy' num2str(synergy_id) ')'];
    saveas(ref_figure_obj, fullfile(save_W_figure_dir_path, [save_figure_name '.fig']));
    saveas(ref_figure_obj, fullfile(save_W_figure_dir_path, [save_figure_name '.png']));
end
close all;

% make directory to save synergy_W data & save data.
if save_WDaySynergy == 1
    save_data_folder_path = strrep(save_W_figure_dir_path, 'figure', 'data');
    makefold(save_data_folder_path);
    
    % Changing the structure of an array
    WDaySynergy = cell(1, syn_num);
    for synergy_id = 1:syn_num
        for day_id = 1:day_num
            WDaySynergy{synergy_id}(:, day_id) = Wt{day_id}(:, synergy_id);
        end
    end
    
    % save_data
    data_file_name = 'spatial_synergies_data_for_xcorr_calcuration';
    save(fullfile(save_data_folder_path, data_file_name), 'WDaySynergy', 'x');
end

%% Plot the average value of synergy_W for all selected dates
aveWt = Wt{1};
% calcrate the average of synergy W
for day_id=1:day_num
    aveWt = (aveWt.*(day_id-1) + Wt{day_id})./day_id;
end

% plot figure of averarge synergyW
std_data_for_errobar = zeros(EMG_num,syn_num);
for synergy_id=1:syn_num
    ref_figure_obj = figure('Position',[900,250*synergy_id,750,400]);

    % Calculate standard deviation
    std_data_for_errobar(:,synergy_id) = std(Wall(:,(synergy_id-1)*day_num+1:synergy_id*day_num),1,2)./sqrt(day_num);

    % plot
    bar(x,aveWt(:,synergy_id));
    hold on;

    % decoration
    error_bar_obj =errorbar(x, aveWt(:,synergy_id), std_data_for_errobar(:,synergy_id), 'MarkerSize',1);
    ylim([-1 4])
    error_bar_obj.Color = 'r';
    error_bar_obj.LineWidth = 2;
    error_bar_obj.LineStyle = 'none';
    ylim([0 1]);
    a = gca;
    a.FontSize = 20;
    a.FontWeight = 'bold';
    a.FontName = 'Arial';
    
    % save figure
    save_figure_name = ['mean_spatial_synergy(synergy' num2str(synergy_id) ')'];
    saveas(ref_figure_obj, fullfile(save_W_figure_dir_path, [save_figure_name '.fig']));
    saveas(ref_figure_obj, fullfile(save_W_figure_dir_path, [save_figure_name '.png']));
end
close all;

%% save order for next phase analysis
if save_data == 1
    % save data of synergyW
    save_data_file_name = 'spatial_synergies_data';
    save(fullfile(save_data_folder_path, save_data_file_name),"Wt","muscle_name","selected_days")

    % save data which is related to the order of synergy
    file_name = 'sort_order_info';
    save(fullfile(fileparts(save_data_folder_path), [file_name '.mat']), 'k_arr', 'selected_days', 'EMG_num', 'syn_num');
end