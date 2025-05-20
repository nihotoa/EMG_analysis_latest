%{
    + 新しいデータを古いデータのstructureにパースするための関数
    + Rolandのクソがデータ無くしたので、対応するために作った
    + Yachimun or SesekiL用
%}

function parsed_structure = makeParsedStructure()
parsed_structure = struct();
parsed_structure.x = [];
parsed_structure.plotData_sel = [];
end