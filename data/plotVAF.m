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
pre: makeEMGNMF_btcOya.m
post: SYNERGYPLOT.m

[Improvement points(Japanaese)]
・冗長 & 汚い、特にcolorbar_flag周りの処理。
・dVAFの処理を加えたが, colorbar_flagがtrueの時の動作確認はしてない
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
term_select_type = 'auto'; %'auto' / 'manual'
term_type = 'pre'; %(if term_select_type == 'auto') pre / post / all 
monkeyname = 'F';
use_style = 'test'; % test/train
figure_type = 'VAF'; % 'VAF'/ dVAF
VAF_plot_type = 'stack'; %'stack' or 'mean'
color_type = 'red'; %(if VAF_plot_type == 'stack') 'red' / 'colorful' 
VAF_threshold = 0.8; % param to draw threshold_line
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

Allfiles = strrep(Allfiles_S, '_standard','');
AllDays = strrep(Allfiles, monkeyname, '');
day_num = length(Allfiles_S);

% create a flag to indicate whether or not to add  a color bar to thefigure
if exist("TT_day")
    colorbar_flag = 1;
else
    colorbar_flag = 0;
end

% create the data array of VAF
VAF_data_list = cell(1, day_num);
shuffle_VAF_data_list = cell(1, day_num);
for day_id = 1:day_num
    VAF_data_path = fullfile(base_dir, Allfiles_S{day_id}, [Allfiles_S{day_id} '.mat']);

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
            switch color_type
                case 'red'
                    color_matrix = zeros(day_num, 3);
                    color_vector = linspace(0.4, 1, day_num);
                    color_matrix(:, 1) = color_vector;
                case 'colorful'
                    color_matrix = turbo(day_num);
            end
            day_range = [0 0];
        else
            color_matrix = zeros(day_num, 3);
            color_vector = linspace(0.4, 1, day_num);
            color_matrix(:, 1) = color_vector;
        end

        for day_id = 1:day_num
            plot_VAF = use_VAF_data_list(:, day_id);

            % plot
            switch color_type
                case 'red'
                    plot(x_axis, plot_VAF, 'LineWidth', 2, 'Color', color_matrix(day_id, :), HandleVisibility='off');
                    plot(x_axis, plot_VAF, 'o', 'LineWidth', 2, 'Color', color_matrix(day_id, :), HandleVisibility='off');
                case 'colorful'
                    plot(x_axis, plot_VAF, 'LineWidth', 2, 'Color', color_matrix(day_id, :), DisplayName = AllDays{day_id});
                    plot(x_axis, plot_VAF, 'o', 'LineWidth', 2, 'Color', color_matrix(day_id, :), HandleVisibility='off');
            end
            
            if colorbar_flag == 1
                if day_id==1
                    day_range(1) = CountElapsedDate(AllDays{day_id}, TT_day);
                elseif day_id==day_num
                    day_range(2) = CountElapsedDate(AllDays{day_id}, TT_day);
                end
            end
        end
    
        if colorbar_flag == 1
            % setting of color bar
            if strcmp(color_type, 'red')
                clim(day_range);
                colormap(color_matrix)
                h = colorbar;
                ylabel(h, 'Elapsed day(criterion = TT)', 'FontSize', font_size)
            end
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
set(gca, 'FontSize', 25);
xlabel('Number of synergy', FontSize=font_size)
ylabel(['Value of ' figure_type], FontSize=font_size)
legend('Location', legend_location)
switch term_select_type
    case 'auto'
        title([figure_type ' value of each session(' term_type '=' num2str(day_num) 'days)'], FontSize = font_size);
    case 'manual'
        title([figure_type ' value of each session'], FontSize = font_size);
end

grid on;

hold off

%% save figure(as .fig & .png)
save_fold = fullfile(base_dir, 'VAF_result');
makefold(save_fold);
switch term_select_type
    case 'auto'
        saveas(gcf, fullfile(save_fold, [figure_type '_result(' term_type '_' num2str(day_num) 'days_' VAF_plot_type ').png']))
        saveas(gcf, fullfile(save_fold, [figure_type '_result(' term_type '_' num2str(day_num) 'days_' VAF_plot_type ').fig']))
    case 'manual'
        saveas(gcf, fullfile(save_fold, [figure_type '_result(' AllDays{1} 'to' AllDays{end} '_' num2str(length(AllDays)) 'days_' VAF_plot_type ').png']));
        saveas(gcf, fullfile(save_fold, [figure_type '_result(' AllDays{1} 'to' AllDays{end} '_' num2str(length(AllDays)) 'days_' VAF_plot_type ').fig']));
end
close all

