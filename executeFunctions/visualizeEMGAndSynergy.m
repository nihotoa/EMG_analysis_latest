%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[role of this code]
plot EMG (or activty pattern of muslcle Synergy) around each timing and save as figure

[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code

[role of this code]
Plot muscle synergies extracted from EMG for each exoerimental day

[Saved data location]
location:
    EMG_analysis_tutorial/data/Yachimun/easyData/P-DATA/<F170516toF170524_4>/
    (The area enclosed by <> depends on the folder selected)

file name:
    data:aligned_EMG_data.mat (This file contains the general data needed for plotting (e.g. cut-out area, cut-out activity data, etc.)
    figure: Many diagrams are saved with the '.fig' and '.png' extensions. Please check the output results

[procedure]
pre : prepareSynergyTemporalData.m or prepareEMGAndTimingData.m
post: calcXcorr

[caution!!]
1. Sometimes the function 'uigetfile' is not executed and an error occurs
-> please reboot MATLAB

[improvement]
+ (シナジーの場合)使用した筋電の数を考慮する必要があるので、ディレクトリをもう一階層追加する
+ preとpost混ぜて選んでもエラー吐かないようにする
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

%% set param
monkey_prefix = 'Hu'; % prefix of Raw data(ex) 'Se'/'Ya'/'F'/'Wa'/'Ni'/'Hu'
plot_all = 1; % whether you want to plot figure focus on 'whole task'
plot_each_timing = 1; % whether you want to plot figure focus on 'each timing'
plot_type = 'Synergy';  % the data which you want to plot -> 'EMG' or 'Synergy'
ylim_setting_type = 'all'; % (if nomalize Amp == false) 'all'/'individual', whether ylim be set individually for each EMG or use a common value
ylim_max = 10; % (if nomalize Amp == false && ylim_setting_type == 'all') ylim of graph
ylim_max_list = [200, 80, 80, 20, 30, 80, 100, 30, 50, 20, 80, 50, 30, 60, 30, 20]; % (if nomalize Amp == false && ylim_setting_type == 'individual') ylim of graph for each EMG
LineW = 1.5; %0.1;a % width of plot line
row_num = 4; % how many rows to display in one subplot figure
fig_type_array = {'stack', 'std'}; % you don't  need to change

% if plot_type == 'Synergy'
use_EMG_type = 'only_task'; %' full' / 'only_task'
synergy_num = 4; % number of synergy you want to analyze

%% code section
% get the real name from monkey_prefix
full_monkey_name = getFullMonkeyName(monkey_prefix);
root_dir = fileparts(pwd);

switch plot_type
    case 'EMG'
        base_dir_path = fullfile(root_dir, 'saveFold', full_monkey_name, 'data', 'EMG_ECoG');
    case 'Synergy'
        base_dir_path = fullfile(root_dir, 'saveFold', full_monkey_name, 'data', 'Synergy');
end

% Get the plotWindow at each timing and list of the filenames of the files to be read.
% set the date list of data to be used as control data & the cutout range around each timing
switch full_monkey_name
    case 'Yachimun'
        timing_name_list = ["Lever1 on ", "Lever1 off ", "Lever2 on ", "Lever2 off"];
        TT_day=  170530;
        % plot window (Xcorr data will be made in this range)
        plotWindow_cell{1} = [-25 5];
        plotWindow_cell{2} = [-15 15];
        plotWindow_cell{3} = [-15 15];
        plotWindow_cell{4} = [-5 25];
    case 'SesekiL'
        timing_name_list = ["Lever on ", "Lever off ", "Photo on", "Photo off"];
        TT_day=  200121;
        % plot window (Xcorr data will be made in this range)
        plotWindow_cell{1} = [-30 15];
        plotWindow_cell{2} = [-10 15];
        plotWindow_cell{3} = [-15 15];
        plotWindow_cell{4} = [-2 15];
    case 'Nibali'
        timing_name_list = ["Task start ", "Grasp on ", "Grasp off ", "Task End"];
        TT_day=  220530;
        % plot window (Xcorr data will be made in this range)
        plotWindow_cell{1} = [-25 5];
        plotWindow_cell{2} = [-15 15];
        plotWindow_cell{3} = [-15 15];
        plotWindow_cell{4} = [-5 25];
    case 'Hugo'
        timing_name_list = ["Task start ", "Drawer on", "Drawer off", "Grasp on ", "Grasp off ", "Task End"];  
        TT_day=  250120;
        % plot window (Xcorr data will be made in this range)
        plotWindow_cell{1} = [-25 15];
        plotWindow_cell{2} = [-25 15];
        plotWindow_cell{3} = [-15 15];
        plotWindow_cell{4} = [-15 15];
        plotWindow_cell{5} = [-15 15];
        plotWindow_cell{6} = [-5 25];
end

switch plot_type
    case 'EMG'
        Pdata_dir_path = fullfile(base_dir_path, 'P-DATA');
    case 'Synergy'
        Pdata_dir_path = fullfile(base_dir_path, 'synergy_across_sessions', use_EMG_type, ['synergy_num==' num2str(synergy_num)], 'temporal_pattern_data');
end

disp("please select '_Pdata.mat' for all the dates you want to plot")
Allfiles_S = uigetfile(fullfile(Pdata_dir_path, '*.mat'), 'Select One or More Files', 'MultiSelect', 'on');
if ischar(Allfiles_S)
    Allfiles_S = {Allfiles_S};
elseif isequal(Allfiles_S, 0)
    disp('user press "cancel" button')
    return;
end


[~, session_num] = size(Allfiles_S);

% make array containing folder name
Allfiles = strrep(Allfiles_S,'_Pdata.mat',''); % just used for folder name
days_str = strrep(Allfiles, monkey_prefix, '');

%% Get the average data length over all sessions(days)

%get the session average of each parameter
for session_id = 1:session_num
    % load parameters
    load_file_path = fullfile(Pdata_dir_path, Allfiles_S{session_id});
    load(load_file_path, "AllT", "TIME_W", "D" )
    
    % initialize 
    if session_id == 1
        timing_num = sum(startsWith(fieldnames(D), 'trig'));
        session_average_length = 0;
        whole_task_length_list = zeros(session_num, 1);

        tentetive_session_average_length_struct = struct();
        tentetive_length_list_struct = struct();
        for timing_id = 1:timing_num
            tentetive_session_average_length_struct.(['timing' num2str(timing_id)]) = 0;
            tentetive_length_list_struct.(['timing' num2str(timing_id)]) = zeros(session_num, 1);
        end
    end

    % store the data from each session
    session_average_length = (session_average_length * (session_id - 1) + AllT) / session_id; 
    whole_task_length_list(session_id) = AllT;
    for timing_id = 1:timing_num
        tentetive_length_data = tentetive_session_average_length_struct.(['timing' num2str(timing_id)]);
        ref_timing_length = D.(['Ld' num2str(timing_id)]);
        tentetive_session_average_length_struct.(['timing' num2str(timing_id)]) = (tentetive_length_data * (session_id-1) + ref_timing_length)/session_id;
        tentetive_length_list_struct.(['timing' num2str(timing_id)])(session_id) = ref_timing_length;
    end
end

%% Perform time normalization based on the session average of the acquired data lengths.

% Create empty structure to store data
% for trial
plotted_whole_task_EMG_struct = struct();
plotted_each_timing_EMG_cell = cell(timing_num, 1);

plotted_whole_task_EMG_struct.session_average_length = round(session_average_length);
plotted_whole_task_EMG_struct.length_list = whole_task_length_list;
plotted_whole_task_EMG_struct.time_normalized_EMG = cell(session_num,1);

% for each timing
for timing_id = 1:timing_num
    plotted_each_timing_EMG_cell{timing_id}.session_average_length = round(tentetive_session_average_length_struct.(['timing' num2str(timing_id)]));
    plotted_each_timing_EMG_cell{timing_id}.length_list = round(tentetive_length_list_struct.(['timing' num2str(timing_id)]));
    plotted_each_timing_EMG_cell{timing_id}.time_normalized_EMG = cell(session_num,1);
    plotted_each_timing_EMG_cell{timing_id}.cutout_range = linspace(-D.(['Range' num2str(timing_id)])(1), D.(['Range' num2str(timing_id)])(2), plotted_each_timing_EMG_cell{timing_id}.session_average_length);
    plotted_each_timing_EMG_cell{timing_id}.plot_range = plotWindow_cell{timing_id};
end

% store the data from each session
whole_task_common_length = plotted_whole_task_EMG_struct.session_average_length;
for session_id = 1:session_num
    % load the data of the average activity pattern of each synergy (ormuscle) for this session
    load(fullfile(Pdata_dir_path, Allfiles_S{session_id}), 'alignedDataAVE');

    if session_id == 1
        element_num = length(alignedDataAVE);
    end
    
    % Eliminate differences in length between sessions (perform time normalisation).
    plot_data = AlignDatasets(alignedDataAVE, whole_task_common_length); 
    plotted_whole_task_EMG_struct.time_normalized_EMG{session_id,1} = cell2mat(plot_data);
end

% add data which is related to 'mean+std' to 'plotted_whole_task_EMG_struct' structure
[plotted_whole_task_EMG_struct] = makeSDdata(plotted_whole_task_EMG_struct, session_num, element_num);

% for each timing
for timing_id = 1:timing_num
    ref_timing_EMG_struct = plotted_each_timing_EMG_cell{timing_id};
    [ref_timing_EMG_struct] = resampleEachTiming(Allfiles_S, ref_timing_EMG_struct, timing_id, Pdata_dir_path, element_num);

    % add data which is related to 'mean+std' to 'plotted_each_timing_EMG_struct{timing_id}' structure
    [ref_timing_EMG_struct] = makeSDdata(ref_timing_EMG_struct, session_num, element_num);
    plotted_each_timing_EMG_cell{timing_id} = ref_timing_EMG_struct;
end

% plot color setting(create color map)
days_double =str2double(days_str'); % used for matching with 'Csp'
selected_first_Pdata_name = Allfiles_S{1};
[TermDays, term_type] = extract_post_days(TT_day, Pdata_dir_path, selected_first_Pdata_name);

% decision of base color(RGB)
switch term_type
    case 'pre'
        color_id = 2;
    case 'post'
        switch full_monkey_name
            case 'SesekiL'
                color_id = 2;
            otherwise
                color_id = 1;
        end
end
PostLength = length(TermDays);
Csp = zeros(PostLength, 3);
Csp(:, color_id) = ones(PostLength, 1).*linspace(0.3, 1, PostLength)';

%% define save folder path (which is stored all data & figures)
unique_name = [Allfiles{1} 'to' days_str{end} '_' num2str(length(Allfiles))];
switch plot_type
    case 'EMG'
        save_figure_fold_path = fullfile(root_dir, 'saveFold', full_monkey_name, 'figure', 'EMG', 'each_timing_EMG', unique_name);
    case 'Synergy'
        tentetive = strrep(base_dir_path, 'data', 'figure');
        save_figure_fold_path = fullfile(tentetive, 'synergy_across_sessions', use_EMG_type, ['synergy_num==' num2str(synergy_num)], unique_name, 'H_figures');
end
makefold(save_figure_fold_path);

%% plot figure
if and(strcmp(ylim_setting_type, 'all'), ylim_max == inf)
    max_amplitude_list = getMaxAmplitudeList(plotted_whole_task_EMG_struct.time_normalized_EMG);
    max_amplitude_list = transpose(max_amplitude_list);
    ylim_max_list = ceil(max_amplitude_list / 10) * 10;
end

% comple the data needed to embelish the figure
% load taskRange
switch plot_type
    case 'EMG' 
        load(fullfile(Pdata_dir_path, Allfiles_S{1}), 'taskRange', 'EMGs');
    case 'Synergy'
        % obtain a list of the percentage of cutouts to the entire task as 'TaskRange' (ex. [-50, 150])
        load(fullfile(Pdata_dir_path, Allfiles_S{1}), 'taskRange');
end
plotted_whole_task_EMG_struct.cutout_range = linspace(taskRange(1), taskRange(2), plotted_whole_task_EMG_struct.session_average_length);

% add variables which is used in plot function in 'data_struct'
data_str = struct();
use_variable_name_list = {'element_num', 'session_num', 'LineW', 'ylim_setting_type', 'ylim_max','ylim_max_list' 'EMGs', 'plot_type', 'TermDays', 'days_double', 'Csp', 'row_num', 'timing_num'};

% store data in a struct
not_exist_variables = {};
for jj = 1:length(use_variable_name_list)
    variable_name = use_variable_name_list{jj};
    try
        data_str.(variable_name) = eval(variable_name);
    catch
        not_exist_variables{end+1} = variable_name;
    end
end

% display not found variable in 'use_variable_name_list'
if not(isempty(not_exist_variables))
    disp(['(' char(join(not_exist_variables, ', ')) ') is not found'])
end

%% 1. plot all taks range data(all muscle) -> plot range follows 'plotWindow'
if plot_all == 1
    % save_setting(determine file name for figure)
    save_figure_name =  ['All_' plot_type '(whole task)'];
    
    % add plotWindow & plotted_data to 'data_str'  
    data_str.plotted_data = plotted_whole_task_EMG_struct;
    data_str.plotWindow = [-25 105];

    % create an array identifying 'fig_type'
    for fig_type_idx = 1:length(fig_type_array)
        fig_type = fig_type_array{fig_type_idx};

        % generate figure 
        f.fig1 = figure('position', [100, 100, 1000, 1000]);
    
        % plot figure
        f = plot_figures(f, data_str, 'whole_task', fig_type);
        sgtitle([fig_type ' ' plot_type ' in task(from' num2str(days_str{1}) 'to' num2str(days_str{end}) '-' num2str(length(days_str)) ')'], 'FontSize', 25)
    
        % save figure
        saveas(gcf, fullfile(save_figure_fold_path, [save_figure_name '_' fig_type '.fig']))
        saveas(gcf, fullfile(save_figure_fold_path, [save_figure_name '_' fig_type '.png']))
        close all;
    end
end

%% plot EMG(or Synergy) which is aligned in each timing(timing1~timing4)

if plot_each_timing == 1
    % decide the number of created figures (4 muscles(or Synergies) per figure)
    figure_num = ceil(element_num/row_num); 

    % Create a struct array for figure to plot
    figure_str = struct;
    for fig_type_idx = 1:length(fig_type_array)
        fig_type = fig_type_array{fig_type_idx};
        figure_str.(fig_type) = struct;
        for figure_id = 1:figure_num
            figure_str.(fig_type).(['fig' num2str(figure_id)]) = figure("position", [100, 100, 250 * timing_num, 1000]);
        end
    end

    for timing_id = 1:timing_num
        % load activity data and window info around timing to be focused
        timing_name = timing_name_list(timing_id);

        % extract plot data as 'plotted_data'
        ref_timing_plotted_data = plotted_each_timing_EMG_cell{timing_id};
        ref_timing_plotted_data.cutout_range =  linspace(-D.(['Range' num2str(timing_id)])(1), D.(['Range' num2str(timing_id)])(2), ref_timing_plotted_data.session_average_length);
        plotWindow = plotWindow_cell{timing_id}; % plotWindow at specified timing

        % add some variables (which is changed in loop) to 'data_str'
        data_str.timing_id = timing_id;
        data_str.timing_name = timing_name;
        data_str.plotWindow = plotWindow;
        data_str.plotted_data = ref_timing_plotted_data;

        % plot figures
        for fig_type_idx = 1:length(fig_type_array)
            fig_type = fig_type_array{fig_type_idx};
            figure_str.(fig_type) = plot_figures(figure_str.(fig_type), data_str, 'each_timing', fig_type);
        end
    end

    % save_figure
    for figure_id = 1:figure_num
        save_figure_name =  ['each_timing_figure' num2str(figure_id)];
        for fig_type_idx = 1:length(fig_type_array)
            fig_type = fig_type_array{fig_type_idx};
            figure(figure_str.(fig_type).(['fig' num2str(figure_id)]));
            saveas(gcf, fullfile(save_figure_fold_path, [save_figure_name '_' fig_type '.fig']))
            saveas(gcf, fullfile(save_figure_fold_path, [save_figure_name '_' fig_type '.png']))
        end
    end
    close all;
end

% save data setting
switch plot_type
    case 'EMG'
        save_data_dir_path = fullfile(base_dir_path, 'EMG_across_sessions', 'EMG_for_each_timing');
    case 'Synergy'
        save_data_dir_path = fullfile(fileparts(Pdata_dir_path), 'temporal_pattern_for_each_timing');
end
makefold(save_data_dir_path)

for session_id = 1:session_num
    whole_task_EMG_struct = struct();
    each_timing_EMG_cell = cell(timing_num, 1);

    whole_task_EMG_struct.time_normalized_EMG = plotted_whole_task_EMG_struct.time_normalized_EMG{session_id};
    whole_task_EMG_struct.session_average_length = plotted_whole_task_EMG_struct.session_average_length;
    whole_task_EMG_struct.cutout_range = plotted_whole_task_EMG_struct.cutout_range;
    
    for timing_id = 1:timing_num
        ref_timing_saved_struct = struct();
        ref_timing_used_struct = plotted_each_timing_EMG_cell{timing_id};
        
        ref_timing_saved_struct.time_normalized_EMG = ref_timing_used_struct.time_normalized_EMG{session_id};
        ref_timing_saved_struct.session_average_length = ref_timing_used_struct.session_average_length;
        ref_timing_saved_struct.cutout_range = ref_timing_used_struct.cutout_range;
        ref_timing_saved_struct.plot_range = ref_timing_used_struct.plot_range;

        each_timing_EMG_cell{timing_id} = ref_timing_saved_struct;
    end
    
    save_file_name = [monkey_prefix days_str{session_id} '_each_timing_pattern.mat'];
    save(fullfile(save_data_dir_path, save_file_name), 'whole_task_EMG_struct', 'each_timing_EMG_cell', 'timing_name_list')
end

%% define local function
% make dates array of post as 'TermDays'(eliminate only Pre days from '_Pdata.mat' name list)
function [TermDays, term_type] = extract_post_days(TT_day, folder_path, first_Pdata_name)
    files_struct = dirPlus(fullfile(folder_path, '*_Pdata.mat'));
    file_names = {files_struct.name};
    day_num = length(file_names);
    date_list = zeros(day_num, 1);
    for day_id = 1:day_num
        num_parts = regexp(file_names{day_id}, '\d+', 'match'); %extract number part
        exp_day = num_parts{1};
        date_list(day_id) = str2double(exp_day);
    end

    % determine which term applies
    num_parts = regexp(first_Pdata_name, '\d+', 'match'); %extract number part
    first_day = num_parts{1};
    elapsed_day = CountElapsedDate(first_day, TT_day);
    if elapsed_day < 0
        term_type = 'pre';
    else
        term_type = 'post';
    end
    TermDays = get_specific_term(date_list, term_type, TT_day);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function max_amplitude_list = getMaxAmplitudeList(plotData)
session_num = length(plotData);
EMG_num = length(plotData{1});
max_amplitude_list = zeros(EMG_num, 1);
for EMG_id = 1:EMG_num
    ref_data = cell(1, session_num);
    for session_id = 1:session_num
        ref_data{session_id} = plotData{session_id}{EMG_id};
    end
    ref_data = cell2mat(ref_data);
    max_amplitude_list(EMG_id) = max(ref_data);
end
end