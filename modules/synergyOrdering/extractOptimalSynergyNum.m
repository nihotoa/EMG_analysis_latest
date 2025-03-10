%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
This function has function to extract optimal number of synergy from each session field of strucuture which is genrated in 'determineOptimalSynergyNumber.m'
extracted optimal number of synergy data is compiled as double array

[input argument]
optimal_synergy_num_struct: [structure], structure which is generated in 'determineOptimalSynergyNumber.m'

[output argument]
optimal_synergyNum_list:[double array], list of the optimal number of synergy.

[improvement point]
optimal_synergy_num以外のフィールドをリストにまとめるために, 入力引数を追加して、どのフィールドを抽出するかswtichで条件分岐するべき.
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [optimal_synergyNum_list] =  extractOptimalSynergyNum(optimal_synergy_num_struct, extract_field_name)
switch extract_field_name
    case 'optimal_synergy_num'
        get_synNum_func = @(s) s.optimal_synergy_num;
    case 'VAF_cc'
        get_synNum_func = @(s) s.VAF_cc;
    case 'best_cc'
        get_synNum_func = @(s) s.best_cc;
end
optimal_synergyNum_list = structfun(get_synNum_func, optimal_synergy_num_struct);
end