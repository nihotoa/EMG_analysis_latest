
%{
[explanation of this func]:
Function to eliminate the difference of trial data length between sessions(dates) by resampling
Processed data is added to 'ref_timing_EMG_struct'

[input arguments]
Allfiles_S: [cell array], list of selected file name
ref_timing_EMG_struct: [struct], contains various information around the timing to be focused on
ref_timing: [double], timing number to be focused on
nomalizeAmp: [double (0/1)],  whether to normalize amplitude
select_folder_path: [char], [char], Absolute path to the location which exists 'Pdata' to be referenced
element_num: [double], number of elements (EMG or synergy)

[output arguments]
ref_Ptig: [struct], contains various information around the timing to be focused on

[caution!!]
このコードの実行にはSignal Processing Toolboxが必要です(resample関数を使用するため. (buil-in関数でもresampleはあるが、こっちのresampleは使いたいやつではないし、エラー吐く))
%}

function [ref_timing_EMG_struct] = resampleEachTiming(Allfiles_S, ref_timing_EMG_struct, ref_timing, select_folder_path, element_num)  
    session_num = length(Allfiles_S);
    for session_id = 1: session_num 
        % load Pdata
        load(fullfile(select_folder_path, Allfiles_S{session_id}), 'ResAVE');
        
        % store activity data around the timing of interest in 'data'
        ref_session_EMG_data = ResAVE.(['tData' num2str(ref_timing) '_AVE']);
        ref_session_data_length = ref_timing_EMG_struct.length_list(session_id,1);
        common_data_length = ref_timing_EMG_struct.session_average_length;
        time_normalized_EMG = zeros(element_num, common_data_length);

        % Time normalize to the average sample size of all sessions
        if ref_session_data_length == common_data_length
            for element_id = 1:element_num
                time_normalized_EMG(element_id,:) = ref_session_EMG_data{1,element_id};
            end
        elseif ref_session_data_length < common_data_length 
            for element_id = 1:element_num
                ref_element_data = ref_session_EMG_data{1,element_id};
                time_normalized_EMG(element_id,:) = interpft(ref_element_data, common_data_length);
            end
        else
            for element_id = 1:element_num
                ref_element_data = ref_session_EMG_data{1,element_id};
                time_normalized_EMG(element_id,:) = resample(ref_element_data, common_data_length, ref_session_data_length);
            end
        end

        ref_timing_EMG_struct.time_normalized_EMG{session_id,1} = time_normalized_EMG;
    end
end