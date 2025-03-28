%{
[Function Description]
This function integrates and processes data recorded by AlphaOmega for a single experiment day.
It concatenates multiple data files, resamples signals to a common frequency, and aligns timing data.
The function handles CAI, CLFP, CRAW, and CTTL signals, ensuring proper synchronization
between different data types and with EMG recordings from the Ripple system.

[Input Arguments]
base_dir_path: [char] Path to the base directory containing experiment day folders
experiment_day_name: [char] Name of the experiment day folder
monkey_prefix: [char] Prefix of recorded file names
common_frequency: [double] Target sampling rate (Hz) for resampling data
record_time: [double] Total recording time in seconds

[Output Arguments]
CAI_struct: [struct] Contains formatted CAI (analog input) data with fields:
    - CAI_XXX: [double array] CAI signal data
    - CAI_XXX_KHz: [double] Sampling rate in kHz
CLFP_struct: [struct] Contains formatted CLFP data with similar fields
CRAW_struct: [struct] Contains formatted CRAW data with similar fields
CTTL_struct: [struct] Contains formatted CTTL data with fields

[Improvement Point(Japanese)]
1. 1ファイル内でCTTL_002のUPとDOWNの数の不一致に対する処理が実装されていないため定義が必要
2. 1ファイル内でCTTL_003のUPとDOWNの数の不一致に対する処理が不十分な場合があるため改善が必要
%}

function [CAI_struct, CLFP_struct, CRAW_struct, CTTL_struct] = integrateAlphaOmegaData(base_dir_path, experiment_day_name, monkey_prefix, common_frequency, record_time)
try
    fprintf ('\n');
    disp('<start  AlphaOmega data format>')
    base_dir_path = fullfile(base_dir_path, experiment_day_name);
    alphaOmega_file_list = dirPlus(fullfile(base_dir_path, [monkey_prefix '*.mat'])); % get the name of files that are recorded by AlphaOmega
    alphaOmega_file_num = length(alphaOmega_file_list);
    if isempty(alphaOmega_file_list)
        warning(['There was a problem with the processing of ' experiment_day_name '. Please fix the promlem and run again']);
        warning(['No .mat files found that match the conditions. Please check if the .mat files prefix in ' experiment_day_name ' folder are "' monkey_prefix '"']);
        return;
    end

    % load all raw data & store as struct type
    all_alphaOmega_data_cell = cell(alphaOmega_file_num, 1);
    for file_id = 1:alphaOmega_file_num
        all_alphaOmega_data_cell{file_id} = load(fullfile(base_dir_path, alphaOmega_file_list(file_id).name));
    end

    %obtain some parameters(number of TTL_signal, CAI_signal, LFP_signal etc...)
    initial_file_data = all_alphaOmega_data_cell{1};
    field_name_list = fieldnames(initial_file_data);

    CTTL_common_string_pattern = '^CTTL.*_KHz$';
    CTTL_KHz_name = field_name_list(~cellfun('isempty', regexp(field_name_list, CTTL_common_string_pattern)));
    CTTL_signal_num = length(CTTL_KHz_name);
    CTTL_original_SR = initial_file_data.(CTTL_KHz_name{1}) * 1000;

    % Obtain CLFP and CRAW signal numbers
    CLFP_signal_names = field_name_list(~cellfun('isempty', regexp(field_name_list, '^CLFP.*_KHz$')));
    CLFP_signal_num = length(CLFP_signal_names);
    CLFP_signal_indices = cellfun(@(x) sscanf(x, 'CLFP_%d_KHz'), CLFP_signal_names);

    CRAW_signal_names = field_name_list(~cellfun('isempty', regexp(field_name_list, '^CRAW.*_KHz$')));
    CRAW_signal_num = length(CRAW_signal_names);
    CRAW_signal_indices = cellfun(@(x) sscanf(x, 'CRAW_%d_KHz'), CRAW_signal_names);

    CAI_common_string_pattern = '^CAI.*_KHz$';
    CAI_file_num = length(field_name_list(~cellfun('isempty', regexp(field_name_list, CAI_common_string_pattern))));

    %% resample CAI & combine multi file
    recording_start_time = initial_file_data.CTTL_001_TimeBegin;

    % Align start between EMG and AO_file data
    CAI_struct = struct();
    for channel_id = 1:length(CAI_file_num)
        [TimeRange,CAI_struct] = synchronizeAndConcatenateSignals(all_alphaOmega_data_cell, CAI_struct, common_frequency, record_time, experiment_day_name, 'CAI', channel_id, recording_start_time);
    end

    % Process CLFP signals
    CLFP_struct = struct();
    for i = 1:CLFP_signal_num
        channel_id = CLFP_signal_indices(i);
        [~, CLFP_struct] = synchronizeAndConcatenateSignals(all_alphaOmega_data_cell, CLFP_struct, common_frequency, record_time, experiment_day_name, 'CLFP', channel_id, recording_start_time);
    end

    % Process CRAW signals
    CRAW_struct = struct();
    for i = 1:CRAW_signal_num
        channel_id = CRAW_signal_indices(i);
        [~, CRAW_struct] = synchronizeAndConcatenateSignals(all_alphaOmega_data_cell, CRAW_struct, common_frequency, record_time, experiment_day_name, 'CRAW', channel_id, recording_start_time);
    end

    %% resample CTTL & combine multi file
    CTTL_struct = struct();
    % set the value to multiply the TTL signal to make it match the down-sampled analog signal(CAI, EMG, ...)
    resampling_factor = common_frequency / CTTL_original_SR;
    for file_id = 1:alphaOmega_file_num
        ref_alphaOmega_file_data = all_alphaOmega_data_cell{file_id};
        ref_file_CTTL_ctruct = getMatchingFields(ref_alphaOmega_file_data , '^CTTL');

        for TTL_id= 2:CTTL_signal_num 
            ref_timing_common_name = ['CTTL_' sprintf('%03d', TTL_id)];
            Up_data_name = [ref_timing_common_name '_Up'];
            Down_data_name = [ref_timing_common_name '_Down'];
            TimeBegin_name = [ref_timing_common_name '_TimeBegin'];
            TimeEnd_name = [ref_timing_common_name '_TimeEnd'];
            KHz_name = [ref_timing_common_name '_KHz'];
            
            % (if there is no corresponding file)
            if and(isempty(Up_data_name), isempty(Down_data_name))
                disp([experiment_day_name '_' alphaOmega_file_list(file_id).name ' does not have CTTL' sprintf('%03d', TTL_id)]);
                continue;
            end
            
            % Check if the fields exist in the structure
            if ~isfield(ref_file_CTTL_ctruct, Up_data_name) || ~isfield(ref_file_CTTL_ctruct, Down_data_name)
                disp(['Warning: ' experiment_day_name '_' alphaOmega_file_list(file_id).name ' does not have ' Up_data_name ' or ' Down_data_name]);
                continue;
            end
            
            Up_data = ref_file_CTTL_ctruct.(Up_data_name);
            Down_data = ref_file_CTTL_ctruct.(Down_data_name);
            if length(Up_data) > length(Down_data)
                if TTL_id == 2
                    % CTTL002_Downはfood onのタイミングなので、CTTL002_Up(food off)はCTTL_002_Downの後に来なければいけない
                    first_Down_data = Down_data(1);
                    Up_data = Up_data(Up_data > first_Down_data);
                end
                Up_data = Up_data(1: length(Down_data));
            elseif length(Up_data) < length(Down_data)
                if TTL_id == 3
                    % CTTL003_Upはsuccess_timingを押したタイミングなので、CTTL003_Down(ボタンを話したタイミングは)はCTTL_003_Upの後に来なければいけない
                    first_Up_data = Up_data(1);
                    Down_data = Down_data(Down_data > first_Up_data);
                end
                Down_data = Down_data(1 : length(Up_data));
            end

            % CTTL_003 is unstable signals, so need filtering
            if TTL_id == 3
                success_signal = [Up_data; Down_data];
                exclude_data_id = [];
                for trial_id = 1:length(success_signal)
                    judge_frame = success_signal(2, trial_id) - success_signal(1, trial_id);
                    if judge_frame < 100
                        % append trial_id into exclude_data_id
                        exclude_data_id = [exclude_data_id trial_id];
                    end
                end
                % exclude
                success_signal(:, exclude_data_id) = [];
                Up_data = success_signal(1, :);
                Down_data = success_signal(2, :);
            end

            % resample & store this data into 'CTTL_struct' (this is cell array for concatenating)
            if ~isempty(Up_data) && ~isempty(Down_data)
                if ~isfield(CTTL_struct, Up_data_name)
                    CTTL_struct.(Up_data_name) = cell(1, alphaOmega_file_num);
                end
                if ~isfield(CTTL_struct, Down_data_name)
                    CTTL_struct.(Down_data_name) = cell(1, alphaOmega_file_num);
                end
                if ~isfield(CTTL_struct, TimeBegin_name)
                    CTTL_struct.(TimeBegin_name) = cell(1, alphaOmega_file_num);
                end
                if ~isfield(CTTL_struct, TimeEnd_name)
                    CTTL_struct.(TimeEnd_name) = cell(1, alphaOmega_file_num);
                end
                
                CTTL_struct.(Up_data_name){1, file_id} = round(Up_data * resampling_factor);
                CTTL_struct.(Down_data_name){1, file_id} = round(Down_data * resampling_factor);
                CTTL_struct.(TimeBegin_name){1, file_id} = ref_file_CTTL_ctruct.(TimeBegin_name);
                CTTL_struct.(TimeEnd_name){1, file_id} = ref_file_CTTL_ctruct.(TimeEnd_name);
            else
                disp(['Warning: Empty Up_data or Down_data for ' ref_timing_common_name ' in file ' num2str(file_id)]);
            end
        end
    end

    % align the criteia for number of elapsed samples with 'recordingStart'(TimeRange(1,1))
    for TTL_id = 2:CTTL_signal_num 
        ref_timing_common_name = ['CTTL_' sprintf('%03d', TTL_id)];
        Up_data_name = [ref_timing_common_name '_Up'];
        Down_data_name = [ref_timing_common_name '_Down'];
        TimeBegin_name = [ref_timing_common_name '_TimeBegin'];
        TimeEnd_name = [ref_timing_common_name '_TimeEnd'];

        % Skip if the fields don't exist in the structure
        if ~isfield(CTTL_struct, Up_data_name) || ~isfield(CTTL_struct, Down_data_name) || ~isfield(CTTL_struct, TimeBegin_name) || ~isfield(CTTL_struct, TimeEnd_name)
            disp(['Skipping concatenation for ' ref_timing_common_name ' - fields not found']);
            continue;
        end
        
        % Skip if the fields are empty
        if isempty(CTTL_struct.(TimeBegin_name))
            disp(['Skipping concatenation for ' ref_timing_common_name ' - no data available']);
            continue;
        end

        ref_TTL_valid_file_num = length(CTTL_struct.(TimeBegin_name));
        for file_id = 1:ref_TTL_valid_file_num
            % Skip empty cells
            if isempty(CTTL_struct.(TimeBegin_name){file_id}) || ...
               isempty(CTTL_struct.(Up_data_name){file_id}) || ...
               isempty(CTTL_struct.(Down_data_name){file_id})
                continue;
            end
            
            % Calculate time offset in seconds and convert to samples
            time_offset_seconds = CTTL_struct.(TimeBegin_name){file_id} - TimeRange(1,1);
            time_offset_samples = round(time_offset_seconds * common_frequency);
            CTTL_struct.(Down_data_name){file_id} = time_offset_samples + CTTL_struct.(Down_data_name){file_id};
            CTTL_struct.(Up_data_name){file_id} = time_offset_samples + CTTL_struct.(Up_data_name){file_id};
        end

        % concatenate & store
        % Remove empty cells before concatenation
        valid_indices = ~cellfun('isempty', CTTL_struct.(Up_data_name));
        if any(valid_indices)
            CTTL_struct.(Up_data_name) = cell2mat(CTTL_struct.(Up_data_name)(valid_indices));
        else
            CTTL_struct.(Up_data_name) = [];
        end
        
        valid_indices = ~cellfun('isempty', CTTL_struct.(Down_data_name));
        if any(valid_indices)
            CTTL_struct.(Down_data_name) = cell2mat(CTTL_struct.(Down_data_name)(valid_indices));
        else
            CTTL_struct.(Down_data_name) = [];
        end
        
        CTTL_struct.(TimeBegin_name) = TimeRange(1, 1);
        
        % Handle the case where TimeEnd_name might contain empty cells
        valid_indices = ~cellfun('isempty', CTTL_struct.(TimeEnd_name));
        if any(valid_indices)
            CTTL_struct.(TimeEnd_name) = CTTL_struct.(TimeEnd_name){find(valid_indices, 1, 'last')};
        else
            CTTL_struct.(TimeEnd_name) = TimeRange(1, 1) + record_time; % Default to recording end time
        end
        
        CTTL_struct.(['CTTL_' sprintf('%03d', TTL_id) '_KHz']) = common_frequency / 1000;
        CTTL_struct.(['CTTL_' sprintf('%03d', TTL_id) '_KHz_Orig']) = common_frequency / 1000;
    end
    disp('<end  AlphaOmega data format>')
catch ME
    % Display detailed error information
    disp('<ERROR in AlphaOmega data processing>')
    disp(['Error in ' experiment_day_name ': ' ME.message]);
    disp(['Error occurred in ' ME.stack(1).name ' at line ' num2str(ME.stack(1).line)]);
    disp('Stack trace:');
    for i = 1:length(ME.stack)
        disp(['   ' ME.stack(i).name ' (line ' num2str(ME.stack(i).line) ')']);
    end
    disp('</ERROR>')
    % Re-throw the error to be caught by the calling function
    rethrow(ME);
end
end




