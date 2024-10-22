%{
[explanation of this func]:
extracting the contents of EMG record files as variables that can be used in MATLAB

[input arguments]
base_dir: [char], path of base directory
exp_day: folder name which contains recorded EMG data(.nev file) you want to analyze 
down_sampleRate:[double], sampling rate after down sampling

[output arguments]
CEMG: [struct], contains all electrode signal(all EMG data) and other information (ex. sampling rate of signal)
amplitude_unit: [char], unit of EMG amplitude
record_time: [double], recording time of EMG signal (unit is second [s])

[caution(japanese)]
nev�t�@�C����mat�t�@�C��������
(mat�t�@�C����nev�t�@�C����ǂݍ��߂Ȃ�����������, �Ǝ҂�mat�t�@�C���ɂ��ăf�[�^(hFile)�𑗂��Ă�����Ă����̃f�[�^)
=> ����ns_Open��full_path���͂���΂�����ƕ����ĉ��P�����̂ŁA��{mat�͎g��Ȃ��͂�

[Improvement point(japanese)]
nev�t�@�C�����������鎞�ɑΉ����Ă��Ȃ��̂ŁA�l����
nev���ǂݍ��߂Ȃ���������.mat�ǂݍ��ݕ������������̂ŁA�G���[�f�����炻�̎��ɍl����
%}

function [CEMG, amplitude_unit, record_time] = generateEMG(base_dir, exp_day, down_sampleRate)
EMG_files_dir = fullfile(base_dir, exp_day);
EMG_files = dir(fullfile(EMG_files_dir, 'datafile*.ns5'));

file_num = length(EMG_files);
EMG_element_cell = cell(1, file_num);
record_time_element = nan(1, file_num);
CEMG = struct;

for file_id = 1:length(EMG_files)
    ref_EMG_file_path = fullfile(EMG_files_dir, EMG_files(file_id).name);
    [~, hFile] = ns_OpenFile(ref_EMG_file_path); 
    try
        [start_num, end_num] = get_EMG_electrode_num(hFile);
    catch
        % This file does not contain EMG electrode signals, so continue
        continue;
    end
    EMG_id = 1;
    for idx = start_num:2:end_num-1
        try
            % get EMG signal from both electrode
            [~, ~, EMG_signal1] = ns_GetAnalogData(hFile, idx, 1, 1e10);
            [~, ~, EMG_signal2] = ns_GetAnalogData(hFile, idx+1, 1, 1e10);
        catch
            % For some reason, the signal obtained from the binary file is empty, so the data from this file is discarded
            break;
        end
        
        % take the difference
        EMG_signal = transpose(EMG_signal1 - EMG_signal2);
    
        % compile the information of record(samplingRate, rosolution, etc...)
        if idx == start_num
            [~, record_info] = ns_GetAnalogInfo(hFile, idx);
            original_sampleRate = record_info.SampleRate;
            amplitude_unit = record_info.Units;
            muscle_num = ((end_num - start_num) + 1) / 2;
            EMG_element_cell{file_id} = cell(muscle_num, 1);
            record_time_element(file_id) = length(EMG_signal) / original_sampleRate;
        end
    
        % store the signal & informations
        ref_signal = EMG_signal * hFile.Entity(idx).Scale;
        formatted_number = sprintf('%03d', EMG_id);
        CEMG.(['CEMG_' formatted_number '_KHz']) = down_sampleRate / 1000;
        CEMG.(['CEMG_' formatted_number '_KHz_Orig']) = down_sampleRate / 1000;
        EMG_element_cell{file_id}{EMG_id} = resample(ref_signal, down_sampleRate, original_sampleRate);
        EMG_id = EMG_id + 1;
    end
end
not_empty_file_indices = find(~cellfun('isempty', EMG_element_cell));
validate_EMG_element_cell = EMG_element_cell(not_empty_file_indices);
validate_EMG_files_name = arrayfun(@(x) x.name, EMG_files(not_empty_file_indices), 'UniformOutput', false);
validate_record_time_element = record_time_element(not_empty_file_indices);
record_time = sum(validate_record_time_element);

% concatenate EMG data
for EMG_id = 1:muscle_num
    concatenatedData = cell(1, length(validate_EMG_element_cell));
    for concat_id = 1:length(validate_EMG_element_cell)
        concatenatedData{concat_id} = validate_EMG_element_cell{concat_id}{EMG_id};
    end
    CEMG.(['CEMG_' sprintf('%03d', EMG_id)]) = cell2mat(concatenatedData);
end

disp(['�y' exp_day '_validate_file:  ' strjoin(validate_EMG_files_name, ' and ') '�z']);
end