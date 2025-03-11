
%{
explanation of this func:
This function is used in 'compileSynergyData.m'.
Plot the results of the synergy analysis (temporal pattern, spatial pattern, VAF, etc.), focusing on the number of synergies in 'synergy_num' for the date specified in 'unique_name'.

input arguments:
unique_name: [char], prefix & date (ex.) 'F170516'
synergy_num: [double], number of synergies to focus on
nmf_fold_name: [char], 
each_plot_flag: [bool], Parameter for changing the layout of diagram.
save_setting:[struct], structure containing parameters for whether the output diagram should be saved or not.
base_dir_path: [char], base path for specifying folder path. (basically, this is correspond to monkey_prefix folder)

output arguments:

[Improvement point]
全体的に冗長
・stackの図とstdの図のplotの被っているところ
・セーブセクションの被っているところ
・loadした時にtestが上書きされてしまうので、構造体に保存して区別するべき
・構造を根本的に変えたが、fullの処理を更新してない(多分動かない)
・図のsgtitleに、cutout_EMG_typeの情報(only_taskとか、fullとか)を追加した方がいいかも
・flag系はいらないかも.(強いて言えばeach_plot_flagがいるくらい? コード冗長になるし、引数多すぎて見辛い原因になるので)
%}

function plotSynergyAll_uchida(base_dir_path, extracted_synergy_data_dir, synergy_detail_data_dir, cutout_EMG_type, unique_name, synergy_num, each_plot_flag, save_setting, plot_clustering_flag, select_synergy_num_type)
%% set para & get nmf result
% load file
if not(exist(extracted_synergy_data_dir, "dir"))
    error('synergy_files are not found. Please run "makeEMFNMF_btcOya.m" first');
else
    % load the data of extracted synergy and the detail information of synergy_analysis
    extracted_synergy_file_path = fullfile(extracted_synergy_data_dir, unique_name, ['t_' unique_name '.mat']);
    synergy_detail_file_path = fullfile(synergy_detail_data_dir, unique_name, [unique_name '.mat']);
    extracted_synergy_data_struct = load(extracted_synergy_file_path);
    all_W_data = extracted_synergy_data_struct.test.W;
    all_H_data = extracted_synergy_data_struct.test.H;
    try
        use_EMG_type = extracted_synergy_data_struct.use_EMG_type;
    catch
        use_EMG_type = 'trimmed';
    end
    synergy_detail_struct = load(synergy_detail_file_path);
    TargetName = synergy_detail_struct.TargetName;
end

% get the number of EMG and muscle name
EMG_num = length(TargetName);
EMG_name_list = get_EMG_name(TargetName);

% get parameters
segment_num = size(all_W_data, 2);
save_fig_W = save_setting.save_fig_W;
save_fig_H = save_setting.save_fig_H;
save_fig_r2 = save_setting.save_fig_r2; 
save_data = save_setting.save_data;

%% sort synergies extracted from each test data and group them by synergies of similar characteristics
W_data = all_W_data(synergy_num, :);
common_save_figure_dir = fullfile(strrep(base_dir_path, 'data', 'figure'), 'daily_synergy_analysis_results', unique_name, ['synergy_num==' num2str(synergy_num)], cutout_EMG_type);
makefold(common_save_figure_dir);
if plot_clustering_flag == 1
    [Wt, k_arr] = OrderSynergy(synergy_num, W_data, segment_num, 1, common_save_figure_dir, unique_name);
else
    [Wt, k_arr] = OrderSynergy(synergy_num, W_data, segment_num, 0);
end

% if difference are found between segments
if isempty(k_arr)
    warning(['The ' num2str(segment_num) ' segments in the "' unique_name '" data were inconsistent when the number of synergies is ' num2str(synergy_num) '.'])
    return;
end

%% plot W (spatial pattern)
figure('Position',[0,1000,800,1300]);
x = categorical(EMG_name_list');
zeroBar = zeros(EMG_num,1);
aveW = zeros(EMG_num,synergy_num);
std_value = cell(1, synergy_num);

% make coefficient matrix for normalizing W(making it a unit vector)
Wt_coefficient_matrix = cell(size(Wt));
normalized_Wt = cell(size(Wt));
for session_id = 1:length(Wt)
    ref_session_Wt = Wt{session_id};
    [~, synergy_num] = size(ref_session_Wt);
    normalized_Wt{session_id} = zeros(size(ref_session_Wt));
    Wt_coefficient_matrix{session_id} = zeros(1, synergy_num);
    for synergy_id = 1:synergy_num
        ref_W = ref_session_Wt(:, synergy_id);
        W_coefficient = norm(ref_W);
        Wt_coefficient_matrix{session_id}(synergy_id) = W_coefficient;
        normalized_Wt{session_id}(:, synergy_id) = ref_W / W_coefficient;
    end
end


% subplot for each synergy
for synergy_id = 1:synergy_num
    % organize value to be plotted
    plotted_W = nan(EMG_num, segment_num);
    for segment_id = 1:segment_num
        plotted_W(:, segment_id) = normalized_Wt{segment_id}(:, synergy_id);
    end
    
    % calc the mean value of test data
    temp = mean(plotted_W, 2);
    ave_normalized_W = temp / norm(temp);
    aveW(:, synergy_id) = ave_normalized_W;
    std_value{1,synergy_id} = std(plotted_W, 0, 2);

    % barplot
    subplot(synergy_num,1,synergy_id); 
    bar(x,[zeroBar plotted_W]);

    % decoration
    ylim([0 1]);
    title(['Synergy' num2str(synergy_id)]);
    set(gca, fontsize=15)
end
sgtitle([unique_name ' synergyNum==' sprintf('%d', synergy_num)], fontSize=20);

%% save figure & data about W (temporal pattern of synergy)
common_save_data_dir = strrep(common_save_figure_dir, 'figure', 'data');
makefold(common_save_data_dir);
if save_data == 1
    save_W_data_fold_path = fullfile(common_save_data_dir, 'W_data');
    makefold(save_W_data_fold_path);
    save(fullfile(save_W_data_fold_path, 'mean_W_data.mat'), 'Wt_coefficient_matrix', 'aveW','k_arr','synergy_num','unique_name');
end

% save figure
if save_fig_W ==1
    save_W_figure_fold_path = fullfile(common_save_figure_dir, 'W_figure');
    makefold(save_W_figure_fold_path);
    saveas(gcf, fullfile(save_W_figure_fold_path, ['W_figure(segment==' num2str(segment_num) ').fig']));
    saveas(gcf, fullfile(save_W_figure_fold_path, ['W_figure(segment==' num2str(segment_num) ').png']));
end
close all;

%% plot aveW
figure('Position',[0,1000,800,1700]);
for synergy_id = 1:synergy_num
    subplot(synergy_num,1,synergy_id); 

    % barplot
    bar(x,aveW(:,synergy_id))
    hold on

    % add error bar
    er = errorbar(x,aveW(:,synergy_id),std_value{synergy_id},std_value{synergy_id});
    er.Color = [0 0 0];
    er.LineStyle = 'none';

    % decoration
    ylim([0 1]);
    title(['Synergy' num2str(synergy_id)]);
    set(gca, fontsize=15)
end
sgtitle([unique_name ' synergyNum==' sprintf('%d', synergy_num)], fontSize=20);

% save figure
if save_fig_W ==1
    saveas(gcf, fullfile(save_W_figure_fold_path, ['mean_W_figure(segment==' num2str(segment_num) ').fig']));
    saveas(gcf, fullfile(save_W_figure_fold_path, ['mean_W_figure(segment==' num2str(segment_num) ').png']));
end
close all;

if each_plot_flag == true
    for synergy_id = 1:synergy_num
        figure('Position',[0,1000,600,400]);

        % bar plot
        bar(x,aveW(:,synergy_id))
        hold on

        % add error bar
        er = errorbar(x,aveW(:,synergy_id),std_value{synergy_id},std_value{synergy_id});
        er.Color = [0 0 0];
        er.LineStyle = 'none';

        % decoration
        ylim([0 1]);
        title([unique_name '-mean spatial pattern - synergy num = ' sprintf('%d', synergy_num) '-synergy' num2str(synergy_id)], fontSize=15);

        % save figure
        if save_fig_W ==1
            saveas(gcf, fullfile(save_W_figure_fold_path, ['each_mean_W_figure(synergy' num2str(synergy_id) ')(segment==' num2str(segment_num) ').fig']));
            saveas(gcf, fullfile(save_W_figure_fold_path, ['each_mean_W_figure(synergy' num2str(synergy_id) ')(segment==' num2str(segment_num) ').png']));
        end
        close all;
    end
end

%% plot H (temporal pattern of synergy)
% load timing data (which is created by )
EMG_data_dir = strrep(base_dir_path, 'Synergy', 'EMG_ECoG');
cutout_EMG_data_file_path = fullfile(EMG_data_dir, 'cutout_EMG_data', [unique_name '_cutout_EMG_data.mat']);

switch use_EMG_type
    % 'fullの対応まだしてない'
    case 'full'
        try
            load(cutout_EMG_data_file_path, 'transposed_success_timing', 'common_sample_rate');
        catch
            stack = dbstack;
            disp(['(Error occured: line ' num2str(stack(1).line + 1) ') EasyData(' easyData_file_path ') is not found. Please run "prepareEMGAndTimingData.m" first!']);
            return;
        end
        SUC_Timing_A = floor(transposed_success_timing.*(100/common_sample_rate));

    case 'trimmed'
        load(fullfile(synergy_detail_data_dir, unique_name, [unique_name '.mat']), 'event_timings_after_trimmed');
        SUC_Timing_A = event_timings_after_trimmed;
end
SUC_num = length(SUC_Timing_A(:, 1));

% concatenate all test data to create a temporal pattern of synergy in the entire recording interval (as All_H)
H_data = all_H_data(synergy_num, :);
All_H = cell(1, segment_num);
for segment_id = 1:segment_num
    ref_segment_sort_order = k_arr(:, segment_id);
    for jj = 1:length(ref_segment_sort_order)
        sort_id = ref_segment_sort_order(jj);
        All_H{segment_id}(jj, :) = H_data{segment_id}(sort_id, :) * Wt_coefficient_matrix{segment_id}(jj);
    end
end
All_H = cell2mat(All_H);

% 正味ここのプロットいらんかも
% plot the activity pattern for each trial, focusing on the timing of 'task_start'
TIMEr = [0 200]; %range of cutting out(sample num)
TIMEl = abs(TIMEr(1))+abs(TIMEr(2))+1; % number of samples to be cut out
aveH = zeros(synergy_num, TIMEl);

monkey_prefix = unique_name(isletter(unique_name));
switch monkey_prefix
    case 'Hu'
        start_timing_id = 1;
    case {'F', 'Ya'}
        start_timing_id = 2;
end

figure('Position',[900,1000,800,1300]);
% each synergy
for synergy_id = 1:synergy_num
    subplot(synergy_num, 1, synergy_id);
    for trial_id=1:SUC_num
        cutout_start_timing = SUC_Timing_A(trial_id, start_timing_id) + TIMEr(1);
        cutout_end_timing = SUC_Timing_A(trial_id, start_timing_id)+TIMEr(2);
        
        % 最初 or 最後の試行で範囲を超えてしまった時
        try
            ref_trial_activity_pattern = All_H(synergy_id,  cutout_start_timing: cutout_end_timing);
        catch
            continue;
        end
        
        % plot each trial temporal data (around 'lever1 off' timing)
        plot(ref_trial_activity_pattern, LineWidth=1.2);
        hold on;

        % update averarge value up to the current trial
        aveH(synergy_id, :) = ((aveH(synergy_id, :) .* (trial_id - 1)) + ref_trial_activity_pattern) ./ trial_id ;
    end

    % decoration
    ylim([0 20]);
    xlabel('elapsed sample num');
    ylabel('coefficient');
    grid on;
    title(['Synergy' num2str(synergy_id)]);
    set(gca, fontsize=15)
end
sgtitle([unique_name ' synergyNum==' num2str(synergy_num)], fontsize=20);
hold off;

% save figure
if save_fig_H ==1
    save_H_figure_fold_path = strrep(save_W_figure_fold_path, 'W_figure', 'H_figure');
    makefold(save_H_figure_fold_path);
    saveas(gcf, fullfile(save_H_figure_fold_path, 'synergy_activity_pattern(stack).fig'));
    saveas(gcf, fullfile(save_H_figure_fold_path, 'synergy_activity_pattern(stack).png'));
end
close all;

%% save data about H (temporal pattern of synergy)
if save_data == 1
    save_H_data_fold_path = strrep(save_W_data_fold_path, 'W_data', 'H_data');
    makefold(save_H_data_fold_path);
    switch select_synergy_num_type
        case 'manual'
            save(fullfile(save_H_data_fold_path, 'mean_H_data.mat'), 'Wt_coefficient_matrix', 'aveH', 'k_arr', 'synergy_num', 'unique_name');
        case 'auto'
            % 確認してない．(そもそもこのswitch分がいらない気がする)
            save(fullfile(save_H_data_fold_path, [unique_name '_aveH3_appropriateNum.mat']), 'Wt_coefficient_matrix', 'aveH','k_arr','synergy_num','unique_name');
    end
end

% plot trial average value of temporal pattern for each synergy &
 figure('Position',[900,1000,800,1300]);
 for synergy_id=1:synergy_num
     subplot(synergy_num,1,synergy_id);
     plot(aveH(synergy_id,:), 'r', LineWidth=1.2);
     hold on;

     % decoration
     ylim([0 20]);
     xlabel('elapsed sample num');
     ylabel('coefficient');
     grid on;
     title(['Synergy' num2str(synergy_id)]);
     set(gca, fontsize=15)
 end
sgtitle([unique_name ' synergyNum==' num2str(synergy_num)], fontsize=20);
hold off

 % save figure (averarge of temporal pattern)
 if save_fig_H ==1
     saveas(gcf, fullfile(save_H_figure_fold_path, 'synergy_activity_pattern(mean).fig'));
     saveas(gcf, fullfile(save_H_figure_fold_path, 'synergy_activity_pattern(mean).png'));
 end
 close all;

%% plot & save VAF figure
figure;
VAF_data_struct = load(synergy_detail_file_path, 'test', 'shuffle');
real_VAF_for_each_segment = VAF_data_struct.test.r2;
shuffle_VAF_for_each_segment = VAF_data_struct.shuffle.r2;

% plot VAF
for segment_id= 1:segment_num
    real_VAF = real_VAF_for_each_segment(:, segment_id);
    shuffle_VAF = shuffle_VAF_for_each_segment(:, segment_id);

    plot(real_VAF, LineWidth=1.2);
    hold on;
    plot(shuffle_VAF, 'Color',[0,0,0], LineWidth=1.2);
end

% draw a line indicating the threshold
plot([0 EMG_num + 1], [0.8 0.8], LineWidth=1.2);

% decoration
grid on;
ylim([0 1]);
xlim([0 EMG_num])
xlabel('number of syenrgy')
ylabel('VAF');
set(gca, fontsize=15)
title([unique_name ' VAF'], FontSize=20);
hold off;

% save VAF figure
if save_fig_r2 ==1
    unique_dir_path = fileparts(fileparts(fileparts(save_H_figure_fold_path)));
    save_VAF_figure_fold_path = fullfile(unique_dir_path, 'VAF_result', cutout_EMG_type);
    makefold(save_VAF_figure_fold_path)
    saveas(gcf, fullfile(save_VAF_figure_fold_path, 'VAF_result.png'));
    saveas(gcf, fullfile(save_VAF_figure_fold_path, 'VAF_result.fig'));
    close all;
end
end

