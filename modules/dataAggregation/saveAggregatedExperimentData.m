%{
[Function Description]
This function unpacks and saves the contents of various data structures into a single .mat file.
It handles EMG, CAI, CLFP, CRAW, and CTTL data structures, ensuring proper time alignment
and data organization in the output file. The function preserves the original structure
of each data type while combining them into a comprehensive experiment record.

[Input Arguments]
save_file_path: [char] Path where the output .mat file will be saved
CEMG_struct: [struct] Structure containing EMG data and metadata
CAI_struct: [struct] Structure containing CAI (analog input) data and metadata
CRAW_struct: [struct] Structure containing raw neural data and metadata
CLFP_struct: [struct] Structure containing local field potential data and metadata
CTTL_struct: [struct] Structure containing timing and trigger data and metadata

[Output Arguments]
None (saves data to file)
%}

function [] = saveAggregatedExperimentData(save_file_path, CEMG_struct, CAI_struct, CRAW_struct, CLFP_struct, CTTL_struct)
necessary_data_struct_list = {CEMG_struct, CAI_struct, CRAW_struct, CLFP_struct, CTTL_struct};
EMG_regexp_pattern = '^CEMG_\d{3}$';
Begin_data_name = 'CAI_struct.CAI_001_TimeBegin';
End_data_name = 'CAI_struct.CAI_001_TimeEnd';

for struct_id = 1:length(necessary_data_struct_list)
    ref_struct = necessary_data_struct_list{struct_id};
    field_name_list = fieldnames(ref_struct);
    for field_id = 1:length(field_name_list)
        ref_field_name = field_name_list{field_id};
        eval([ref_field_name ' = ref_struct.' ref_field_name ';'])

        if regexp(ref_field_name, EMG_regexp_pattern)
            TimeBegin_variable_name = [ref_field_name '_TimeBegin'];
            TimeEnd_variable_name = [ref_field_name '_TimeEnd'];
            eval([TimeBegin_variable_name ' = ' Begin_data_name ';'])
            eval([TimeEnd_variable_name ' = ' End_data_name ';'])
        end
    end
end

% clear data strucut (because it's in the way when we save data)
clear CEMG_struct CAI_struct CRAW_struct CLFP_struct CTTL_struct;

% save data
save(save_file_path, 'CEMG*', 'CAI*', 'CRAW*', 'CLFP*', 'CTTL*');
disp(['[saved]: ' save_file_path]);
end

