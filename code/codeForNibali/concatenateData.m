%{
[explanation of this func]:
this func is used in 'generarteRawData.m'
concatenate each data(CAI, CLFP, etc...) which is included in recorded data by AlphaOmega for 1day and output each of these concatenated data as structure

[input arguments]
base_dir: [char], directory path of reference
exp_day: [char], day of experimet
monkeyname:[char], prefix of recorded file
downHz:[double], sampling rate after resampling
record_time: [double], record time of EMG signal

[output arguments]
CAI_str: [struct], contains various file which is related to CAI signal
CLFP_str: [struct], contains various file which is related to CLFP signal
CRAW_str: [struct], contains various file which is related to CRAW signal
CTTL_str:  [struct], contains various file which is related to CTTL signal

[Improvement Point]
・CTTL==2の場合にも対応していたが、流石に3つ無いとダメなので消した
=> エラー吐いたらその時対応する => 吐かなかった
・1ファイルの中でCTTL_003のUPとDOWNの数の差分における条件分位が冗長だからもう少し簡潔にする
%}

function [CAI_str, CLFP_str, CRAW_str, CTTL_str] = concatenateData(base_dir, exp_day, monkeyname, downHz, record_time)

%% code section
base_dir = fullfile(base_dir, exp_day);
AO_file_list = dir(fullfile(base_dir, [monkeyname '*.mat'])); % get the name of files that are recorded by AlphaOmega
AO_file_num = length(AO_file_list);

% load all raw data & store as struct type
all_data_cell = cell(AO_file_num, 1);
for file_id = 1:AO_file_num
    all_data_cell{file_id} = load(fullfile(base_dir, AO_file_list(file_id).name));
end

% refer to the file to obtain some parameters
initial_data = all_data_cell{1};
vars = fieldnames(initial_data);

CTTL_pattern = '^CTTL.*_KHz$';
CTTL_signal_num = length(vars(~cellfun('isempty', regexp(vars, CTTL_pattern))));
CTTL_KHz_name = vars(~cellfun('isempty', regexp(vars, CTTL_pattern)));
CTTL_original_SR = initial_data.(CTTL_KHz_name{1}) * 1000;

CLFP_pattern = '^CLFP.*_KHz$';
CLFP_signal_num = length(vars(~cellfun('isempty', regexp(vars, CLFP_pattern))));

CRAW_pattern = '^CRAW.*_KHz$';
CRAW_signal_num = length(vars(~cellfun('isempty', regexp(vars, CRAW_pattern))));

CAI_pattern = '^CAI.*_KHz$';
CAI_file_num = length(vars(~cellfun('isempty', regexp(vars, CAI_pattern))));

%% resample CAI & combine multi file
task_start_time = initial_data.CTTL_001_TimeBegin;

% Align start between EMG and AO_file data
CAI_str = struct();
for channel_id = 1:length(CAI_file_num)
    [TimeRange,CAI_str] = AlignStart(all_data_cell, CAI_str, downHz, record_time, exp_day, 'CAI', channel_id,task_start_time);
end

CLFP_str = struct();
for channel_id = 1:CLFP_signal_num
    [~, CLFP_str] = AlignStart(all_data_cell, CLFP_str, downHz, record_time, exp_day, 'CLFP', channel_id,task_start_time);
end

CRAW_str = struct();
for channel_id = 1:CRAW_signal_num
    [~, CRAW_str] = AlignStart(all_data_cell, CRAW_str, downHz, record_time, exp_day, 'CRAW', channel_id,task_start_time);
end

%% resample CTTL & combine multi file
CTTL_str = struct();
% set the value to multiply the TTL signal to make it match the down-sampled analog signal(CAI, EMG, ...)
multiplicand = downHz / CTTL_original_SR;
for file_id = 1:AO_file_num
    each_CTTL_str = extractStruct(all_data_cell{file_id}, '^CTTL');

    for TTL_id= 2:CTTL_signal_num 
        % obtain the name of the variable corresponds to each TTL_id data
        vars = fieldnames(each_CTTL_str);
        Up_data_name = vars(contains(vars, sprintf('%03d', TTL_id)) & contains(vars, 'Up'));
        Down_data_name = vars(contains(vars, sprintf('%03d', TTL_id)) & contains(vars, 'Down'));
        TimeBegin_name = vars(contains(vars, sprintf('%03d', TTL_id)) & contains(vars, 'TimeBegin'));
        TimeEnd_name = vars(contains(vars, sprintf('%03d', TTL_id)) & contains(vars, 'TimeEnd'));
        KHz_name = vars(contains(vars, sprintf('%03d', TTL_id)) & contains(vars, '_KHz'));
        
        % (if there is no corresponding file)
        if and(isempty(Up_data_name), isempty(Down_data_name))
            disp([exp_day '_' AO_file_list(file_id).name ' does not have CTTL' sprintf('%03d', TTL_id)]);
            continue;
        end

        % exclude timing data (which is so close to adjacent timing data)
        if TTL_id == 3
            Up_data = each_CTTL_str.(Up_data_name{1});
            Down_data = each_CTTL_str.(Down_data_name{1});

            if length(Up_data) == length(Down_data)
                success_signal = [Up_data; Down_data];
            elseif length(Up_data) > length(Down_data)
                success_signal = [Up_data(1:length(Down_data)); Down_data];
                surplus_data = Up_data(length(Down_data)+1:end);
                pre_start = each_CTTL_str.(TimeBegin_name{1});
            else
                error_time = each_CTTL_str.(TimeBegin_name{1}) - pre_start;
                error_sample = round(error_time * (each_CTTL_str.(KHz_name{1}) * 1000));
                filled_data = surplus_data - error_sample;
                success_signal = [[filled_data Up_data]; Down_data];
            end

            % find trial _id which is excluded & remove data by refering to this information
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
            each_CTTL_str.(Up_data_name{1}) = success_signal(1, :);
            each_CTTL_str.(Down_data_name{1}) = success_signal(2, :);
        end

        % resample & store this data into 'CTTL_str' (this is cell array for concatenating)
        CTTL_str.(Up_data_name{1}){1, file_id}= round(each_CTTL_str.(Up_data_name{1}) * multiplicand);
        CTTL_str.(Down_data_name{1}){1, file_id}= round(each_CTTL_str.(Down_data_name{1}) * multiplicand);
        CTTL_str.(TimeBegin_name{1}){1, file_id}= each_CTTL_str.(TimeBegin_name{1});
        CTTL_str.(TimeEnd_name{1}){1, file_id}= each_CTTL_str.(TimeEnd_name{1});
    end
end

% add error sampling(between 'record_start' and '1st rising time of each TTL signal')
for TTL_id = 2:CTTL_signal_num 
    vars = fieldnames(CTTL_str);
    Up_data_name = vars(contains(vars, sprintf('%03d', TTL_id)) & contains(vars, 'Up'));
    Down_data_name = vars(contains(vars, sprintf('%03d', TTL_id)) & contains(vars, 'Down'));
    TimeBegin_name = vars(contains(vars, sprintf('%03d', TTL_id)) & contains(vars, 'TimeBegin'));
    TimeEnd_name = vars(contains(vars, sprintf('%03d', TTL_id)) & contains(vars, 'TimeEnd'));
    
    ref_TTL_valid_file_num = length(CTTL_str.(TimeBegin_name{1}));
    for file_id = 1:ref_TTL_valid_file_num
        % make up for the error sampling
        error_sampling = round((CTTL_str.(TimeBegin_name{1}){file_id} - TimeRange(1,1)) * downHz);
        CTTL_str.(Down_data_name{1}){file_id} = error_sampling + CTTL_str.(Down_data_name{1}){file_id};
        CTTL_str.(Up_data_name{1}){file_id} = error_sampling + CTTL_str.(Up_data_name{1}){file_id};
    end

    % concatenate & store
    CTTL_str.(Up_data_name{1}) = cell2mat(CTTL_str.(Up_data_name{1}));
    CTTL_str.(Down_data_name{1}) = cell2mat(CTTL_str.(Down_data_name{1}));
    CTTL_str.(TimeBegin_name{1}) = TimeRange(1, 1);
    CTTL_str.(TimeEnd_name{1}) = CTTL_str.(TimeEnd_name{1}){end};
    CTTL_str.(['CTTL_' sprintf('%03d', TTL_id) '_KHz']) = downHz / 1000;
    CTTL_str.(['CTTL_' sprintf('%03d', TTL_id) '_KHz_Orig']) = downHz / 1000;
end
end




