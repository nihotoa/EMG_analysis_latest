%{
[explanation of this func]:
Create a list of names with fixed prefixes and incrementing numeric parts
(e.g.)
{'synergy1', 'synergy2', 'synergy3', 'synergy4', ...}

[input arguments]:
prefix:[char], prefix to be fixed (e.g.) 'synergy'
max_num: [double], maximum of number. ()

[output arguments]:
name_list: [cell array], generated name list. (length is correspond to 'max_num')
%}

function [name_list] = generateSequentialNames(prefix, max_num)
name_list = arrayfun(@(i) sprintf([prefix '%d'], i), 1:max_num, 'UniformOutput', false);
end

