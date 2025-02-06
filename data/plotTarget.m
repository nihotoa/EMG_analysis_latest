%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
%coded by Naoki Uchida
% last modification : 2024.3.14(by Ohta)

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
pre : MakeDataForPlot_H_utb.m or runnningEasyfunc.m
post: calcXcorr

[caution!!]
1. Sometimes the function 'uigetfile' is not executed and an error occurs
-> please reboot MATLAB

[Improvement points(Japanaese)]
+ figure, データに限らず、何かしらセーブしたらログ出すように変更。
+ 冗長 & 変数名がカスすぎる．この後に行う解析xcorrの計算しかないから、使わないデータは構造体に入れたり、セーブに含めたりしない
セーブするデータの変数名変えてもxcorr以外に影響が及ばないので思い切って変数名変える
+ preのプロットでもpColor = 'C'を使えるようにする


[Remind(Japanese)]
・save_dataのセクションを消した。(チュートリアルで必要がないから)
・EMG_maxみたいなやつを消した(ローランドさんがやってくれたからやる必要ない)
・forHaraを消した(plot_figure_type, eliminate_musclesと,local関数のplot_timing_figures2を消した)
・save_xcorr_dataのセクションを消した(必要なさそうだったから)
・nmf_fold_nameを消した(最初から解析すれば一位に定まるから)
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkeyname = 'Hu'; % prefix of Raw data(ex) 'Se'/'Ya'/'F'/'Wa'/'Ni'/'Hu'
plot_all = 1; % whether you want to plot figure focus on 'whole task'
plot_each_timing = 1; % whether you want to plot figure focus on 'each timing'
plot_type = 'Synergy';  % the data which you want to plot -> 'EMG' or 'Synergy'
normalizeAmp = false; % wether normalize Amplitude or not
ylim_setting_type = 'all'; % (if nomalize Amp == false) 'all'/'individual', whether ylim be set individually for each EMG or use a common value
ylim_max = 10; % (if nomalize Amp == false && ylim_setting_type == 'all') ylim of graph
ylim_max_list = [200, 80, 80, 20, 30, 80, 100, 30, 50, 20, 80, 50, 30, 60, 30, 20]; % (if nomalize Amp == false && ylim_setting_type == 'individual') ylim of graph for each EMG
LineW = 1.5; %0.1;a % width of plot line 
row_num = 4; % how many rows to display in one subplot figure
fig_type_array = {'stack', 'std'}; % you don't  need to change
nmf_fold_name = 'new_nmf_result'; % name of nmf folder

%% code section
% get the real name from monkeyname
realname = get_real_name(monkeyname);

% Get the plotWindow at each timing and list of the filenames of the files to be read.
% set the date list of data to be used as control data & the cutout range around each timing
switch realname
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
        plotWindow_cell{1} = [-25 5];
        plotWindow_cell{2} = [-15 15];
        plotWindow_cell{3} = [-15 15];
        plotWindow_cell{4} = [-15 15];
        plotWindow_cell{5} = [-15 15];
        plotWindow_cell{6} = [-5 25];
end

% compile a list of names of files containing data to be plotted
[Allfiles_S, select_folder_path] = getFileName(plot_type, realname);
if isequal(Allfiles_S, 0)
    disp('user press "cancel" button')
    return;
end


[~, session_num] = size(Allfiles_S);

% make array containing folder name
Allfiles = strrep(Allfiles_S,'_Pdata.mat',''); % just used for folder name
switch plot_type
    case 'EMG'
        days_str = strrep(strrep(Allfiles, monkeyname, ''), '_', ''); % just used for 'sgtitle'
    case 'Synergy'
        extract_func = @(str) regexp(str, '.*_(\d+)$', 'tokens', 'once');
        days_str = cellfun(extract_func, Allfiles, 'UniformOutput', true);
end

%% Get the average data length over all sessions(days)

%get the session average of each parameter
for session_id = 1:session_num
    % load parameters
    load_file_path = fullfile(select_folder_path, Allfiles_S{session_id});
    load(load_file_path, "AllT", "TIME_W", "D" )
    
    if session_id == 1
        % Create empty array to store data from each timing
        timing_num = sum(startsWith(fieldnames(D), 'trig'));
        % for trial
        AllT_AVE = 0;
        Pall.Tlist = zeros(session_num, 1);
        
        % for each timing
        Ptrig = cell(timing_num, 1);
        for timing_id = 1:timing_num
            D_AVE.(['timing' num2str(timing_id)]) = 0;
            Ptrig{timing_id}.Tlist = zeros(session_num, 1);
        end
    end

    % store the data from each session
    % for trial
    AllT_AVE = (AllT_AVE*(session_id-1) + AllT)/session_id; 
    Pall.Tlist(session_id,1) = AllT;  
    
    % for each timing
    for timing_id = 1:timing_num
        original_data = D_AVE.(['timing' num2str(timing_id)]);
        added_data = D.(['Ld' num2str(timing_id)]);
        D_AVE.(['timing' num2str(timing_id)]) = (original_data * (session_id-1) + added_data)/session_id;
        Ptrig{timing_id}.Tlist(session_id,1) = added_data;
    end
end

%% Perform time normalization based on the session average of the acquired data lengths.

% Create empty structure to store data
% for trial
Pall.AllT_AVE = round(AllT_AVE);
Pall.plotData_sel = cell(session_num,1);

% for each timing
for timing_id = 1:timing_num
    Ptrig{timing_id}.AllT_AVE = round(D_AVE.(['timing' num2str(timing_id)]));
    Ptrig{timing_id}.plotData_sel = cell(session_num,1);
    Ptrig{timing_id}.cutoutRange = linspace(-D.(['Range' num2str(timing_id)])(1), D.(['Range' num2str(timing_id)])(2), Ptrig{timing_id}.AllT_AVE);
    Ptrig{timing_id}.plotRange = plotWindow_cell{timing_id};
end

% store the data from each session
% for trial
for j = 1:session_num
    % load the data of the average activity pattern of each synergy (ormuscle) for this session
    load(fullfile(select_folder_path, Allfiles_S{j}), 'alignedDataAVE');

    if j == 1
        element_num = length(alignedDataAVE);
    end
    
    % Eliminate differences in length between sessions (perform time normalisation).
    plotData = AlignDatasets(alignedDataAVE, Pall.AllT_AVE); 

    if normalizeAmp == 1
        % divide by the maximum value of each element
        for mm = 1:element_num          
           plotData{mm} = plotData{mm} / max(plotData{mm});
        end
    end
    Pall.plotData_sel{j,1} = plotData;
end

% add data which is related to 'mean+std' to 'Pall' structure
[Pall] = makeSDdata(Pall, session_num, element_num);

% for each timing
for timing_id = 1:timing_num
    [Ptrig{timing_id}] = resampleEachTiming(Allfiles_S, Ptrig{timing_id}, timing_id, normalizeAmp, select_folder_path, element_num);

    % add data which is related to 'mean+std' to 'Ptrig{timing_id}' structure
    [Ptrig{timing_id}] = makeSDdata(Ptrig{timing_id}, session_num, element_num);
end

% plot color setting(create color map)
days_double =str2double(days_str'); % used for matching with 'Csp'
selected_first_Pdata_name = Allfiles_S{1};
[TermDays, term_type] = extract_post_days(TT_day, select_folder_path, plot_type, selected_first_Pdata_name);

% decision of base color(RGB)
switch term_type
    case 'pre'
        color_id = 2;
    case 'post'
        switch realname
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
switch plot_type
    case 'EMG'
        save_fold_path = fullfile(pwd, realname, 'easyData', 'P-DATA', [ Allfiles{1} 'to' Allfiles{end} '_' sprintf('%d',session_num)]);
    case 'Synergy'
        save_fold_path = fullfile(pwd, realname, nmf_fold_name, 'syn_figures', 'H_figures', [ Allfiles{1} 'to' Allfiles{end} '_' sprintf('%d',session_num)]);
end
makefold(save_fold_path);

%% plot figure
if and(strcmp(ylim_setting_type, 'all'), ylim_max == inf)
    max_amplitude_list = getMaxAmplitudeList(Pall.plotData_sel);
    max_amplitude_list = transpose(max_amplitude_list);
    ylim_max_list = ceil(max_amplitude_list / 10) * 10;
end

% comple the data needed to embelish the figure
% load taskRange
switch plot_type
    case 'EMG' 
        load(fullfile(select_folder_path, Allfiles_S{1}), 'taskRange', 'EMGs');
    case 'Synergy'
        % obtain a list of the percentage of cutouts to the entire task as 'TaskRange' (ex. [-50, 150])
        load(fullfile(select_folder_path, Allfiles_S{1}), 'taskRange');
end
Pall.cutoutRange = linspace(taskRange(1), taskRange(2), Pall.AllT_AVE);

% add variables which is used in plot function in 'data_struct'
data_str = struct();
use_variable_name_list = {'element_num', 'session_num', 'LineW', 'normalizeAmp', 'ylim_setting_type', 'ylim_max','ylim_max_list' 'EMGs', 'plot_type', 'TermDays', 'days_double', 'Csp', 'row_num', 'timing_num'};

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
    if normalizeAmp == 1
        save_figure_name = [save_figure_name '_normalized'];
    end
    
    % add plotWindow & Pdata to 'data_str'  
    data_str.Pdata = Pall;
    data_str.plotWindow = [-25 105];

    % create an array identifying 'fig_type'
    for idx = 1:length(fig_type_array)
        fig_type = fig_type_array{idx};

        % generate figure 
        f.fig1 = figure('position', [100, 100, 1000, 1000]);
    
        % plot figure
        f = plot_figures(f, data_str, 'whole_task', fig_type);
        sgtitle([fig_type ' ' plot_type ' in task(from' num2str(days_str{1}) 'to' num2str(days_str{end}) '-' num2str(length(days_str)) ')'], 'FontSize', 25)
    
        % save figure
        saveas(gcf, fullfile(save_fold_path, [save_figure_name '_' fig_type '.fig']))
        saveas(gcf, fullfile(save_fold_path, [save_figure_name '_' fig_type '.png']))
        close all;
    end
end

%% plot EMG(or Synergy) which is aligned in each timing(timing1~timing4)

if plot_each_timing == 1
    % decide the number of created figures (4 muscles(or Synergies) per figure)
    figure_num = ceil(element_num/row_num); 

    % Create a struct array for figure to plot
    figure_str = struct;
    for idx = 1:length(fig_type_array)
        fig_type = fig_type_array{idx};
        figure_str.(fig_type) = struct;
        for figure_id = 1:figure_num
            figure_str.(fig_type).(['fig' num2str(figure_id)]) = figure("position", [100, 100, 250 * timing_num, 1000]);
        end
    end

    for timing_id = 1:timing_num
        % load activity data and window info around timing to be focused
        timing_name = timing_name_list(timing_id);

        % extract plot data as 'Pdata'
        Pdata = Ptrig{timing_id};
        Pdata.cutoutRange =  linspace(-D.(['Range' num2str(timing_id)])(1), D.(['Range' num2str(timing_id)])(2), Pdata.AllT_AVE);
        plotWindow = plotWindow_cell{timing_id}; % plotWindow at specified timing
        
        % add some variables (which is changed in loop) to 'data_str'
        data_str.timing_id = timing_id;
        data_str.timing_name = timing_name;
        data_str.plotWindow = plotWindow;
        data_str.Pdata = Pdata;
        
        % plot figures
        for idx = 1:length(fig_type_array)
            fig_type = fig_type_array{idx};
            figure_str.(fig_type) = plot_figures(figure_str.(fig_type), data_str, 'each_timing', fig_type);
        end
    end

    % save_figure
    for figure_id = 1:figure_num
        save_figure_name =  ['each_timing_figure' num2str(figure_id)];
        for idx = 1:length(fig_type_array)
            fig_type = fig_type_array{idx};
            figure(figure_str.(fig_type).(['fig' num2str(figure_id)]));
            saveas(gcf, fullfile(save_fold_path, [save_figure_name '_' fig_type '.fig']))
            saveas(gcf, fullfile(save_fold_path, [save_figure_name '_' fig_type '.png']))
        end
    end
    close all;
end
    
%% save data
if normalizeAmp == 1
    save(fullfile(save_fold_path, 'alignedEMG_data(normalizeAmp).mat'), 'Pall', 'Ptrig', 'timing_name_list')
else
    save(fullfile(save_fold_path, 'alignedEMG_data.mat'), 'Pall', 'Ptrig', 'timing_name_list');
end


%% define local function
% make dates array of post as 'TermDays'(eliminate only Pre days from '_Pdata.mat' name list)
function [TermDays, term_type] = extract_post_days(TT_day, folder_path, plot_type, first_Pdata_name)
    common_file_name = '_Pdata';
    if strcmp(plot_type, 'Synergy')
        tentetive = regexp(first_Pdata_name, '\d+', 'match'); %extract number part
        synergy_num_string = tentetive{1};
        common_file_name = ['Syn' synergy_num_string '*' common_file_name];
    end
    files_struct = dirEx(fullfile(folder_path, ['*' common_file_name '.mat']));
    file_names = {files_struct.name};
    day_num = length(file_names);
    date_list = zeros(day_num, 1);
    for day_id = 1:day_num
        num_parts = regexp(file_names{day_id}, '\d+', 'match'); %extract number part
        switch plot_type
            case  'EMG'
                exp_day = num_parts{1};
            case 'Synergy'
                exp_day = num_parts{2};
        end
        date_list(day_id) = str2double(exp_day);
    end

    % determine which term applies
    num_parts = regexp(first_Pdata_name, '\d+', 'match'); %extract number part
    switch plot_type
        case  'EMG'
            first_day = num_parts{1};
        case 'Synergy'
            first_day = num_parts{2};
    end
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