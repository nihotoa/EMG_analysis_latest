%{
[explanation of this func]:
Unpack the fields of each data structure & save these data as .mat file 

[input arguments]
base_dir: [char], path of based directory
exp_day: [char], recorded day
monkeyname: [char], prefix of recorded data
CEMG_struct:[struct], struct contains various fields which is ralated to CEMG data
CAI_struct: [struct], struct contains various fields which is ralated to CAI data
CRAW_struct: [struct], struct contains various fields which is ralated to CRAW data
CLFP_struct: [struct], struct contains various fields which is ralated to CLFP data
CTTL_struct: [struct], struct contains various fields which is ralated to CTTL data

[output arguments]
%}
function [] = saveRawData(base_dir, exp_day, monkeyname, CEMG_struct, CAI_struct, CRAW_struct, CLFP_struct, CTTL_struct)
struct_list = {CEMG_struct, CAI_struct, CRAW_struct, CLFP_struct, CTTL_struct};
EMG_pattern = '^CEMG_\d{3}$';
Begin_data_name = 'CAI_struct.CAI_001_TimeBegin'; 
End_data_name = 'CAI_struct.CAI_001_TimeEnd';

for struct_id = 1:length(struct_list)
    ref_struct = struct_list{struct_id};
    field_name_list = fieldnames(ref_struct);
    for field_id = 1:length(field_name_list)
        field_name = field_name_list{field_id};
        % unpack
        eval([field_name ' = ref_struct.' field_name ';'])

        % add info
        if regexp (field_name, EMG_pattern)
            Begin_var_name = [field_name '_TimeBegin'];
            End_var_name = [field_name '_TimeEnd'];
            eval([Begin_var_name ' = ' Begin_data_name ';'])
            eval([End_var_name ' = ' End_data_name ';'])
        end
    end
end

% clear data strucut (because it's in the way when we save data)
clear CEMG_struct CAI_struct CRAW_struct CLFP_struct CTTL_struct;

% save data
save_file_path = fullfile(base_dir, [monkeyname exp_day(3:end) '-' sprintf('%04d', 1) '.mat']);
save(save_file_path, 'CEMG*', 'CAI*', 'CRAW*', 'CLFP*', 'CTTL*');
disp(['[saved]: ' save_file_path])
end

