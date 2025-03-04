%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code

[role of this code]
Visualize the VAF value of synergy obtained by NNMF and save it as a figure

[Saved figure location]
location: 
    EMG_analysis_tutorial/data/Yachimun/new_nmf_result/VAF_result/

[procedure]
pre: synergyExtractionByNMF.m
post: compileSynergyData.m

[Improvement points(Japanaese)]
+ 使用した筋電の数を考慮する必要があるので、ディレクトリをもう一階層追加する
・冗長 & 汚い、特にcolorbar_flag周りの処理。
・dVAFの処理を加えたが, colorbar_flagがtrueの時の動作確認はしてない
・visualizeEMGAndSynergyと同じように、preとpostでカラーバーの色変えたほうがいいかも
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
term_select_type = 'manual'; %'auto' / 'manual'
use_EMG_type = 'only_task'; %' full' / 'only_task'
term_type = 'post'; %(if term_select_type == 'auto') pre / post / all 
monkey_prefix = 'Hu';
use_style = 'test'; % test/train
figure_type = 'VAF'; % 'VAF'/ dVAF
VAF_plot_type = 'stack'; %'stack' or 'mean'
VAF_threshold = 0.8; % param to draw threshold_line
font_size = 20; % Font size of text in the figure
TT_day = 20250120;

%% code section
full_monkey_name = getFullMonkeyName(monkey_prefix);
root_dir = fileparts(pwd);
base_dir_path = fullfile(root_dir, 'saveFold', full_monkey_name, 'data', 'Synergy');
synergy_detail_dir = fullfile(base_dir_path, 'synergy_detail', use_EMG_type);
Allfiles_S = getGroupedDates(synergy_detail_dir, monkey_prefix, term_select_type, term_type);
if isempty(Allfiles_S)
    disp('user pressed "cancel" button');
    return;
end

AllDays = strrep(Allfiles_S, monkey_prefix, '');
day_num = length(Allfiles_S);

% create a flag to indicate whether or not to add  a color bar to thefigure
colorbar_flag = 0;
if and(exist("TT_day", "var"), not(day_num == 1))
    colorbar_flag = 1;
end

% create the data array of VAF
VAF_data_list = cell(1, day_num);
shuffle_VAF_data_list = cell(1, day_num);
for day_id = 1:day_num
    unique_name = Allfiles_S{day_id};
    VAF_data_path = fullfile(synergy_detail_dir, unique_name, [unique_name '.mat']);

    % load VAF data & shuffle data
    VAF_data = load(VAF_data_path, use_style);
    shuffle_data = load(VAF_data_path, 'shuffle');

    % calcurate the average value of VAF for all test (or train) data & shuffle data
    VAF_data_list{day_id} = mean(VAF_data.(use_style).r2, 2);
    shuffle_VAF_data_list{day_id} = mean(shuffle_data.shuffle.r2, 2);
end
VAF_data_list = cell2mat(VAF_data_list);
shuffle_VAF_data_list = cell2mat(shuffle_VAF_data_list);

if strcmp(figure_type, 'dVAF')
    dVAF_data_list = diff(VAF_data_list, 1);
    shuffle_dVAF_data_list = diff(shuffle_VAF_data_list, 1);
end

% extract number of muscles
[muscle_num, ~] = size(VAF_data_list);

%% plot VAF
switch figure_type
    case 'VAF'
        use_shuffle_data_list = shuffle_VAF_data_list;
        use_VAF_data_list = VAF_data_list;
        x_axis = 1:muscle_num; 
        y_range = [0 1];
        legend_location = 'northwest';
    case 'dVAF'
        use_shuffle_data_list = shuffle_dVAF_data_list;
        use_VAF_data_list = dVAF_data_list;
        x_axis = 2:muscle_num;
        y_range = [0 0.4];
        legend_location = 'northeast';
end

figure('Position',[100,100,800,600]);
hold on;

% plot VAF of shuffle data
shuffle_mean = mean(use_shuffle_data_list, 2);
shuffle_std = std(use_shuffle_data_list, 0, 2);
errorbar(x_axis, shuffle_mean, shuffle_std, 'o-', 'LineWidth', 2, 'Color', 'blue', 'DisplayName', [figure_type '-shuffle']);

% plot VAF of actual data
switch VAF_plot_type
    case 'stack'
        if colorbar_flag == 1
            day_range = zeros(1,2);
            day_range(1) = CountElapsedDate(AllDays{1}, TT_day);
            day_range(2) = CountElapsedDate(AllDays{end}, TT_day);

            color_matrix = zeros(day_num, 3);
            color_vector = linspace(0.4, 1, day_num);
            % preとpostで色分けする(preとpostが混同している場合は赤ベースにする)
            if all(day_range < 0)
                color_matrix(:, 2) = color_vector;
            else
                color_matrix(:, 1) = color_vector;
            end
        else
            color_matrix = zeros(day_num, 3);
            color_vector = linspace(0.4, 1, day_num);
            color_matrix(:, 1) = color_vector;
        end

        for day_id = 1:day_num
            plot_VAF = use_VAF_data_list(:, day_id);

            % plot
            plot(x_axis, plot_VAF, 'LineWidth', 2, 'Color', color_matrix(day_id, :), HandleVisibility='off');
            plot(x_axis, plot_VAF, 'o', 'LineWidth', 2, 'Color', color_matrix(day_id, :), HandleVisibility='off');
        end
    
        if colorbar_flag == 1
            % setting of color bar
            clim(day_range);
            colormap(color_matrix)
            h = colorbar;
            ylabel(h, 'Elapsed day(criterion = TT)', 'FontSize', font_size)
        end
    case 'mean'
        plot_VAF = mean(use_VAF_data_list, 2);
        plot_VAF_std = std(use_VAF_data_list, 0, 2);

        % plot
        errorbar(x_axis, plot_VAF, plot_VAF_std, 'o-', 'LineWidth', 2, 'Color', 'red', 'DisplayName', [figure_type '-' num2str(muscle_num) 'EMGs']);
end

% decoration
if strcmp(figure_type, 'VAF')
    yline(VAF_threshold,'Color','k','LineWidth',2, HandleVisibility='off')
end
xlim([0 muscle_num]);
ylim(y_range);
xlabel('Number of synergy', FontSize=font_size)
ylabel(['Value of ' figure_type], FontSize=font_size)
legend('Location', legend_location)
switch term_select_type
    case 'auto'
        title([figure_type ' value of each session(' term_type '=' num2str(day_num) 'days)'], FontSize = font_size);
    case 'manual'
        title([figure_type ' value of each session'], FontSize = font_size);
end
set(gca, 'FontSize', 25);
grid on;

hold off

%% save figure(as .fig & .png)
save_figure_base_fold_path = strrep(base_dir_path, 'data', 'figure');
save_figure_fold_path = fullfile(save_figure_base_fold_path, 'VAF_result', figure_type, VAF_plot_type, use_EMG_type);
makefold(save_figure_fold_path);
switch term_select_type
    case 'auto'
        saveas(gcf, fullfile(save_figure_fold_path, [figure_type '_result(' term_type '_' num2str(day_num) 'days_' VAF_plot_type ').png']))
        saveas(gcf, fullfile(save_figure_fold_path, [figure_type '_result(' term_type '_' num2str(day_num) 'days_' VAF_plot_type ').fig']))
    case 'manual'
        saveas(gcf, fullfile(save_figure_fold_path, [figure_type '_result(' AllDays{1} 'to' AllDays{end} '_' num2str(length(AllDays)) 'days_' VAF_plot_type ').png']));
        saveas(gcf, fullfile(save_figure_fold_path, [figure_type '_result(' AllDays{1} 'to' AllDays{end} '_' num2str(length(AllDays)) 'days_' VAF_plot_type ').fig']));
end
close all

