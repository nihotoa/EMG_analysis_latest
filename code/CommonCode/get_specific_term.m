%{
[explanation of this func]:
function to return the list of date which match specific trerm
(Curently, this function is used for extract Pre or Post TT days list from entire date list)

[input arguments]
date_list[cell array]: list of date
term_type: [char], 'pre', 'post'
ref_day: day of reference

[output arguments]
filtered_date_list: [cell array], return list of date which match specific term
(Return with the same data type as the input list)

[improvement point(japanese)]
入出力の日付のリストのデータ型がcell配列出ないといけないので、汎用性を高める
%}

function [filtered_date_list] = get_specific_term(date_list, term_type, ref_day)
date_num = length(date_list);
if iscell(date_list)
    elapsed_date_list = cell(date_num, 1);
    for date_idx = 1:date_num
        exp_day = date_list{date_idx};
        elapsed_date_list{date_idx} = CountElapsedDate(exp_day, ref_day);
    end
    elapsed_date_list = cell2mat(elapsed_date_list);

elseif isa(date_list, 'double')
    elapsed_date_list = zeros(date_num, 1);
    for date_idx = 1:date_num
        exp_day = date_list(date_idx);
        elapsed_date_list(date_idx) = CountElapsedDate(exp_day, ref_day);
    end
else
    disp('this func does not deal with this data type')
    return;
end

switch term_type
    case 'pre'
        filtered_date_list = date_list(elapsed_date_list < 0);
    case 'post'
        filtered_date_list = date_list(elapsed_date_list > 0);
end
end

