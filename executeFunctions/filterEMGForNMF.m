%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[Operation]
1. Navigate to the executeFunctions directory.
2. Change some parameters (refer to 'set param' section)
3. Run this code

[Role of this code]
Perform preprocessing on EMG data and save the filtered data as a .mat file.
The sequence of filters applied is:
1. High-pass filter
2. Rectification
3. Low-pass filter
4. Downsampling

[Saved data location]
The location of the saved file is shown in the log when this function is executed.

[Procedure]
Pre: prepareRawEMGDataForNMF.m
Post: synergyExtractionByNMF.m

[Caution]
The functions loaddata and makeContinuousChannel.m were created by Takei-san. They are complex and have not been refactored, so they are used as is.

[Improvement Points]
- Add error handling for missing raw data for the specified extract_EMG_type (suggest running prepareRawEMGDataForNMF)
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

%% Set parameters
monkey_prefix = 'Hu'; % Prefix of the recorded file
extract_EMG_type = 'only_trial'; % Data extraction mode: 'full', 'only_trial', 'only_drawer', 'only_food'

% Filter settings
band_pass_flag = false;
high_pass_flag = true;
rect_flag = true;
low_pass_flag = true;
resample_flag = true;

% Cut-off frequency settings
band_pass_freq = [50 200]; % Band-pass filter cut-off frequency [Hz]
high_pass_freq = 50; % High-pass filter cut-off frequency [Hz]
low_pass_freq = 20; % Low-pass filter cut-off frequency [Hz]
resample_freq = 100; % Sampling rate [Hz] after downsampling

%% Code section
full_monkey_name = getFullMonkeyName(monkey_prefix);
root_dir_path = fileparts(pwd);
base_dir_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'Synergy', 'row_EMG_data', extract_EMG_type);

% Get the name of the folder directly under 'Parent dir'
unique_name_list = dirdir(base_dir_path);
disp('【Please select all day folders containing the data you want to filter】')
unique_name_list = uiselect(unique_name_list, 1, 'Please select folders containing the data you want to analyze');

if isempty(unique_name_list)
    disp('User pressed cancel. No folders selected. Exiting process.');
    return;
end
ref_unique_name = unique_name_list{1};

muscle_file_list = dirPlus(fullfile(base_dir_path, ref_unique_name));
raw_EMG_file_names = {muscle_file_list.name};
disp('【Please select all muscle data (<muscle name>(uV).mat) you want to filter】')
raw_EMG_file_names = uiselect(raw_EMG_file_names, 1, 'Please select all muscle data');
if isempty(raw_EMG_file_names)
    disp('User pressed cancel. No muscle data selected. Exiting process.');
    return;
end

% Check if raw data exists
if isempty(raw_EMG_file_names)
    error('No raw EMG data found for the specified extract_EMG_type. Please run prepareRawEMGDataForNMF to generate the necessary data.');
end

ref_raw_EMG_data = load(fullfile(base_dir_path, ref_unique_name, raw_EMG_file_names{1}));
trimmed_flag = false;
if isfield(ref_raw_EMG_data, 'event_timings_after_trimmed')
    trimmed_flag = true;
end
clear ref_raw_EMG_data;

common_save_dir = strrep(base_dir_path, 'row_EMG_data', 'filtered_EMG_data');
for day_id = 1:length(unique_name_list)
    ref_unique_name = unique_name_list{day_id};
    disp(['Processing day: ', ref_unique_name]);
    for muscle_id = 1:length(raw_EMG_file_names)
        disp(['  Processing muscle: ', raw_EMG_file_names{muscle_id}]);
        ref_EMG_data_struct = loaddata(fullfile(base_dir_path, ref_unique_name, raw_EMG_file_names{muscle_id}));
        ref_EMG_data_struct.filter_detail_name = ref_EMG_data_struct.muscle_name;
        if band_pass_flag
            ref_EMG_data_struct = makeContinuousChannel([ref_EMG_data_struct.filter_detail_name, '-bandpass-', num2str(band_pass_freq(1)), 'Hz_to_', num2str(band_pass_freq(2)), 'Hz'], 'band-pass', ref_EMG_data_struct, band_pass_freq);
        end

        if high_pass_flag
            % High-pass filtering
            ref_EMG_data_struct = makeContinuousChannel([ref_EMG_data_struct.filter_detail_name, '-hp', num2str(high_pass_freq), 'Hz'], 'butter', ref_EMG_data_struct, 'high', 6, high_pass_freq, 'both');
        end

        if rect_flag
            % Full wave rectification
            ref_EMG_data_struct = makeContinuousChannel([ref_EMG_data_struct.filter_detail_name, '-rect'], 'rectify', ref_EMG_data_struct);
        end

        if low_pass_flag
            % Low-pass filtering
            ref_EMG_data_struct = makeContinuousChannel([ref_EMG_data_struct.filter_detail_name, '-lp', num2str(low_pass_freq), 'Hz'], 'butter', ref_EMG_data_struct, 'low', 6, low_pass_freq, 'both');
        end

        if resample_flag
            % Downsampling at 100Hz
            if trimmed_flag
                ref_EMG_data_struct.event_timings_after_trimmed = round(ref_EMG_data_struct.event_timings_after_trimmed * (resample_freq / ref_EMG_data_struct.common_sample_rate));
            end
            ref_EMG_data_struct = makeContinuousChannel([ref_EMG_data_struct.filter_detail_name, '-ds', num2str(resample_freq), 'Hz'], 'resample', ref_EMG_data_struct, resample_freq, 0);
        end

        % Save data
        save_dir_path = fullfile(common_save_dir, ref_unique_name);
        makefold(save_dir_path);
        save(fullfile(save_dir_path, [ref_EMG_data_struct.filter_detail_name, '.mat']), '-struct', 'ref_EMG_data_struct');
        disp(['  Data saved to: ', fullfile(save_dir_path, [ref_EMG_data_struct.filter_detail_name, '.mat'])]);
    end
end
