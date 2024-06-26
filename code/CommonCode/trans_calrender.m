%{
[explanation of this func]:
convert data type from 'double' to 'datetime'

[input arguments]
exp_day: [double or char], day  (ex.) 170530

[output arguments]
calender_day: [datetime], day which is converted    (ex.) 2017/05/30
%}

function [calender_day] = trans_calrender(exp_day)
    exp_day = string(exp_day); 
    temp = char(exp_day);
    if length(temp) == 8
        % Divide into 'year'/'month'/'day'
        year = str2double(string(temp(1:4)));
        month = str2double(string(temp(5:6)));
        day = str2double(string(temp(7:8)));
    elseif length(temp) == 6
        % Divide into 'year'/'month'/'day'
        year = str2double('20' + string(temp(1:2)));
        month = str2double(string(temp(3:4)));
        day = str2double(string(temp(5:6)));
    end
    
    % change to calender type
    calender_day = datetime(year,month,day);
end

