%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
THIS FUNCTION IS NOT REQUIRED TO COMPLETE THE ANALYSIS.
IF YOU WANT TO COMPLETE ANALYSIS, PLEASE FOLLOW THE PROCEDURE OF ESSENTIAL FUNCTION 

[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code

[role of this code]
・confirm the error of time between trial because it affects on the accuracy of average EMG or synergy pattern (which is averaged by stack of each task activity that is performed time normalized)
・Please use this to evaluate the quality of task objectively

[Saved data location]
as figure:
    EMG_analysis_latest/data/<realname>/easyData/task_time_analysis_result/

[procedure]
pre: runnningEasyfunc.m
post: nothing

[Improvement points(Japanaese)]
タイミングデータはds100Hzしているので分解能は0.01[s]であることに注意
=> 分解能を上げたいのであれば、ds前のデータを保存する必要あり
・コードが冗長かも(特にdecoration)
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

%% set param
monkeyname = 'Hu'; % 'F', 'Ni'

% setting of threshold
average_time_threshold = 2;
std_time_threshold = 1;
normalized_time_threshold = 1;
scale_FontSize = 10;
label_FontSize = 10;

%% code section
warning('off')

% get the real monkey name
[realname] = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname, 'easyData');

% setting table name of row and column
switch monkeyname
    case {'Ya', 'F'}
        timing_name = {'lever1 on', 'lever1 off', 'lever2 on', 'lever2 off'};
        TT_surgery_day = '170530';
    case 'Ni'
        timing_name = {'task start', 'grasp on', 'grasp off', 'task end'};
        TT_surgery_day = '220530';
    case 'Hu'
        timing_name = {'task start', 'drawer on', 'drawer off', 'food on', 'food off', 'task end'};
        TT_surgery_day = '241020';
end

% get the list of directory name
disp('【Please select all day folders you want to analyze (Multiple selections are possible)】)')
InputDirs   = uiselect(dirdir(base_dir),1,'Please select folders which contains the data you want to analyze');
if isempty(InputDirs)
    disp('user pressed "cancel" button');
    return
end

% make struct to store the data
trial_data_str = struct();
trial_data_str.average_time = cell(length(InputDirs), 1);
trial_data_str.std_time = cell(length(InputDirs), 1);
trial_data_str.normalized_std = cell(length(InputDirs), 1);
date_list = {};

for day_id = 1:length(InputDirs)
    % load signal data(EMG data)
    necessary_part = strrep(InputDirs{day_id}, '_standard', '');
    try
        % load information
        info_str = load(fullfile(base_dir, InputDirs{day_id}, [necessary_part '_alignedData_Uchida.mat']), 'down_Hz', 'TIME_W', 'Timing_ave', 'Timing_std', 'Timing_std_diff','Timing_ave_ratio');
        
        % find start and end id
        start_id = find(info_str.Timing_ave_ratio == 0);
        end_id = find(info_str.Timing_ave_ratio == 1);
    
        % eliminate not necessary digits
        Timing_ave = round(info_str.Timing_ave);
        Timing_std = round(info_str.Timing_std);
    
        % calcurate difference from timing to timing
        Timing_ave_diff = [0 diff(Timing_ave)];
        Timing_std_diff = [0 round(info_str.Timing_std_diff)];
        
        timing_array = [Timing_ave;Timing_std] / info_str.down_Hz;
        timing_diff_array = [Timing_ave_diff; Timing_std_diff] / info_str.down_Hz;
        timing_array = timing_array(:, start_id:end_id);
        timing_diff_array = timing_diff_array(:, start_id:end_id);
        timing_diff_array(:, 1) = 0;
        
        % store the data
        trial_data_str.average_time{day_id} = [timing_diff_array(1, 2:end), timing_array(1, end)];
        trial_data_str.std_time{day_id} = [timing_diff_array(2, 2:end), timing_array(2, end)];
        trial_data_str.normalized_std{day_id} = [timing_diff_array(2, 2:end) ./ timing_diff_array(1, 2:end), timing_array(2,end)/timing_array(1, end)];

        % add day which has adequate alignedData_Uchida.mat to 'date_list'
        ref_day = get_days(necessary_part);
        date_list{end+1, 1} = ref_day;
    catch 
        disp([necessary_part '_alignedData_Uchida.mat does not exist'])
        continue
    end
end

% eliminate empty cell from each fields & perform 'cell2mat' to make double array
field_name_list = fieldnames(trial_data_str);
for field_id = 1:length(field_name_list)
    trial_data_str.(field_name_list{field_id}) = trial_data_str.(field_name_list{field_id})(~cellfun(@isempty, trial_data_str.(field_name_list{field_id})));
    trial_data_str.(field_name_list{field_id}) = cell2mat(trial_data_str.(field_name_list{field_id}));
end

% make elapsed date list (which is used for x axis)
elapsed_day_list = makeElapsedDateList(date_list, TT_surgery_day);
post_first_elapsed_date = min(elapsed_day_list(elapsed_day_list > 0));

%% plot data
[~, col_num] = size(trial_data_str.average_time);
row_num = length(field_name_list);
figure("position", [100, 100, 1200, 800]);
for row_id = 1:row_num
    ref_type_data = trial_data_str.(field_name_list{row_id});
    % decide threshold of ylim
    switch row_id
        case 1 % average of task time
            y_threshold = average_time_threshold;
        case 2 % std of task time
            y_threshold = std_time_threshold;
        case 3 % normalized std
            y_threshold = normalized_time_threshold;
    end

    for col_id = 1:col_num
        plot_data = ref_type_data(:, col_id);
        subplot(row_num, col_num, col_num * (row_id-1) + col_id)
        hold on;

        %plot
        plot(elapsed_day_list, plot_data, LineWidth=1.2);
        hold on;
        plot(elapsed_day_list, plot_data, 'o');
    
        % decoration
        rectangle('Position', [0 0, post_first_elapsed_date - 1, y_threshold], 'FaceColor',[1, 1, 1], 'EdgeColor', 'K', 'LineWidth',1.2);
        xlim([elapsed_day_list(1) elapsed_day_list(end)]);
        ylim([0 y_threshold]);
        
        set(gca, FontSize=scale_FontSize)
        if col_id == 1
            ylabel([field_name_list{row_id} '[s]'], 'Interpreter', 'latex', FontSize=label_FontSize);
        end
        grid on;
        
        if row_id == 1
            if col_id == col_num
                title('whole task', FontSize=label_FontSize);
            else
                title(['"' timing_name{col_id} '" to "' timing_name{col_id+1} '"'], FontSize=label_FontSize);
            end
        elseif row_id == row_num
            xlabel('elapsed date from TT[day]', FontSize=label_FontSize)
        end
        hold off;
        hold off;
    end
end
sgtitle('Task Time Analysis', fontsize = 20);

%% save figures
save_fold_path = fullfile(base_dir, 'task_time_analysis_result');
makefold(save_fold_path)
save_file_name = ['task_time_analysis(' num2str(length(elapsed_day_list)) 'days_from_' num2str(date_list{1}) '_to_' num2str(date_list{end}) ')'];

saveas(gcf, fullfile(save_fold_path, [save_file_name '.fig']));
saveas(gcf, fullfile(save_fold_path, [save_file_name '.png']));
disp(['figure is saved as ' fullfile(save_fold_path, [save_file_name '.fig'])]);
disp(['figure is saved as ' fullfile(save_fold_path, [save_file_name '.png'])]);

close all;
warning('on');
