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
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
term_select_type = 'manual'; %'auto' / 'manual'
term_type = 'pre'; %(if term_select_type == 'auto') pre / post / all 
monkeyname = 'Ni';
use_style = 'test'; % test/train
VAF_plot_type = 'stack'; %'stack' or 'mean'
color_type = 'red'; %(if VAF_plot_type == 'stack') 'red' / 'colorful' 
VAF_threshold = 0.8; % param to draw threshold_line
font_size = 20; % Font size of text in the figure
nmf_fold_name = 'new_nmf_result'; % name of nmf folder

%% code section
[realname] = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname, nmf_fold_name);

% define TT-syurgery date
switch monkeyname
    case {'Ya', 'F'}
        TT_day = '20170530';
    case 'Ni'
        TT_day = '20220530';
end

% Create a list of folders containing the synergy data for each date.
switch term_select_type
    case 'auto'
        data_folders = dir(base_dir);
        folderList = {data_folders([data_folders.isdir]).name};
        Allfiles_S = folderList(startsWith(folderList, monkeyname));
        
        [prev_last_idx, post_first_idx] = get_term_id(Allfiles_S, 1, TT_day);
        
        switch term_type
            case 'pre'
                Allfiles_S = Allfiles_S(1:prev_last_idx);
            case 'post'
                Allfiles_S = Allfiles_S(post_first_idx:end);
            case 'all'
                % no processing
        end
    case 'manual'
        disp('Please select date folders which contains the VAF data you want to plot');
        Allfiles_S = uiselect(dirdir(base_dir),1,'Please select date folders which contains the VAF data you want to plot');
        if isempty(Allfiles_S)
            disp('Any Folder were not selected. Shut down the process');
            return;
        end
end

Allfiles = strrep(Allfiles_S, '_standard','');
AllDays = strrep(Allfiles, monkeyname, '');
day_num = length(Allfiles_S);

% create the data array of VAF
VAF_data_list = cell(1, day_num);
shuffle_data_list = cell(1, day_num);
for ii = 1:day_num
    VAF_data_path = fullfile(base_dir, Allfiles_S{ii}, [Allfiles_S{ii} '.mat']);

    % load VAF data & shuffle data
    VAF_data = load(VAF_data_path, use_style);
    shuffle_data = load(VAF_data_path, 'shuffle');

    % calcurate the average value of VAF for all test (or train) data & shuffle data
    VAF_data_list{ii} = mean(VAF_data.(use_style).r2, 2);
    shuffle_data_list{ii} = mean(shuffle_data.shuffle.r2, 2);
end
VAF_data_list = cell2mat(VAF_data_list);
shuffle_data_list = cell2mat(shuffle_data_list);

% extract number of muscles
[muscle_num, ~] = size(VAF_data_list);

%% plot VAF
f = figure('Position',[100,100,800,600]);
hold on;
x_axis = 1:muscle_num;

% plot VAF of shuffle data
shuffle_mean = mean(shuffle_data_list, 2);
shuffle_std = std(shuffle_data_list, 0, 2);
errorbar((1:muscle_num)', shuffle_mean, shuffle_std, 'o-', 'LineWidth', 2, 'Color', 'blue', 'DisplayName', 'VAF-shuffle');

% plot VAF of actual data
switch VAF_plot_type
    case 'stack'
        switch color_type
            case 'red'
                color_matrix = zeros(day_num, 3);
                color_vector = linspace(0.4, 1, day_num);
                color_matrix(:, 1) = color_vector;
            case 'colorful'
                color_matrix = turbo(day_num);
        end
        day_range = [0 0];
        for ii = 1:day_num
            plot_VAF = VAF_data_list(:, ii);
            
            % plot
            switch color_type
                case 'red'
                    plot(plot_VAF,'LineWidth',2, 'Color', color_matrix(ii, :), HandleVisibility='off');
                    plot(plot_VAF,'o','LineWidth',2, 'Color', color_matrix(ii, :), HandleVisibility='off');
                case 'colorful'
                    plot(plot_VAF,'LineWidth',2, 'Color', color_matrix(ii, :), DisplayName = AllDays{ii});
                    plot(plot_VAF,'o','LineWidth',2, 'Color', color_matrix(ii, :), HandleVisibility='off');
            end

            if ii==1
                day_range(1) = CountElapsedDate(AllDays{ii}, TT_day);
            elseif ii==day_num
                day_range(2) = CountElapsedDate(AllDays{ii}, TT_day);
            end
        end

        % setting of color bar
        if strcmp(color_type, 'red')
            clim(day_range);
            colormap(color_matrix)
            h = colorbar;
            ylabel(h, 'Elapsed day(criterion = TT)', 'FontSize', font_size)
        end
    case 'mean'
        plot_VAF = mean(VAF_data_list, 2);
        plot_VAF_std = std(VAF_data_list, 0, 2);

        % plot
        errorbar((1:muscle_num)', plot_VAF, plot_VAF_std, 'o-', 'LineWidth', 2, 'Color', 'red', 'DisplayName', ['VAF-' num2str(muscle_num) 'EMGs']);
end

% decoration
yline(VAF_threshold,'Color','k','LineWidth',2, HandleVisibility='off')
xlim([0 muscle_num]);
ylim([0 1])
set(gca, 'FontSize', 15);
xlabel('Number of synergy', FontSize=font_size)
ylabel('Value of VAF', FontSize=font_size)
switch term_select_type
    case 'auto'
        legend('Location','northwest')
        title(['VAF value of each session(' term_type '=' num2str(day_num) 'days)'], FontSize = font_size);
    case 'manual'
        % legendつける
        legend('Location', 'southeast');
        title(['VAF value of each session'], FontSize = font_size);
end

grid on;

hold off

%% save figure(as .fig & .png)
save_fold = fullfile(base_dir, 'VAF_result');
makefold(save_fold);
switch term_select_type
    case 'auto'
        saveas(gcf, fullfile(save_fold, ['VAF_result(' term_type '_' num2str(day_num) 'days_' VAF_plot_type ').png']))
        saveas(gcf, fullfile(save_fold, ['VAF_result(' term_type '_' num2str(day_num) 'days_' VAF_plot_type ').fig']))
    case 'manual'
        saveas(gcf, fullfile(save_fold, ['VAF_result(' AllDays{1} 'to' AllDays{end} '_' num2str(length(AllDays)) 'days_' VAF_plot_type ').png']));
        saveas(gcf, fullfile(save_fold, ['VAF_result(' AllDays{1} 'to' AllDays{end} '_' num2str(length(AllDays)) 'days_' VAF_plot_type ').fig']));
end
close all

