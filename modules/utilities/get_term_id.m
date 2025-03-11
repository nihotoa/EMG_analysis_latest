%{
[explanation of this func]:
Returns the index of the element in 'file_names' whose name contains the date immediately before (or after) 'base_day'

[input arguments]:
file_names: [cell array], list of file name
extract_num_id:[double], which number of num_parts you want to assign
base_day: [double or char], day which corresponds to criterion

[output arguments]
prev_id: [double], index of the date immediately before 'base_day'
post_id: [double], index of the date immediately after 'base_day'

[improvement point(japanese)]

%}
function [prev_id, post_id] = get_term_id(file_names, extract_num_id, base_day)
for file_id = 1:length(file_names)
    ref_file_name = file_names{file_id};
    num_parts = regexp(ref_file_name, '\d+', 'match'); %extract number part
    ref_day = num_parts{extract_num_id};
    elapsed_term = CountElapsedDate(ref_day, base_day);
    if elapsed_term > 0
        prev_id = file_id - 1;
        post_id = file_id;
        return;
    end
end
error('This "file_names" array can not be devided into "pre" and "post"')
end

