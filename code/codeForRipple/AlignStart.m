%{
[explanation of this func]:
this function is used in 'CombineMatfile.m'.
Concatenate all designated data for 1 day, perform resampling and return this concatenated data wtih supplement inforomation as structure.
designated data is created by using both 'signal_name' and 'ref_id'
(ex.) if 'signal_name' is CAI and 'ref_id' is 1, designated data is correspond to  'CAI_001'

[input argument]
all_data_cell:[cell array], cell array contains structs which contains loaded data from each raw data file 
signal_struct: [struct], struct to store the necessary data which is created in this function
downHz:[double], sampling rate after resampling
record_time:[double], record time of EMG signal
exp_day:[char], day of experiment
signal_name:[char], string of signal (used to identify signal)
ref_id:[double], channel id which you want to focus on
task_start_time:[double], start time of EMG recording

[output arguments]
TimeRange: [double array], time data both start and end of recording
signal_struct: [struct], struct to store the necessary data which is created in this function

[detail of this process(japanese)]
1. CTTL_001��, record��'�J�n'��'�I��'�̃g�O���X�C�b�`�ɑΉ����Ă���
(�r������, AlphaOmega�̕����g�O���X�C�b�`�ŋL�^�̊J�n�ƏI�����ł��Ȃ��Ȃ����̂ŁAAlphaOmega�͎蓮��
�L�^���J�n���āA�蓮�ŏI������K�v���������B���̂��߁AEMG�ƃ^�C�~���O�����킹�邽�߂Ƀg�O���X�C�b�`�̊J�n
�ƏI���̃^�C�~���O�ł���CTTL_001�̓������^�C�~���O�ō��킹��悤�ɂ���(���̊֐��������))

2. �܂�AEMG�̍ŏ��̃T���v����, CTTL_001�̍ŏ��̃^�C�~���O����v����悤��, AlphaOmega�̃f�[�^���g���~���O����K�v������
�@ ���l�ɂ��ďI���^�C�~���O�ȍ~��AlphaOmegafile�̓��e���폜����K�v������

[caution(japanese)]
�I���Ǝn�܂肪��v���Ă��鎞��trash_data_time��0�ɂȂ�̂ŁA�Ƃ肠�������̊֐����g���Ă����Ζ��Ȃ�

[Improvement point]
CTTL_001���g�O���X�C�b�`��on off�ɕK�������Ή�����킯�ł͂Ȃ��̂ŁA�����ɐݒ肷��
%}

function [TimeRange, signal_struct] = AlignStart(all_data_cell, signal_struct, downHz, record_time, exp_day, signal_name, ref_id, task_start_time) 
    AlphaOmega_file_num = length(all_data_cell);
    sel_signal = cell(1, AlphaOmega_file_num);
    ref_data_name = [signal_name '_' sprintf('%03d', ref_id)];

    for file_idx = 1:AlphaOmega_file_num 
        try
            ref_data = all_data_cell{file_idx}.(ref_data_name);
        catch
            % process if data file (corresponds to file_idx) does't have field corresponds to 'ref_data_name'
            if ref_id == 1
                disp([exp_day '-file' num2str(file_idx) ' does not contains ' signal_name ' signal'])
            end
            continue;
        end

        % cast & reasample
        ref_data = cast(ref_data, 'double');
        original_Hz = all_data_cell{file_idx}.([ref_data_name '_KHz']) * 1000;
        ref_data = resample(ref_data, downHz, original_Hz);

        if file_idx==1
            % start timing of EMG_record(correspond to CTTL_001_TimeBegin)
            TimeBegin = task_start_time;
            TimeEnd = TimeBegin + record_time;
            TimeRange(1,1) = TimeBegin;
            TimeRange(1,2) = TimeEnd;

            % trash(align start)
            trash_data_time = TimeBegin - all_data_cell{file_idx}.([ref_data_name '_TimeBegin']);
            if strcmp(signal_name, 'CAI')
                disp([exp_day ' TrashTime(before_start): ' num2str(trash_data_time) '[s]']);
            end
            trash_sample=round(trash_data_time*downHz);

            % convert - value to 0
            if trash_sample < 0 && abs(trash_sample) < 100 
                trash_sample = 0;
            end
            ref_data = ref_data(trash_sample+1:end);

        elseif all_data_cell{file_idx}.([ref_data_name '_TimeEnd']) > TimeRange(2) 
            % trash(align end)
            trash_data_time =  all_data_cell{file_idx}.([ref_data_name '_TimeEnd']) - TimeRange(2); 
            if and(strcmp(signal_name, 'CAI'), file_idx == AlphaOmega_file_num)
                disp([exp_day ' TrashTime(after_end): ' num2str(trash_data_time) '[s]']);
            end
            trash_sample = round(downHz * trash_data_time);
            last_sample_idx = length(ref_data) - trash_sample;
            ref_data = ref_data(1:last_sample_idx);
        else
        end

        % store the data from this file
        sel_signal{1, file_idx} = ref_data;
    end
    signal_data = cell2mat(sel_signal);

    % add necessary information into 'signal struct'
    signal_struct.(ref_data_name) = signal_data;
    signal_struct.([ref_data_name '_KHz']) = downHz / 1000;
    signal_struct.([ref_data_name '_KHz_Orig']) = downHz / 1000;
    signal_struct.([ref_data_name '_TimeBegin']) = TimeRange(1, 1);
    signal_struct.([ref_data_name '_TimeEnd']) = TimeRange(1,2);
end

