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
pre: plotVAF.m
post: dispNMF_W.m

[caution!!]
In order to complete this function, in addtion to the analysis flow of synergy analysis, it is necessary to finish the flow up to 'runningEasyfunc.m' of EMG analysis

[Improvement points(Japanaese)]
注意点: タイミングデータの取得のために, EMG_analysisのフローをrunnningEasyfuncまで行う必要がある
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkeyname = 'F'; % prefix that each monkey has uniquery
synergy_num_list = [4]; % which synergy number of synergies to plot(Please decide based onf VAF results)
nmf_fold_name = 'new_nmf_result';
each_plot = 1; % whether you want to plot spatial_pattern figure for each synergy

% save_setting
save_setting.save_fig_W = 1; % whether you want to save figure of spatial pattern of synergy(synergy W)
save_setting.save_fig_H = 1; % whether you want to save figure of temporal pattern of synergy(synergy H)
save_setting.save_fig_r2 = 1; % whether you want to save figure of VAF of synergy
save_setting.save_data = 1; % whether you want to save data about synergy W & synergy H

     
%% code section
% get the real monkey name
[realname] = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname);

% get the list of day
disp('Please select all date folder you want to analyze')
InputDirs   = uiselect(dirdir(fullfile(base_dir, 'new_nmf_result')), 1, 'Please select all date folder you want to analyze');
days = get_days(InputDirs);

% loop for each experimental day
for ii = 1:length(days)
    fold_name = [monkeyname sprintf('%d',days(ii))];

    % loop for each number of synergies 
    for jj = 1:length(synergy_num_list)
        synergy_num = synergy_num_list(jj);
        plotSynergyAll_uchida(fold_name, synergy_num, nmf_fold_name, each_plot, save_setting, base_dir);
    end
    close all
end


