%{
[Function Description]
This function identifies the electrode indices for EMG signals from a Ripple recording file.
It searches through the electrode labels to find the range of EMG electrodes by looking
for labels containing 'emg' in their names.

[Input Arguments]
hFile: [struct] File handle obtained from ns_OpenFile.m containing electrode information

[Output Arguments]
start_electrode_id: [double] Index of the first EMG electrode
end_electrode_id: [double] Index of the last EMG electrode
%}
function [start_electrode_id, end_electrode_id] = getEMGElectrodeNum(hFile)
    label_names = {hFile.Entity.Label};
    emg_electrode_index_list = find(cellfun(@(x) contains(x, 'emg'), label_names));
    start_electrode_id = emg_electrode_index_list(1);
    end_electrode_id = emg_electrode_index_list(end);
end

