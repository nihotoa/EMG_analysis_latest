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
pre: plotVAF.m or FindOptimalSynergyNum.m
post: dispNMF_W.m

[caution!!]
In order to complete this function, in addtion to the analysis flow of synergy analysis, it is necessary to finish the flow up to 'runningEasyfunc.m' of EMG analysis

[Improvement points(Japanaese)]
注意点: タイミングデータの取得のために, EMG_analysisのフローをrunnningEasyfuncまで行う必要がある
select_synergy_num_type == 'auto'で解析を行うためには,先にFindOptimalSynergyNum.mを行う必要がある.
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkeyname = 'F'; % prefix that each monkey has uniquery
select_synergy_num_type = 'manual';  % 'manual' / 'auto'
synergy_num_list = [4]; % (if select_synergy_num_type == 'manual')which synergy number of synergies to plot(Please decide based onf VAF results)
plot_clustering = 1; % Whether you want to plot & save heatmap of cosine distance and the clustering result.
nmf_fold_name = 'new_nmf_result'; 
each_plot = 0; % whether you want to plot spatial_pattern figure for each synergy

% save_setting
save_setting.save_fig_W = 1; % whether you want to save figure of spatial pattern of synergy(synergy W)
save_setting.save_fig_H = 1; % whether you want to save figure of temporal pattern of synergy(synergy H)
save_setting.save_fig_r2 = 1; % whether you want to save figure of VAF of synergy
save_setting.save_data = 1; % whether you want to save data about synergy W & synergy H

     
%% code section
% get the real monkey name
[realname] = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname);

if strcmp(select_synergy_num_type, 'auto')
    optimal_synergy_num_data_path = fullfile(base_dir, nmf_fold_name, 'optimal_synergy_num_data');
    disp('【Please select optiaml_syenrgy_num_data you want to use】');
    optimal_synergy_num_data_name = uigetfile(optimal_synergy_num_data_path);
    load(fullfile(optimal_synergy_num_data_path, optimal_synergy_num_data_name), 'optimal_synergy_num_struct')
end

% get the list of day
disp('Please select all date folder you want to analyze')
InputDirs   = uiselect(dirdir(fullfile(base_dir, 'new_nmf_result')), 1, 'Please select all date folder you want to analyze');
days = get_days(InputDirs);

if strcmp(select_synergy_num_type, 'auto')
    optimal_synergy_num_list = zeros(length(days), 1);
    field_name_list = fieldnames(optimal_synergy_num_struct);
    for day_id = 1:length(days)
        ref_day_string = num2str(days(day_id));
        correspond_id = find(contains(field_name_list, ref_day_string));
        optimal_synergy_num_list(day_id) = optimal_synergy_num_struct.(field_name_list{correspond_id}).optimal_synergy_num;
    end
end

% loop for each experimental day
for ii = 1:length(days)
    fold_name = [monkeyname sprintf('%d',days(ii))];
    switch select_synergy_num_type
        case 'manual'
            % loop for each number of synergies 
            for jj = 1:length(synergy_num_list)
                synergy_num = synergy_num_list(jj);
                plotSynergyAll_uchida(fold_name, synergy_num, nmf_fold_name, each_plot, save_setting, base_dir, plot_clustering, select_synergy_num_type);
            end
        case 'auto'
            synergy_num = optimal_synergy_num_list(ii);
            plotSynergyAll_uchida(fold_name, synergy_num, nmf_fold_name, each_plot, save_setting, base_dir, plot_clustering, select_synergy_num_type);
    end         
    close all
end


