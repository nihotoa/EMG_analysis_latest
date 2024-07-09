%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code

[role of this code]
・Output a single figure of the spatial pattern of each synergy for all dates selected by the UI operation.
・Store data on the mapping of each synergy on each date and on the spatial pattern of synergies (synergy W) summarised.

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
post: MakeDataForPlot_H_utb.m

[Improvement points(Japanaese)]
cosine distanceとclusteringは他の関数でも使うので、localじゃなくて、外部関数としてまとめたほうがいいかも
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

%% set param
monkeyname = 'F';  % Name prefix of the folder containing the synergy data for each date
term_type = 'post';  % Which period synergies do you want to plot?
syn_num = 4; % number of synergy you want to analyze
plot_clustering_result = 1; % whether to plot cosine distance & dendrogram of hierarcical clustering
save_WDaySynergy = 1;% Whether to save synergy W (to be used for ANOVA)
save_data = 1; % Whether to store data on synergy orders in 'order_tim_list' folder (should basically be set to 1).
save_fig = 1; % Whether to save the plotted synergy W figure
synergy_combination = 'prox-prox'; % dist-dist/prox-dist/all etc..
nmf_fold_name = 'new_nmf_result'; % name of nmf folder

%% code section
[realname] = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname, nmf_fold_name);

% Create a list of folders containing the synergy data for each date.
data_folders = dir(base_dir);
folderList = {data_folders([data_folders.isdir]).name};
Allfiles_S = folderList(startsWith(folderList, monkeyname));

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
        pre_file_list = Allfiles_S(1:prev_last_idx);
        Allfiles_S = Allfiles_S(post_first_idx:end);
end

% extract only date portion from 'Allfiles_S' and store it into a list
days = get_days(Allfiles_S);
day_num = length(days);
if strcmp(term_type, 'post')
    pre_days = get_days(pre_file_list);
end

%% Get the name of the EMG used for the synergy analysis
first_date_fold_name = Allfiles_S{1};

% Get the path of the file that has name information of EMG used for muscle synergy analysis
first_date_file_path = fullfile(base_dir, first_date_fold_name, [first_date_fold_name '.mat']);

% get name information of EMG used for muscle synergy analysis
load(first_date_file_path, 'TargetName');
EMGs = get_EMG_name(TargetName);
EMG_num = length(EMGs);


%% Reorder the synergies to match the synergies on the first day.

% align the order of synergies
[Wt, k_arr] = OrderSynergy(EMG_num, syn_num, [], monkeyname, days, base_dir, plot_clustering_result, term_type);

if strcmp(term_type, 'post')
    % align the order of synergies with the 1st day of 'pre'
    compair_days = [pre_days(1); days(1)];
    [~, order_list] = OrderSynergy(EMG_num, syn_num, [], monkeyname, compair_days, base_dir, plot_clustering_result);
    synergy_order = order_list(:, 2);

    % align with using 'synergy_order'
    k_arr = k_arr(synergy_order, :);
    Wt = cellfun(@(x) x(:, synergy_order), Wt, 'UniformOutput', false);
end

% Expand Wt & rearrange columns
Walt = cell2mat(Wt);
Wall = Walt;
for synergy_id = 1:syn_num
    for date_id=1:day_num
        Wall(:,(synergy_id-1)*day_num+date_id) = Walt(:,(date_id-1)*syn_num+synergy_id);
    end
end

%% plot figure(Synergy_W)

% Organize the information needed for plot.
x = categorical(EMGs');
muscle_name = x; 
zeroBar = zeros(EMG_num,1);

% make folder to save figures
save_figure_folder_path = fullfile(base_dir, 'syn_figures', [monkeyname mat2str(days(1)) 'to' mat2str(days(end)) '_' sprintf('%d',day_num)]);
makefold(save_figure_folder_path);

for synergy_id=1:syn_num 
    f1 = figure('Position',[300,250*synergy_id,750,400]);
    hold on;
    
    % create plotted_W
    plotted_W = nan(EMG_num, day_num);
    for date_id = 1:day_num
        plotted_W(:, date_id) = Wt{date_id}(:, synergy_id);
    end
    bar(x,[zeroBar plotted_W],'b','EdgeColor','none');

    % decoration
    ylim([0 2.5]);
    a = gca;
    a.FontSize = 20;
    a.FontWeight = 'bold';
    a.FontName = 'Arial';
    if save_fig == 1
        figure1_name = ['W' sprintf('%d',syn_num) '_' mat2str(days(1)) 'to' mat2str(days(end)) '_' sprintf('%d',day_num) '_syn' sprintf('%d',synergy_id)];
        saveas(f1, fullfile(save_figure_folder_path, [figure1_name '.fig']));
        saveas(f1, fullfile(save_figure_folder_path, [figure1_name '.png']));
    end
end
close all;

% make directory to save synergy_W data & save data.
if save_WDaySynergy == 1
    makefold('W_synergy_data');

    % Changing the structure of an array
    WDaySynergy = cell(1,syn_num);
    for synergy_id = 1:syn_num
        for date_id = 1:day_num
            WDaySynergy{synergy_id}(:, date_id) = Wt{date_id}(:, synergy_id);
        end
    end
    
    % save_data
    data_file_name = [monkeyname num2str(days(1)) 'to' num2str(days(end)) '_' num2str(day_num) '(' term_type ')'];
    makefold(fullfile(base_dir, 'W_synergy_data'))
    save(fullfile(base_dir, 'W_synergy_data', data_file_name), 'WDaySynergy', 'x');
end

%% Plot the average value of synergy_W for all selected dates
aveWt = Wt{1};
% calcrate the average of synergy W
for date_id=1:day_num
    aveWt = (aveWt.*(date_id-1) + Wt{date_id})./date_id;
end

% plot figure of averarge synergyW
errt = zeros(EMG_num,syn_num);
for synergy_id=1:syn_num
    f2 = figure('Position',[900,250*synergy_id,750,400]);

    % Calculate standard deviation
    errt(:,synergy_id) = std(Wall(:,(synergy_id-1)*day_num+1:synergy_id*day_num),1,2)./sqrt(day_num);

    % plot
    bar(x,aveWt(:,synergy_id));
    hold on;

    % decoration
    e1 =errorbar(x, aveWt(:,synergy_id), errt(:,synergy_id), 'MarkerSize',1);
    ylim([-1 4])
    e1.Color = 'r';
    e1.LineWidth = 2;
    e1.LineStyle = 'none';
    ylim([0 2.5]);
    a = gca;
    a.FontSize = 20;
    a.FontWeight = 'bold';
    a.FontName = 'Arial';
    
    % save figure
    if save_fig == 1
        figure_average_name = ['aveW' sprintf('%d',syn_num) '_' mat2str(days(1)) 'to' mat2str(days(end)) '_' sprintf('%d',day_num) '_syn' sprintf('%d',synergy_id)];
        saveas(f2, fullfile(save_figure_folder_path, [figure_average_name '.fig']));
        saveas(f2, fullfile(save_figure_folder_path, [figure_average_name '.png']));
    end
end
close all;
%% save order for next phase analysis
if save_data == 1
    % save data of synergyW
    save_W_data_dir = fullfile(base_dir, 'spatial_synergy_data', synergy_combination);
    makefold(save_W_data_dir);
    save_W_data_file_name = [term_type '(' num2str(day_num) 'days)_data.mat'];
    save(fullfile(save_W_data_dir, save_W_data_file_name),"Wt","muscle_name","days")

    % save data which is related to the order of synergy
    save_order_data_dir = fullfile(base_dir, 'order_tim_list',  [monkeyname mat2str(days(1)) 'to' mat2str(days(end)) '_' sprintf('%d',day_num)]);
    makefold(save_order_data_dir);

    comment = 'this data were made for aveH plot';
    save_order_data_file_name = [monkeyname mat2str(days(1)) 'to' mat2str(days(end)) '_' sprintf('%d',day_num) '_' sprintf('%d',syn_num) '.mat'];
    save(fullfile(save_order_data_dir, save_order_data_file_name), 'k_arr','comment', 'days', 'EMG_num', 'syn_num');
end