%{
[explanation of this func]:
function to extract from the structure only those fields that correspond to the regular expression

[input arguments]
original_struct: [struct], structure to be filtered
pattern: [char], string of regfular expression

[output arguments]
filtered_struct: [struct], strucuture containing fields extracted from 'original_struct' based on 'pattern'

%}

function [filtered_struct] = getMatchingFields(original_struct, pattern)
filtered_struct = struct();
% get fields name of  'original_struct'
fields = fieldnames(original_struct);

% assign only fields with the corresponding regular expression as field name to 'filtered_struct'
for i = 1:length(fields)
    field_name = fields{i};
    if regexp(field_name, pattern)
        filtered_struct.(field_name) = original_struct.(field_name);
    end
end
end

