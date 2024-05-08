%{
[explanation of this func]:
this func is used in 'SAVE4NMF.m'
concanenate EMG data for 1 experiment day.
Extract information necessary for EMG analysis(ex. TimeRange, EMG_Hz etc...) from recorded data

[input arguments]
monkeyname: [char], prefix of recorded data file
xpdate: [char], date of experiment
file_num: [double array], which file number corresponds to the experimental data
real_name: [char], full name of monkey

[output arguments]
AllData_EMG: [double array], concatenated raw EMG data
TimeRange: [double array], time of start and end of recording
EMG_Hz: sampling frequency of EMG data 

[Improvement points(Japanese)]
pwdじゃなくて,  inputにbase_dir指定してそれを使った方がいいかも
%}

function [AllData_EMG, TimeRange, EMG_Hz] = makeEasyEMG(monkeyname, xpdate, file_num, real_name, EMG_num)
%% create EMG All Data matrix
file_count = (file_num(end) - file_num(1)) + 1;
AllData_EMG_sel = cell(file_count,1);
load(fullfile(pwd, real_name, [monkeyname xpdate '-' sprintf('%04d',file_num(1,1))]),'CEMG_001_TimeBegin');
TimeRange = zeros(1,2);
TimeRange(1,1) = CEMG_001_TimeBegin;
EMG_prefix = 'CEMG';
get_first_data = 1;

for i = file_num(1,1):file_num(end)
    for j = 1:EMG_num
        if get_first_data
            load(fullfile(pwd, real_name, [monkeyname xpdate '-' sprintf('%04d',i)]), [EMG_prefix '_001*']);
            EMG_Hz = eval([EMG_prefix '_001_KHz .* 1000;']);
            Data_num_EMG = eval(['length(' EMG_prefix '_001);']);
            AllData1_EMG = zeros(Data_num_EMG, EMG_num);
            AllData1_EMG(:,1) = eval([EMG_prefix '_001;']);
            get_first_data = 0;
        else
            load(fullfile(pwd, real_name, [monkeyname xpdate '-' sprintf('%04d',i)]), [EMG_prefix '_0' sprintf('%02d',j)]);
            eval(['AllData1_EMG(:, j ) = ' EMG_prefix '_0' sprintf('%02d',j) ''';']);
        end
    end
    AllData_EMG_sel{(i - file_num(1, 1)) + 1, 1} = AllData1_EMG;
    load([monkeyname xpdate '-' sprintf('%04d',i)],[EMG_prefix '_001_TimeEnd']);
    TimeRange(1,2) = eval([EMG_prefix '_001_TimeEnd;']);
    get_first_data = 1;
end
AllData_EMG = cell2mat(AllData_EMG_sel);
end