function EMG_name_list = get_EMG_name(TargetName)

%{
explanation of this func:
Extract the numerical part from each element of InputDirs(cell array) and create a list of double array

input arguments:
InputDirs: cell array, Each cell contains the string type of the folder name.' You can get it by using 'uiselect'

output arguments:
days: double array, Each element contains a date of double type
%}

% finding common string
% (since the process contents are connected by '-', find common string by concatenating the first '-' and the following)
ref_name = TargetName{1};
ref_name_components = strsplit(ref_name, '-');
ref_name_components{1} = strrep(ref_name_components{1}, ref_name_components{1}, '');
temp = join(ref_name_components, '-');
common_string = temp{1};

EMG_name_list = cell(length(TargetName), 1);
% delete common strings from all elements
for ii = 1:length(TargetName)
    EMG_name_list{ii} = strrep(TargetName{ii}, common_string, '');
end
end

