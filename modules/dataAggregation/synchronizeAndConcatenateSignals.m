%{
[Function Description]
This function synchronizes and concatenates signals from multiple AlphaOmega data files.
It resamples signals to a common frequency and aligns them with EMG recording timing.
The function handles various signal types (CAI, CLFP, CRAW) and ensures proper timing alignment.

[Input Arguments]
all_alphaOmega_data_cell: [cell array] Cell array containing loaded data from each raw data file
ref_signal_struct: [struct] Structure to store the processed data
common_frequency: [double] Target sampling rate (Hz) for resampling
record_time: [double] Total recording time in seconds
experiment_day_name: [char] Name of the experiment day
ref_signal_name: [char] Type of signal to process (e.g., 'CAI', 'CLFP')
ref_channel_id: [double] Channel ID to process
task_start_time: [double] Start time of EMG recording in seconds

[Output Arguments]
TimeRange: [double array] Array containing start and end times of recording [start_time, end_time]
ref_signal_struct: [struct] Structure containing processed and aligned signal data

[detail of this process(Japanese)]
1. CTTL_001は、記録の'開始'と'終了'のタイミングに対応するタイミングデータ
2. EMGの最初のサンプルと、CTTL_001の最初のタイミングを合わせるため、AlphaOmegaのデータをタイミング調整する必要がある
3. 同様に、終了タイミング以降のAlphaOmegaファイルの内容を削除する必要がある

[caution(Japanese)]
終了と開始が一致している場合、trash_data_timeが0になるため、この関数を使用する際は注意が必要
%}

function [TimeRange, ref_signal_struct] = synchronizeAndConcatenateSignals(all_alphaOmega_data_cell, ref_signal_struct, common_frequency, record_time, experiment_day_name, ref_signal_name, ref_channel_id, task_start_time) 
    AlphaOmega_file_num = length(all_alphaOmega_data_cell);
    signal_cell_for_integrate = cell(1, AlphaOmega_file_num);
    ref_data_file_name = [ref_signal_name '_' sprintf('%03d', ref_channel_id)];

    for file_idx = 1:AlphaOmega_file_num 
        try
            ref_data = all_alphaOmega_data_cell{file_idx}.(ref_data_file_name);
        catch
            % process if data file (corresponds to file_idx) does't have field corresponds to 'ref_data_file_name'
            if ref_channel_id == 1
                disp([experiment_day_name '-file' num2str(file_idx) ' does not contains ' ref_signal_name ' signal'])
            end
            continue;
        end

        % cast & reasample
        ref_data = cast(ref_data, 'double');
        original_signal_SR = all_alphaOmega_data_cell{file_idx}.([ref_data_file_name '_KHz']) * 1000;
        ref_data = resample(ref_data, common_frequency, original_signal_SR);

        if file_idx==1
            % start timing of EMG_record(correspond to CTTL_001_TimeBegin)
            record_start_time = task_start_time;
            record_end_time = record_start_time + record_time;
            TimeRange(1,1) = record_start_time;
            TimeRange(1,2) = record_end_time;

            % trash(align start)
            trash_data_time = record_start_time - all_alphaOmega_data_cell{file_idx}.([ref_data_file_name '_TimeBegin']);
            if strcmp(ref_signal_name, 'CAI')
                disp(['    ' experiment_day_name ' trash time (before start): ' num2str(trash_data_time) '[s]']);
            end
            trash_sample_num = round(trash_data_time * common_frequency);

            % convert - value to 0
            if trash_sample_num < 0 && abs(trash_sample_num) < 100 
                trash_sample_num = 0;
            end
            ref_data = ref_data(trash_sample_num+1:end);

        elseif all_alphaOmega_data_cell{file_idx}.([ref_data_file_name '_TimeEnd']) > TimeRange(2) 
            % trash(align end)
            trash_data_time =  all_alphaOmega_data_cell{file_idx}.([ref_data_file_name '_TimeEnd']) - TimeRange(2); 
            if and(strcmp(ref_signal_name, 'CAI'), file_idx == AlphaOmega_file_num)
                disp(['    ' experiment_day_name ' trash time (after end): ' num2str(trash_data_time) '[s]']);
            end
            trash_sample_num = round(common_frequency * trash_data_time);
            last_sample_idx = length(ref_data) - trash_sample_num;
            ref_data = ref_data(1:last_sample_idx);
        end

        % store the data from this file
        signal_cell_for_integrate{1, file_idx} = ref_data;
    end
    integrated_signal_data = cell2mat(signal_cell_for_integrate);

    % add necessary information into 'signal struct'
    ref_signal_struct.(ref_data_file_name) = integrated_signal_data;
    ref_signal_struct.([ref_data_file_name '_BitResolution']) = all_alphaOmega_data_cell{1}.([ref_data_file_name '_BitResolution']);
    ref_signal_struct.([ref_data_file_name '_Gain']) = all_alphaOmega_data_cell{1}.([ref_data_file_name '_Gain']);
    ref_signal_struct.([ref_data_file_name '_KHz']) = common_frequency / 1000;
    ref_signal_struct.([ref_data_file_name '_KHz_Orig']) = common_frequency / 1000;
    ref_signal_struct.([ref_data_file_name '_TimeBegin']) = TimeRange(1, 1);
    ref_signal_struct.([ref_data_file_name '_TimeEnd']) = TimeRange(1,2);
end

