%{
[explanation of this code]:
get the monkey's full name from the filename prefix

[input arguments]:
prefix: [char], prefix of file  (ex.) if filename is 'F170516_0002', pleaseinput 'F'

[output arguments]:
realname: [char], full name of monkey which is correspond to prefix name of file 
%}

function [realname] = get_real_name(prefix)
switch prefix
    case {'Ya', 'F'}
        realname = 'Yachimun';
    case 'Se'
        realname = 'SesekiL';
    case 'Ni'
        realname = 'Nibali';
    case 'Hu'
        realname = 'Hugo';
end
end

