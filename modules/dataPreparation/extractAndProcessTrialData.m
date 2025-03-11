%{
[Function Description]
This function extracts and processes trial data from experimental recordings.
It identifies successful trials, extracts timing information, and prepares the data
for further analysis. The function handles different task types based on the monkey
prefix and applies appropriate processing methods for each task type.

[Input Arguments]
monkey_prefix: [char] Prefix identifying the monkey (e.g., 'Ni', 'Hu', 'Ya')
full_monkey_name: [char] Full name of the monkey
experiment_day_num: [double] Date of experiment in numeric format
EMG_name_list: [cell array] List of EMG channel names
validate_file_range: [double array] Range of files to process
common_save_figure_path: [char] Path to save generated figures
downsample_rate: [double] Rate for downsampling the data
time_restriction_enabled: [logical] Flag to enable time restriction
trial_time_threshold: [double] Time limit for restriction (if enabled)

[Output Arguments]
transposed_success_timing: [double array] Timing data for successful trials with dimensions
    [trials x timing_events], containing sample indices for each timing event
%}

function [transposed_success_timing] = extractAndProcessTrialData(monkey_prefix, full_monkey_name, experiment_day_num, EMG_name_list, validate_file_range, common_save_figure_path, downsample_rate, time_restriction_enabled, trial_time_threshold)
    experiment_day = sprintf('%d',experiment_day_num);
    EMG_num = length(EMG_name_list);

    %% concatenate EMG data from each files(same processing as 'prepareRawEMGDataForNMF.m')
    [concatenated_EMG_data, TimeRange_EMG, original_EMG_SR] = concatenateEMGData(monkey_prefix, experiment_day, validate_file_range, EMG_num, full_monkey_name);
    concatenated_EMG_data = resample(concatenated_EMG_data, downsample_rate, original_EMG_SR);

    %% cut  data on task timing
    switch monkey_prefix
        case {'Ya', 'F'}
            transposed_success_timing = processLeverPullTaskEvents(monkey_prefix,experiment_day,validate_file_range,downsample_rate,TimeRange_EMG);
        case 'Se'
            %{
                + this case was written by Naoki Uchida.
                + I (Ohta) don't know the detail of this script
            %}
            [transposed_success_timing, TTLd, TTLu] = processLeverPullTaskEvents(monkey_prefix,experiment_day,validate_file_range,downsample_rate,TimeRange_EMG);
            % change tiing from 'lever2' to 'photocell'
            errorlist = '';
            emp_d = 0;
            emp_u = 0;
            ph_d = zeros(length(transposed_success_timing),1); % photo down clock = Photo On
            ph_u = zeros(length(transposed_success_timing),1); % photo up clock = Photo Off
            for i = 1:length(transposed_success_timing)
                if isempty(max(TTLd((transposed_success_timing(i,3)<TTLd).*(TTLd<transposed_success_timing(i,5)))))
                    emp_d = 1;
                else
                    ph_d(i) = min(TTLd((transposed_success_timing(i,3)<TTLd).*(TTLd<transposed_success_timing(i,5))));
                end
                if isempty(max(TTLu((transposed_success_timing(i,3)<TTLu).*(TTLu<transposed_success_timing(i,5)))))
                    emp_u = 1;
                else
                    ph_u(i) = max(TTLu((transposed_success_timing(i,3)<TTLu).*(TTLu<transposed_success_timing(i,5))));
                end
                if ph_d(i)>ph_u(i) || emp_d == 1 || emp_u ==1
                    errorlist = [errorlist ' ' sprintf('%d',i)];
                    emp_d = 0;
                    emp_u = 0;
                end
                transposed_success_timing(i,4) = ph_d(i);
                transposed_success_timing(i,5) = ph_u(i); % Change timings 4 and 5 to 'photo-on' and 'photo-off' timings
            end
            if ~isempty(errorlist)
                ER = str2num(errorlist);
                for ii = flip(ER)
                    transposed_success_timing(ii,:) = [];
                end
            end
        case 'Ni'
            transposed_success_timing = processSimpleGraspTaskEvents(full_monkey_name, monkey_prefix, experiment_day, validate_file_range, downsample_rate);
        case 'Hu'
            success_button_count_threshold = 80;
            transposed_success_timing = processDrawerTaskEvents(full_monkey_name, monkey_prefix, experiment_day, validate_file_range, downsample_rate, success_button_count_threshold, time_restriction_enabled, trial_time_threshold);
    end
    success_timing = transpose(transposed_success_timing);
    success_timing = [success_timing; success_timing(end, :) - success_timing(1, :)];

    %% save data
    Unit = 'uV';
    common_sample_rate = downsample_rate;
    cutout_EMG_data_save_dir_path = fullfile(common_save_figure_path, 'cutout_EMG_data_list');
    makefold(cutout_EMG_data_save_dir_path);
    save(fullfile(cutout_EMG_data_save_dir_path, [monkey_prefix experiment_day '_cutout_EMG_data.mat']), 'concatenated_EMG_data', 'common_sample_rate', 'EMG_name_list', 'TimeRange_EMG', 'transposed_success_timing', 'Unit');

    success_timing_data_save_dir_path = fullfile(common_save_figure_path, 'success_timing_data_list', experiment_day);
    makefold(success_timing_data_save_dir_path);
    success_timing_file_name = 'success_timing';
    if time_restriction_enabled
        success_timing_file_name = [success_timing_file_name '(' num2str(trial_time_threshold) '[sec]_restriction)'];
    end
    save(fullfile(success_timing_data_save_dir_path, [success_timing_file_name '.mat']), 'success_timing');
end