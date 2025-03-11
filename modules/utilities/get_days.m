function [days] = get_days(name_list, extract_id)
%{
explanation of this func:
Extract the numerical part from each element of name_list(cell array) and create a list of double array

input arguments:
name_list: [cell array or char] Each cell contains the string type of the folder name.' You can get it by using 'uiselect'
extract_id: If there are multiple number parts in sentence, which index element should be extracted 

output arguments:
days: [double array] Each element contains a date of double type
%}
if nargin == 1
    extract_id = 1;
end

if ischar(name_list)
    temp = name_list;
    clear name_list;
    name_list{1} = temp;
end

days = zeros(length(name_list), 1);
for ii = 1:length(name_list)
    ref_element = name_list{ii};
    number_part = regexp(ref_element, '\d+', 'match');
    day = str2double(number_part{extract_id});
    days(ii) = day;
end
end