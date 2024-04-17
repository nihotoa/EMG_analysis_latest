%{
[explanation of this func]
find the index of EMG electrode from hFile

[input arguments]
hFIle: [struct], this is obtained by executing 'ns_OpenFile.m'

[output arguments]
start_id: [double], index of the 1st EMG electrode
end_id: [double], index of the last EMG electrode

[Improvement point(Japanese)]
'emg'‚Æ‚¢‚¤•¶š®‚ğŠÜ‚Ş‚à‚Ì‚ğEMG“d‹É‚ÆŒ©˜ô‚µ‚Ä‚¢‚é‚ªAripple‘¤‚Ìİ’è‚É‚æ‚Á‚ÄŒÂX‚Ì•¶š—ñ‚ª•Ï‚í‚é‚©‚à‚µ‚ê‚È‚¢‚±‚Æ‚É’ˆÓ
%}
function [start_id, end_id] = get_EMG_electrode_num(hFile)
    label_names = {hFile.Entity.Label};
    emg_electrode_index = find(cellfun(@(x) contains(x, 'emg'), label_names));
    start_id = emg_electrode_index(1);
    end_id = emg_electrode_index(end);
end

