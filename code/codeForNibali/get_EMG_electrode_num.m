%{
[explanation of this func]
find the index of EMG electrode from hFile

[input arguments]
hFIle: [struct], this is obtained by executing 'ns_OpenFile.m'

[output arguments]
start_id: [double], index of the 1st EMG electrode
end_id: [double], index of the last EMG electrode

[Improvement point(Japanese)]
'emg'という文字式を含むものをEMG電極と見做しているが、ripple側の設定によって個々の文字列が変わるかもしれないことに注意
%}
function [start_id, end_id] = get_EMG_electrode_num(hFile)
    label_names = {hFile.Entity.Label};
    emg_electrode_index = find(cellfun(@(x) contains(x, 'emg'), label_names));
    start_id = emg_electrode_index(1);
    end_id = emg_electrode_index(end);
end

