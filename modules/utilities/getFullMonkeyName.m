%{
[explanation of this code]:
get the monkey's full name from the filename prefix

[input arguments]:
prefix: [char], prefix of file  (ex.) if filename is 'F170516_0002', pleaseinput 'F'

[output arguments]:
full_monkey_name: [char], full name of monkey which is correspond to prefix name of file 
%}

function [full_monkey_name] = getFullMonkeyName(prefix)
switch prefix
    case {'Ya', 'F'}
        full_monkey_name = 'Yachimun';
    case 'Se'
        full_monkey_name = 'SesekiL';
    case 'Ni'
        full_monkey_name = 'Nibali';
    case 'Hu'
        full_monkey_name = 'Hugo';
end
end

