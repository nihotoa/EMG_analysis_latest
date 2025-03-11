%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Please change parameters
2. Please run this code & select data by following guidance (which is displayed in command window after Running this code)

[role of this code]
Plot muscle synergies extracted from EMG for each exoerimental day

[Saved data location]
location: Directory youhave chosen as save folder (A dialog box will pop up during the process, so please select a save folder)
file name: 

[procedure]
pre: visualizeVAF.m or determineOptimalSynergyNumber.m
post: visualizeSynergyWeights.m

[caution!!]
In order to complete this function, in addtion to the analysis flow of synergy analysis, it is necessary to finish the flow up to 'runningEasyfunc.m' of EMG analysis
・select_synergy_num_type == 'auto'で解析を行うためには,先にdetermineOptimalSynergyNumber.mを行う必要がある.

[Improvement points(Japanaese)]
+ 使用した筋電の数を考慮する必要があるので、ディレクトリをもう一階層追加する
+ マニュアルでシナジー数を指定するのではなく、optimal_synergy_numを参照して解析回すオプションを追加する(現状のautoがそれに対応してる)
+ autoじゃなくて、optimal_synergy_numを参照したっていうニュアンスに変更する
+ autoにした時のcancel処理が実装されてない
・構造変えた時に、autoの動作チェックはしてない．
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkey_prefix = 'Hu'; % prefix that each monkey has uniquery
select_synergy_num_type = 'manual';  % 'manual' / 'auto'
use_EMG_type = 'only_task'; %' full' / 'only_task'
synergy_num_list = [4]; % (if select_synergy_num_type == 'manual')which synergy number of synergies to plot(Please decide based onf VAF results)
plot_clustering_flag = true; % Whether you want to plot & save heatmap of cosine distance and the clustering result.
each_plot_flag = false; % whether you want to plot spatial_pattern figure for each synergy
% save_setting
save_setting.save_fig_W = 1; % whether you want to save figure of spatial pattern of synergy(synergy W)
save_setting.save_fig_H = 1; % whether you want to save figure of temporal pattern of synergy(synergy H)
save_setting.save_fig_r2 = 1; % whether you want to save figure of VAF of synergy
save_setting.save_data = 1; % whether you want to save data about synergy W & synergy H

     
%% code section
% get the real monkey name
full_monkey_name = getFullMonkeyName(monkey_prefix);
root_dir_path = fileparts(pwd);
base_dir_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'Synergy');
synergy_detail_data_dir = fullfile(base_dir_path, 'synergy_detail', use_EMG_type);
extracted_synergy_data_dir = fullfile(base_dir_path, 'extracted_synergy', use_EMG_type);

if strcmp(select_synergy_num_type, 'auto')
    optimal_synergy_num_data_path = fullfile(base_dir_path, nmf_fold_name, 'optimal_synergy_num_data');
    disp('【Please select optimal_syenrgy_num_data you want to use】');
    optimal_synergy_num_data_name = uigetfile(optimal_synergy_num_data_path);
    load(fullfile(optimal_synergy_num_data_path, optimal_synergy_num_data_name), 'optimal_synergy_num_struct')
end

% get the list of day
disp('Please select all date folder you want to analyze')
selected_dir_list   = uiselect(dirdir(synergy_detail_data_dir), 1, 'Please select all date folder you want to analyze');
if isempty(selected_dir_list)
    disp('user press "cancel" button');
    return;
end

exp_days = get_days(selected_dir_list);
exp_days_num = length(exp_days);

if strcmp(select_synergy_num_type, 'auto')
    optimal_synergy_num_list = zeros(exp_days_num, 1);
    field_name_list = fieldnames(optimal_synergy_num_struct);
    for day_id = 1:exp_days_num
        ref_day_string = num2str(exp_days(day_id));
        correspond_id = find(contains(field_name_list, ref_day_string));
        optimal_synergy_num_list(day_id) = optimal_synergy_num_struct.(field_name_list{correspond_id}).optimal_synergy_num;
    end
end

% loop for each experimental day
for exp_day_id = 1:exp_days_num
    unique_name = selected_dir_list{exp_day_id};
    switch select_synergy_num_type
        case 'manual'
            % loop for each number of synergies 
            for synergy_num_id = 1:length(synergy_num_list)
                synergy_num = synergy_num_list(synergy_num_id);
                plotSynergyAll_uchida(base_dir_path, extracted_synergy_data_dir, synergy_detail_data_dir, use_EMG_type, unique_name, synergy_num, each_plot_flag, save_setting, plot_clustering_flag, select_synergy_num_type)
            end
        case 'auto'
            synergy_num = optimal_synergy_num_list(exp_day_id);
            if isnan(synergy_num)
                continue;
            end
            plotSynergyAll_uchida(unique_name, synergy_num, nmf_fold_name, each_plot_flag, save_setting, base_dir_path, plot_clustering_flag, select_synergy_num_type);
    end         
    close all
end


