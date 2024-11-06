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
post: (if you want to cutout temporal pattern of synergy)MakeDataForPlot_H_utb.m
         (if you want to confirm whether the significant change is occured in spatial synergy by statistical test) PerformAnova.m
        (if you want to evaluate the change in spatial synergy by PCA) EvaluateSynergyChange.m


[Improvement points(Japanaese)]
cosine distanceとclusteringは他の関数でも使うので、localじゃなくて、外部関数としてまとめたほうがいいかも

[caution]
階層クラスタリングを行った時に、全てのクラスタの要素数が一致していない場合はエラー吐く。
(シナジー数が変化しない & シナジーの構造も変化しない前提で作られている)
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

%% set param
term_select_type = 'manual'; %'auto' / 'manual'
term_type = 'pre'; %(if term_select_type == 'auto') pre / post / all 
monkeyname = 'Hu';
syn_num = 5; % number of synergy you want to analyze
plot_clustering_result = 1; % whether to plot cosine distance & dendrogram of hierarcical clustering
save_WDaySynergy = 1;% Whether to save synergy W (to be used for ANOVA)
save_data = 1; % Whether to store data on synergy orders in 'order_tim_list' folder (should basically be set to 1).
save_fig = 1; % Whether to save the plotted synergy W figure
synergy_combination = 'all'; % dist-dist/prox-dist/all etc..
nmf_fold_name = 'new_nmf_result'; % name of nmf folder

%% code section
realname = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname, nmf_fold_name);
Allfiles_S = getGroupedDates(base_dir, monkeyname, term_select_type, term_type);
if isempty(Allfiles_S)
    disp('user pressed "cancel" button');
    return;
end

% extract only date portion from 'Allfiles_S' and store it into a list
days = get_days(Allfiles_S);
day_num = length(days);
if and(strcmp(term_select_type, 'auto'), strcmp(term_type, 'post'))
    pre_file_list = getGroupedDates(base_dir, monkeyname, term_select_type, 'pre');
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
% 1. load W_data
if day_num > 1
    W_data = cell(1, day_num);
    for date_id = 1:day_num
        ref_day = days(date_id);
        common_name = [monkeyname num2str(ref_day)];
        use_W_folder_path = fullfile(base_dir, [common_name '_standard'], [common_name '_syn_result_' num2str(EMG_num)], [common_name '_W']);
        use_W_file_name = [common_name '_aveW_' num2str(syn_num)];
        load(fullfile(use_W_folder_path, use_W_file_name), 'aveW');
        W_data{date_id} = aveW;
        clear aveW;
    end
    [Wt, k_arr] = OrderSynergy(EMG_num, syn_num, W_data, monkeyname, days, base_dir, plot_clustering_result, term_type);
    if isempty(k_arr)
        warning('We were unable to match all synergies. We recommend reducing the number of synergy');
        return; 
    end
else
    k_arr = transpose(1:syn_num);
    W_data =  cell(1,1);
    % Load the W synergy data created by SYNERGYPLOT
    synergy_W_file_path = fullfile(base_dir, [monkeyname num2str(days) '_standard'], [monkeyname num2str(days) '_syn_result_' sprintf('%d',EMG_num)], [monkeyname num2str(days) '_W'], [monkeyname num2str(days) '_aveW_' sprintf('%d',syn_num) '.mat']);
    load(synergy_W_file_path, 'aveW');
    Wt{1} = aveW;
end

if and(strcmp(term_select_type, 'auto'), strcmp(term_type, 'post'))
    % align the order of synergies with the 1st day of 'pre'
    compair_days = [pre_days(1); days(1)];
    representative_data = cell(1, 2);
    for date_id = 1:2
        ref_day = compair_days(date_id);
        common_name = [monkeyname num2str(ref_day)];
        use_W_folder_path = fullfile(base_dir, [common_name '_standard'], [common_name '_syn_result_' num2str(EMG_num)], [common_name '_W']);
        use_W_file_name = [common_name '_aveW_' num2str(syn_num)];
        load(fullfile(use_W_folder_path, use_W_file_name), 'aveW');
        representative_data{date_id} = aveW;
        clear aveW;
    end
    [~, order_list] = OrderSynergy(EMG_num, syn_num, representative_data, monkeyname, compair_days, base_dir, plot_clustering_result);
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
    ylim([0 1]);
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