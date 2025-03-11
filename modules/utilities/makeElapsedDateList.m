%{
[explanation of this func]:
calcurates how may days after 'ref_day' each element of 'date_list'
corresponds and returns this  as list

[input arguments]:
date_list: [cell array], list of date   (ex.) {'20220420', '20220421'}
ref_day: [double or char], reference day    (ex.) '20220520'

[output arguments]
elapsed_date_list: [double array], how may days after 'ref_day' each element of 'date_list'
corresponds (ex.) [-30, -29]

[caution]
Please note that input arguments and output aruguments have difference of data types.

%}
function [elapsed_date_list] = makeElapsedDateList(date_list, ref_day)
date_num = length(date_list);
elapsed_date_list = cell(date_num, 1);
for date_idx = 1:date_num
    exp_day = date_list{date_idx};
    elapsed_date_list{date_idx} = CountElapsedDate(exp_day, ref_day);
end
elapsed_date_list = cell2mat(elapsed_date_list);
end

