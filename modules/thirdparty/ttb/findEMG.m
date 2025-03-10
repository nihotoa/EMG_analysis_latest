function EMG_name_list=findEMG(EMG_name_list)

EMG_name_list    = parseEMG(EMG_name_list);
for iEMG=length(EMG_name_list):-1:1
    if(isempty(EMG_name_list{iEMG}))
        EMG_name_list(iEMG)=[];
    end
end
EMG_name_list    = unique(EMG_name_list);