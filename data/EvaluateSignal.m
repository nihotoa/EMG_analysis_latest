%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
THIS FUNCTION IS NOT REQUIRED TO COMPLETE THE ANALYSIS.
IF YOU WANT TO COMPLETE ANALYSIS, PLEASE FOLLOW THE PROCEDURE OF ESSENTIAL FUNCTION 

[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code

[role of this code]
・evaluate the quality of selected signal by following method
1. calcurate the area of the power spectrum
2. calcurate the ratio of area of power spectrum between less than 'devide_criterion_freq' and more than 'devide_criterion_freq' as 'SN_ratio'.

[Saved data location]
as figure:
    localtion:EMG_analysis_latest/data/<realname>/easyData/freq_analysis_result/<filterDir>

[procedure]
pre: PerformFFT.m
post: nothing

[Improvement points(Japanaese)]
単純に面積を求めて、面積比を計算しているだけなので、もう少しいい方法があるか考える
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

%% set param
monkeyname = 'Ni'; % prefix of recorded data file ('F', 'Ni')
devide_criterion_freq = 250; % threshold of frequency to devide
fig_row = 4; % Number of row of subplot for figure (number of columns is automatically determined by this) 

%% code section
% get the real monkey name
[realname] = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname, 'easyData');

% assign surgery day of tendon-transfer in 'TT_surgery_day'
switch monkeyname
    case {'F', 'Ya'}
        TT_surgery_day = '170530';
    case 'Ni'
        TT_surgery_day = '220530'; 
end

% get the list of directory name
disp('【Please select folder which contains spectrum】)')
filterDir  = uiselect(dirdir(fullfile(base_dir, 'spectrum_datas')),1,'Please select folders which contains the data you want to analyze');
spectrum_file_fold_path = fullfile(base_dir, 'spectrum_datas', filterDir{1});
spectrum_file_name = uigetfile(spectrum_file_fold_path);

% load data
load(fullfile(spectrum_file_fold_path, spectrum_file_name), 'power_spectrum_struct');
days_list = power_spectrum_struct.exp_days;
day_num = length(days_list);
EMGs = fieldnames(power_spectrum_struct.spectrum_data.([monkeyname days_list{1}]));
EMG_num = length(EMGs);

% prepare struct to store analyzed data
SN_struct = struct();
power_total_struct = struct();
for muscle_id = 1:EMG_num
    SN_struct.(EMGs{muscle_id}) = zeros(day_num, 1);
    power_total_struct.(EMGs{muscle_id})  = zeros(day_num, 1);
end

% calcurate area & volume of sum of spectrum
max_SN_value = []; % this is used for ylim for SN figure
for day_id = 1:day_num
    distinction_name = [monkeyname power_spectrum_struct.exp_days{day_id}];
    spectrum_data = power_spectrum_struct.spectrum_data.(distinction_name);
    freq_axis = power_spectrum_struct.freq_axis.(distinction_name);

    % extract necessary indices
    signal_indices = find(freq_axis > 0 & freq_axis < devide_criterion_freq);
    noize_indices = find(freq_axis > devide_criterion_freq);
    all_indices = find(freq_axis > 0);

    % find the frequency resolution inthe power spectrum
    f_delta = freq_axis(2) - freq_axis(1);
    for muscle_id = 1:EMG_num
        ref_muscle_spectrum = spectrum_data.(EMGs{muscle_id});

        % calucurate area
        signal_sum = sum(ref_muscle_spectrum(signal_indices));
        noize_sum = sum(ref_muscle_spectrum(noize_indices));
        SN_value = signal_sum / noize_sum;

        % calcurate sum of power(area between 0 to (sampleRate/2))
        sum_power = sum(f_delta * ref_muscle_spectrum(all_indices));
        
        % store data
        SN_struct.(EMGs{muscle_id})(day_id) = SN_value;
        power_total_struct.(EMGs{muscle_id})(day_id) = sum_power;

        if day_id == 1 && muscle_id == 1
            max_SN_value = SN_value;
        elseif SN_value > max_SN_value
            max_SN_value = SN_value;
        end
    end
end

%% plot result
power_figure = figure("position", [100, 100, 1200, 800]);
SN_figure = figure("position", [100, 100, 1200, 800]);

% make elapsed date list (which is used for x axis)
elapsed_day_list = makeElapsedDateList(days_list, TT_surgery_day);
post_first_elapsed_date = min(elapsed_day_list(elapsed_day_list > 0));
fig_col = ceil(EMG_num / fig_row);

for muscle_id = 1:EMG_num
    ref_total_power_list = power_total_struct.(EMGs{muscle_id});
    ref_SN_value_list = SN_struct.(EMGs{muscle_id});
    
    % plot power
    figure(power_figure);
    subplot(fig_row, fig_col, muscle_id);
    hold on
    plot(elapsed_day_list, ref_total_power_list, LineWidth=1.2);
    hold on;
    plot(elapsed_day_list, ref_total_power_list, 'o');

    % decoration
    xlim([elapsed_day_list(1) elapsed_day_list(end)]);
    xlabel('elapsed date from TT[day]')
    ylabel('Area of valid freq range');
    grid on;
    rectangle('Position', [0 0, post_first_elapsed_date - 1, max(ref_total_power_list)+10], 'FaceColor',[1, 1, 1], 'EdgeColor', 'K', 'LineWidth',1.2);
    ylim([0 max(ref_total_power_list)+5]);
    title(EMGs{muscle_id});
    hold off;
    hold off 
    if muscle_id == EMG_num
        sgtitle('total Power of each EMG');
    end

    % plot SN
    figure(SN_figure);
    subplot(fig_row, fig_col, muscle_id);
    hold on
    plot(elapsed_day_list, ref_SN_value_list, LineWidth=1.2);
    hold on;
    plot(elapsed_day_list, ref_SN_value_list, 'o');

    % decoration
    xlim([elapsed_day_list(1) elapsed_day_list(end)]);
    xlabel('elapsed date from TT[day]')
    ylabel('SN ratio');
    grid on;
    rectangle('Position', [0 0, post_first_elapsed_date - 1, max_SN_value+1], 'FaceColor',[1, 1, 1], 'EdgeColor', 'K', 'LineWidth',1.2);
    ylim([0 max_SN_value+1]);
    title(EMGs{muscle_id});
    hold off;
    hold off;

    % plot both 
    if muscle_id == EMG_num
        sgtitle('SN value of each EMG');
    end
end

%% save figure
save_figure_dir = fullfile(base_dir, 'freq_analysis_result', filterDir{1});
makefold(save_figure_dir);
figure(power_figure)
saveas(gcf, fullfile(save_figure_dir, ['total_power(' filterDir{1} '_' days_list{1} '-to-' days_list{end} '-' num2str(day_num) 'days).png']));
figure(SN_figure)
saveas(gcf, fullfile(save_figure_dir, ['SN_ratio(' filterDir{1} '_devide' num2str(devide_criterion_freq) 'Hz_' days_list{1} '-to-' days_list{end} '-' num2str(day_num) 'days).png']));
close all;
