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
SynergyOrderの中身が冗長(特にヒートマップの図の作成のところはもっときれいにできるはず)
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

%% set param
monkeyname = 'F';  % Name prefix of the folder containing the synergy data for each date
term_type = 'pre';  % Which period synergies do you want to plot?
syn_num = 4; % number of synergy you want to analyze
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
[days, day_num] = extract_date(Allfiles_S, monkeyname);
if strcmp(term_type, 'post')
    [pre_days, ~] = extract_date(pre_file_list, monkeyname);
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
[Wt, k_arr] = OrderSynergy(EMG_num, syn_num, monkeyname, days, base_dir, term_type);

if strcmp(term_type, 'post')
    % align the order of synergies with the 1st day of 'pre'
    compair_days = [pre_days(1); days(1)];
    [~, order_list] = OrderSynergy(EMG_num, syn_num, monkeyname, compair_days, base_dir);
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


%% define local function
%{
[explanation of this func]:
extract only date portion from 'file_name_list' and store it into a list

[input arguments]
Allfiles_S: [cell array], the list of name of files
monkeyname: [char], prefix of raw file

[output arguments]
days: [double array], the list of experiment date
day_num: [double], how may days included in the list
%}
function [days, day_num] = extract_date(file_name_list, monkeyname)
% S = size(file_name_list);
Allfiles = strrep(file_name_list, '_standard','');
days = strrep(Allfiles, monkeyname, '');
days = cellfun(@str2double, days);
days = transpose(days);
day_num = length(days);
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% next local function %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[explanation of this func]:
this local function is used to provide the information about sort of synergies

[input arguments]

[output arguments]

[caution!!]
%}

function [Wt, k_arr] = OrderSynergy(EMG_num, syn_num, monkeyname, days, base_dir, term_type)
if not(exist('term_type', 'var'))
    plot_setting = 0;
else
    plot_setting = 1;
end
% setting of save_folder
hierarchical_cluster_result_path = fullfile(base_dir, 'hierarchical_cluster_result');
makefold(hierarchical_cluster_result_path);

day_num = length(days);
% Create an empty array to store synergy W values
W_data =  cell(1,day_num);
labels = {};
alphabet_string = 'A':'Z';
% Read the daily synergy W values & create an array.
for date_id = 1:day_num
    % Load the W synergy data created in the previous phase
    synergy_W_file_path = fullfile(base_dir, [monkeyname mat2str(days(date_id)) '_standard'], [monkeyname mat2str(days(date_id)) '_syn_result_' sprintf('%d',EMG_num)], [monkeyname mat2str(days(date_id)) '_W'], [monkeyname mat2str(days(date_id)) '_aveW_' sprintf('%d',syn_num) '.mat']);
    load(synergy_W_file_path, 'aveW');
    W_data{date_id} = aveW;
    
    % % append name of synergies for labeling
    [~, synergy_num] = size(aveW);
    use_alphabet_str = alphabet_string(1:synergy_num);
    for synergy_id = 1:length(use_alphabet_str)
        labels{end+1} = [use_alphabet_str(synergy_id) num2str(date_id)];
    end
end

W_data_for_Wt = W_data;
W_data = cell2mat(W_data);
[~, condition_num] = size(W_data);

% calcurate cosine distance of all pairs of spatial pattern vectors and sotre them in a square matrix
cosine_distance_matrix = zeros(condition_num, condition_num);
for ref1_id = 1:condition_num
    ref1_W_vector = W_data(:, ref1_id);
    for ref2_id = 1:condition_num
        ref2_W_vector = W_data(:, ref2_id);

        % calcurate_cosine distance
        denumerator_value = dot(ref1_W_vector, ref2_W_vector);
        denomitor_value = norm(ref1_W_vector) * norm(ref2_W_vector);
        cosine_distance_value = 1 - (denumerator_value / denomitor_value);
        cosine_distance_value = round(cosine_distance_value, 5);
        cosine_distance_matrix(ref1_id, ref2_id) = cosine_distance_value;
    end
end

if plot_setting == 1
    figure('position', [100, 100, 1200, 800])
    colormap(jet);
    imagesc(cosine_distance_matrix);
    colorbar;
    h = colorbar;
    ylabel(h, 'cosine distance', 'FontSize', 25)
    axis xy;

    %decoration
    if condition_num <= 50
        xticks(1:condition_num); yticks(1:condition_num);
        xticklabels(labels);
        yticklabels(labels);
        xtickangle(90);
    end
    set(gca, 'FontSize', 15)
    title_str = sprintf(['cosine distance between each synergies' '\n' 'original order (' term_type ' ' num2str(day_num) 'days)']);
    title(title_str, 'FontSize', 25)

    % save
    saveas(gcf, fullfile(hierarchical_cluster_result_path, ['original_order_heatmap(' term_type ').fig']))
    saveas(gcf, fullfile(hierarchical_cluster_result_path, ['original_order_heatmap(' term_type ').png']))
    close all;
end

% transform cosine_distance_matrix into pairwize_distance_vector
paiwise_distance_vector = [];
for row_id = 1:condition_num-1
    ref_vector = cosine_distance_matrix(row_id, :);
    start_index = find(ref_vector==0) + 1;
    insert_vector = ref_vector(start_index:end);
    paiwise_distance_vector = [paiwise_distance_vector insert_vector];
end

% perform hierarchical clustering
Z = linkage(paiwise_distance_vector);
cluster_idx_list = cluster(Z, "maxclust", synergy_num);
k_arr = zeros(synergy_num, day_num);
sort_idx = cell(1, synergy_num);
for synergy_idx = 1:synergy_num
    correspond_idx_list = find(cluster_idx_list == synergy_idx);
    stored_idx_list = mod(correspond_idx_list, synergy_num);
    
    % change 0 value in 'stored_idx_list' to 'synergy_num'
    changed_idx_list = find(stored_idx_list==0);
    stored_idx_list(changed_idx_list) = synergy_num;
    first_date_synergy_num = stored_idx_list(1);
    
    % store the data
    sort_idx{first_date_synergy_num} = correspond_idx_list';
    k_arr(first_date_synergy_num, :) = stored_idx_list;
end

if plot_setting == 1
    % make dendrogram(argument2 is involved in the number of data to display)
    figure('position', [100, 100, 1200, 800])
    if condition_num < 50
        dendrogram_fig = dendrogram(Z, 0, 'labels', labels);
    else
        dendrogram_fig = dendrogram(Z, 50, 'labels', labels);
    end

    % decoration of dendrogram
    hold on;
    grid on;
    set(dendrogram_fig, 'LineWidth', 1.5)
    dendrogram_axes = gca;
    dendrogram_axes.XTickLabelRotation = 90;
    dendrogram_axes.FontSize = 15;
    c = cophenet(Z, paiwise_distance_vector);
    title_str = sprintf(['cosine distance between synergies(' term_type ' ' num2str(day_num) 'days)' '\n' '(cophenetic correlation coefficient = ' num2str(c) ')']);
    title(title_str, 'FontSize', 25);

    % save
    saveas(gcf, fullfile(hierarchical_cluster_result_path, ['dendrogram(' term_type ').png']));
    saveas(gcf, fullfile(hierarchical_cluster_result_path, ['dendrogram(' term_type ').fig']));
    close all;
end

% sort synergy and make heatmap
if plot_setting==1
    sort_idx = cell2mat(sort_idx);
    sorted_cosine_distance_matrix = cosine_distance_matrix(sort_idx, sort_idx);

    % ここ1回目と全く一緒だから関数化する
    figure('position', [100, 100, 1200, 800])
    colormap(jet);
    imagesc(sorted_cosine_distance_matrix);
    colorbar;
    h = colorbar;
    ylabel(h, 'cosine distance', 'FontSize', 25)
    axis xy;

    %decoration
    if condition_num <= 50
        xticks(1:condition_num); yticks(1:condition_num);
        xticklabels(labels);
        yticklabels(labels);
        xtickangle(90);
    end
    set(gca, 'FontSize', 15)
    title_str = sprintf(['cosine distance between each synergies' '\n' 'sorted (' term_type ' ' num2str(day_num) 'days)']);
    title(title_str, 'FontSize', 25)

    % save
    saveas(gcf, fullfile(hierarchical_cluster_result_path, ['ordered_heatmap(' term_type ').fig']))
    saveas(gcf, fullfile(hierarchical_cluster_result_path, ['ordered_heatmap(' term_type ').png']))
    close all;
end

% make Wt
Wt = cell(1, day_num);
for day_id = 1:day_num
    Wt{day_id} = W_data_for_Wt{day_id}(:, k_arr(:, day_id));
end
end