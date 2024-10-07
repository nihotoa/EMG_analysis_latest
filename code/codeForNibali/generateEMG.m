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
nevファイルとmatファイルがある
(matファイルはnevファイルを読み込めなかった時期に, 業者にmatファイルにしてデータ(hFile)を送ってもらってた時のデータ)
=> 結局ns_Openでfull_path入力すればいけると聞いて改善したので、基本matは使わないはず

[Improvement point(japanese)]
nevファイルが複数ある時に対応していないので、考える
nevが読み込めなかった時の.mat読み込み部分を消したので、エラー吐いたらその時に考える
%}

function [CEMG, amplitude_unit, record_time] = generateEMG(base_dir, exp_day, down_sampleRate)

ref_dir = fullfile(base_dir, exp_day);
ref_file = dir(fullfile(ref_dir, 'datafile*.nev'));
EMG_file_path = fullfile(ref_dir, ref_file.name);

[~, hFile] = ns_OpenFile(EMG_file_path); 
[start_num, end_num] = get_EMG_electrode_num(hFile);

CEMG = struct;
EMG_idx = 1;
for idx = start_num:2:end_num-1
    % get EMG signal from both electrode
    [~, ~, EMG_signal1] = ns_GetAnalogData(hFile, idx, 1, 1e8);
    [~, ~, EMG_signal2] = ns_GetAnalogData(hFile, idx+1, 1, 1e8);
        
    % take the difference
    EMG_signal = transpose(EMG_signal1 - EMG_signal2);

    % compile the information of record(samplingRate, rosolution, etc...)
    if idx == start_num
        [~, record_info] = ns_GetAnalogInfo(hFile, idx);
        original_sampleRate = record_info.SampleRate;
        amplitude_unit = record_info.Units;
        record_time = length(EMG_signal) / original_sampleRate;
    end

    % store the signal & informations
    formatted_number = sprintf('%03d', EMG_idx);
    ref_signal = EMG_signal * hFile.Entity(idx).Scale;
    CEMG.(['CEMG_' formatted_number]) = resample(ref_signal, down_sampleRate, original_sampleRate);
    CEMG.(['CEMG_' formatted_number '_KHz']) = down_sampleRate / 1000;
    CEMG.(['CEMG_' formatted_number '_KHz_Orig']) = down_sampleRate / 1000;

    EMG_idx = EMG_idx + 1;
end
end