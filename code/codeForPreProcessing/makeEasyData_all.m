%{
[explanation of this func]:
this function is used in 'runnningEasyfunc.m'
Perform data concatenation & filtering processing & Obtain information on each timing for EMG trial-by-trial extraction

[input arguments]:
monkeyname: [char], prefix of file
real_name: [char], full name of monkey
xpdate_num: [double], date of experiment
save_fold: [char], 'easyData' (don't need to change)
mE: [struct], Contains parameters on whether or not processing is performed and information on the sampling frequency after downsampling.
task: [char], 'standard' (don't need to change)

[output arguments]:
EMGs:[cell array], The name of each EMF is stored in a char type.
Tp: [double array], Data for each timing in each trial is stored.
Tp3: [double array], Data for each timing in each trial is stored.

[Improvement points(Japanese)]
pwdじゃなくて,  inputにbase_dir指定してそれを使った方がいいかも
全体的に冗長
NibaliのTpの切り出しの関数内も冗長なので削る
CTTL_003がうまく計測できなかったように、success_button_count_thresholdを設けて、TTL_002のみを使って
イベントタイミングを作るような条件分岐を実現しているが、drawerタスクしか対応していないので、Nibaliの方も書き換える
(というか共通化できないかどうか考える)
%}

function [EMGs,Tp,Tp3] = makeEasyData_all(monkeyname, real_name, xpdate_num, file_num, common_save_fold_path, mE, task)
%% set parameters
make_EMG = mE.make_EMG;
save_E = mE.save_E;
down_E =  mE.down_E;
make_Timing = mE.make_Timing;
downdata_to = mE.downdata_to;
success_button_count_threshold = 80;
time_restriction_flag = mE.time_restriction_flag;
time_restriction_threshold = mE.time_restriction_threshold; 

%% code section
xpdate = sprintf('%d',xpdate_num);
% Store the name of the muscle corresponding to each electrode in the cell array
switch monkeyname
    case 'Wa'%Wasa
        % which EMG channels will be imported and/or filtered (channels are numbered according to the output file, not the AO original channel ID)
        EMGs=cell(14,1) ;
        EMGs{1,1}= 'Delt';
        EMGs{2,1}= 'Biceps';
        EMGs{3,1}= 'Triceps';
        EMGs{4,1}= 'BRD';
        EMGs{5,1}= 'cuff';
        EMGs{6,1}= 'ED23';
        EMGs{7,1}= 'ED45';
        EMGs{8,1}= 'ECR';
        EMGs{9,1}= 'ECU';
        EMGs{10,1}= 'EDC';
        EMGs{11,1}= 'FDS';
        EMGs{12,1}= 'FDP';
        EMGs{13,1}= 'FCU';
        EMGs{14,1}= 'FCR';
    case {'Ya', 'F'}%Yachimun
        % which EMG channels will be imported and/or filtered (channels are numbered according to the output file, not the AO original channel ID)
        EMGs=cell(12,1) ;
        EMGs{1,1}= 'FDP';
        EMGs{2,1}= 'FDSprox';
        EMGs{3,1}= 'FDSdist';
        EMGs{4,1}= 'FCU';
        EMGs{5,1}= 'PL';
        EMGs{6,1}= 'FCR';
        EMGs{7,1}= 'BRD';
        EMGs{8,1}= 'ECR';
        EMGs{9,1}= 'EDCprox';
        EMGs{10,1}= 'EDCdist';
        EMGs{11,1}= 'ED23';
        EMGs{12,1}= 'ECU';
    case 'Su'%Suruku
        % which EMG channels will be imported and/or filtered (channels are numbered according to the output file, not the AO original channel ID)
        EMGs=cell(12,1) ;
        EMGs{1,1}= 'FDS';
        EMGs{2,1}= 'FDP';
        EMGs{3,1}= 'FCR';
        EMGs{4,1}= 'FCU';
        EMGs{5,1}= 'PL';
        EMGs{6,1}= 'BRD';
        EMGs{7,1}= 'EDC';
        EMGs{8,1}= 'ED23';
        EMGs{9,1}= 'ED45';
        EMGs{10,1}= 'ECU';
        EMGs{11,1}= 'ECR';
        EMGs{12,1}= 'Deltoid';
   case 'Se'%Seseki
        % which EMG channels will be imported and/or filtered (channels are numbered according to the output file, not the AO original channel ID)
        EMGs=cell(12, 1) ;
        EMGs{1,1}= 'EDC';
        EMGs{2,1}= 'ED23';
        EMGs{3,1}= 'ED45';
        EMGs{4,1}= 'ECU';
        EMGs{5,1}= 'ECR';
        EMGs{6,1}= 'Deltoid';
        EMGs{7,1}= 'FDS';
        EMGs{8,1}= 'FDP';
        EMGs{9,1}= 'FCR';
        EMGs{10,1}= 'FCU';
        EMGs{11,1}= 'PL';
        EMGs{12,1}= 'BRD';
    case 'Ma'
        Mn = 8;
        EMGs=cell(Mn,1) ;
        EMGs{1,1}= 'EDC';
        EMGs{2,1}= 'ECR';
        EMGs{3,1}= 'BRD_1';
        EMGs{4,1}= 'FCU';
        EMGs{5,1}= 'FCR';
        EMGs{6,1}= 'BRD_2';
        if Mn == 8
           EMGs{7,1}= 'FDPr';
           EMGs{8,1}= 'FDPu';
        end
    case 'Ni'
        % which EMG channels will be imported and/or filtered (channels are numbered according to the output file, not the AO original channel ID)
        EMGs=cell(16,1) ;
        EMGs{1,1}= 'EDCdist';
        EMGs{2,1}= 'EDCprox';
        EMGs{3,1}= 'ED23';
        EMGs{4,1}= 'ED45';
        EMGs{5,1}= 'ECR';
        EMGs{6,1}= 'ECU';
        EMGs{7,1}= 'BRD';
        EMGs{8,1}= 'EPL';
        EMGs{9,1}= 'FDSdist';
        EMGs{10,1}= 'FDSprox';
        EMGs{11,1}= 'FDP';
        EMGs{12,1}= 'FCR';
        EMGs{13,1}= 'FCU';
        EMGs{14,1}= 'FPL';
        EMGs{15,1}= 'Biceps';
        EMGs{16,1}= 'Triceps';
    case 'Hu'
        EMGs=cell(16,1) ;
        EMGs{1,1}= 'EDC';
        EMGs{2,1}= 'ED23';
        EMGs{3,1}= 'ED45';
        EMGs{4,1}= 'ECR';
        EMGs{5,1}= 'ECU';
        EMGs{6,1}= 'FDI';
        EMGs{7,1}= 'ADP';
        EMGs{8,1}= 'ADM';
        EMGs{9,1}= 'Biceps';
        EMGs{10,1}= 'Triceps';
        EMGs{11,1}= 'FDS';
        EMGs{12,1}= 'FDP';
        EMGs{13,1}= 'PL';
        EMGs{14,1}= 'FCR';
        EMGs{15,1}= 'FCU';
        EMGs{16,1}= 'BRD';
end
EMG_num = length(EMGs);

%% concatenate EMG data from each files(same processing as 'SAVE4NMF.m')
if make_EMG == 1
    [AllData_EMG, TimeRange_EMG, EMG_Hz] = makeEasyEMG(monkeyname,xpdate,file_num, EMG_num, real_name);
end

%% down sampling data
if down_E == 1
   AllData_EMG = resample(AllData_EMG,downdata_to,EMG_Hz);
end

%% cut  data on task timing
if make_Timing == 1
   switch monkeyname
      case {'Su','Se'}
         [Timing,Tp,Tp3,TTLd,TTLu] = makeEasyTiming(monkeyname,xpdate,file_num,downdata_to,TimeRange_EMG);
         % change tiing from 'lever2' to 'photocell'
         errorlist = '';
         emp_d = 0;
         emp_u = 0;
         ph_d = zeros(length(Tp),1); % photo down clock = Photo On
         ph_u = zeros(length(Tp),1); % photo up clock = Photo Off
         for i = 1:length(Tp)
            if isempty(max(TTLd((Tp(i,3)<TTLd).*(TTLd<Tp(i,5)))))
                emp_d = 1;
            else
                ph_d(i) = min(TTLd((Tp(i,3)<TTLd).*(TTLd<Tp(i,5))));
            end
            if isempty(max(TTLu((Tp(i,3)<TTLu).*(TTLu<Tp(i,5)))))
                emp_u = 1;
            else
                ph_u(i) = max(TTLu((Tp(i,3)<TTLu).*(TTLu<Tp(i,5))));
            end
            if ph_d(i)>ph_u(i) || emp_d == 1 || emp_u ==1
                errorlist = [errorlist ' ' sprintf('%d',i)];
                emp_d = 0;
                emp_u = 0;
            end
            Tp(i,4) = ph_d(i);
            Tp(i,5) = ph_u(i); % Change timings 4 and 5 to 'photo-on' and 'photo-off' timings
         end
         if isempty(errorlist)
         else ER = str2num(errorlist);
             for ii = flip(ER)
                 Tp(ii,:) = [];
             end
         end
        
       case 'Ni'
           try
               [Timing,Tp,Tp3] = makeEasyTiming_Nibali(real_name, monkeyname, xpdate, file_num, downdata_to);
           catch
               warning([real_name '-' xpdate ' does not have "CTTL_003" signal']);
           end
       case 'Hu'
           [Timing,Tp,Tp3, is_condition2_active] = makeEasyTiming_drawer(real_name, monkeyname, xpdate, file_num, downdata_to, success_button_count_threshold, time_restriction_flag, time_restriction_threshold);
       otherwise %if reference monkey is not SesekiR or Wasa. (if you don't have to chage to fotocell）
            [Timing,Tp,Tp3] = makeEasyTiming(monkeyname,xpdate,file_num,downdata_to,TimeRange_EMG);
   end
   
   if exist("is_condition2_active", "var") && is_condition2_active
       % eliminate 'success_button' data
       Tp = Tp(:, 1:end-1);
   end
   success_timing = transpose(Tp);
   success_timing = [success_timing; success_timing(end, :) - success_timing(1, :)];
end

%% get data for Cross-Talk check (getCTcheck)
[trial_num, ~] = size(Tp);
CTcheck.raw_trial_EMG = cell(1, trial_num);
CTcheck.diff3_trial_EMG = cell(1, trial_num);

% Check for crosstalk for each trial
for trial_id = 1:trial_num
    [ref_trial_data, ref_trial_data_diff3] = getCTcheck(AllData_EMG, Tp, EMG_num, trial_id, downdata_to);
    CTcheck.raw_trial_EMG{trial_id} = ref_trial_data;
    CTcheck.diff3_trial_EMG{trial_id} = ref_trial_data_diff3; 
end

%% save data
if save_E == 1
    Unit = 'uV';
    SampleRate = downdata_to;
    cutout_EMG_data_save_fold_path = fullfile(common_save_fold_path, 'cutout_EMG_data_list');
    makefold(cutout_EMG_data_save_fold_path);
    switch monkeyname
        case {'Ya','Ma','F', 'Wa', 'Ni', 'Hu'}
            save(fullfile(cutout_EMG_data_save_fold_path, [monkeyname xpdate '_cutout_EMG_data.mat']), 'monkeyname', 'xpdate', 'file_num', 'EMGs',...
                                                    'AllData_EMG', ...
                                                    'TimeRange_EMG',...
                                                    'EMG_Hz',... '
                                                    'Unit','SampleRate',...
                                                    'Timing','Tp','Tp3');
       case {'Su','Se'}
            save(fullfile(cutout_EMG_data_save_fold_path, [monkeyname xpdate '_cutout_EMG_data.mat']), 'monkeyname', 'xpdate', 'file_num', 'EMGs',...
                                                    'AllData_EMG', ...
                                                    'TimeRange_EMG',...
                                                    'EMG_Hz',... 
                                                    'Unit','SampleRate',...
                                                    'Timing','Tp','Tp3','TTLd','TTLu');
    end

    CT_check_data_save_fold_path = fullfile(common_save_fold_path, 'CT_check_data_list');
    makefold(CT_check_data_save_fold_path);
    save(fullfile(CT_check_data_save_fold_path, [monkeyname xpdate '_CT_check_data.mat']), 'CTcheck');

    if exist("success_timing", "var")
        success_timing_data_save_fold_path = fullfile(common_save_fold_path, 'success_timing_data_list', xpdate);
        makefold(success_timing_data_save_fold_path);
        success_timing_file_name = 'success_timing';
        if time_restriction_flag
            success_timing_file_name = [success_timing_file_name '(' num2str(time_restriction_threshold) '[sec]_restriction)'];
        end
        save(fullfile(success_timing_data_save_fold_path, [success_timing_file_name '.mat']), 'success_timing');
    end
    disp(['FINISH TO MAKE & SAVE ' monkeyname xpdate 'file[' sprintf('%d',file_num(1)) ',' sprintf('%d',file_num(end)) ']']);
else
   disp(['NOT SAVE ' monkeyname xpdate 'file[' sprintf('%d',file_num(1)) ',' sprintf('%d',file_num(end)) ']']);
end
end

%% define local function
%% 1.concatenate EMG data from each file & return concatenated EMG dataset (AllData_EMG)
function [AllData_EMG, TimeRange, EMG_Hz] = makeEasyEMG(monkeyname, xpdate, file_num, EMG_num, real_name)
file_count = (file_num(end) - file_num(1)) + 1;
AllData_EMG_sel = cell(file_count,1);
root_dir = fileparts(pwd);
load(fullfile(root_dir, 'useDataFold', real_name, [monkeyname xpdate '-' sprintf('%04d',file_num(1,1))]),'CEMG_001_TimeBegin');
TimeRange = zeros(1,2);
TimeRange(1,1) = CEMG_001_TimeBegin;
EMG_prefix = 'CEMG';
get_first_data = 1;

for i = file_num(1,1):file_num(end)
    for j = 1:EMG_num
        if get_first_data
            load(fullfile(root_dir, 'useDataFold', real_name, [monkeyname xpdate '-' sprintf('%04d',i)]), [EMG_prefix '_001*']);
            EMG_Hz = eval([EMG_prefix '_001_KHz .* 1000;']);
            Data_num_EMG = eval(['length(' EMG_prefix '_001);']);
            AllData1_EMG = zeros(Data_num_EMG, EMG_num);
            AllData1_EMG(:,1) = eval([EMG_prefix '_001;']);
            get_first_data = 0;
        else
            load(fullfile(root_dir, 'useDataFold', real_name, [monkeyname xpdate '-' sprintf('%04d',i)]), [EMG_prefix '_' sprintf('%03d',j)]);
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


%% 2. Create a cell array of event codes and extract only the event codes for task timing
function [Timing,Tp,Tp3,varargout] = makeEasyTiming(monkeyname, xpdate, file_num, SampleRate, TimeRange_EMG)
Ld = file_num(end)-file_num(1)+1;
%number of file
AllInPort_sel = cell(1,Ld);
get_first_portin = 1;
for i = file_num(1,1):file_num(1,end)
    if get_first_portin
        S1 = load([monkeyname xpdate '-' sprintf('%04d', i) '.mat'], 'CInPort*');
        CInPort = S1.CInPort_001;
    else
        
        S = load([monkeyname xpdate '-' sprintf('%04d', i) '.mat'], 'CInPort_001');
        if ~isempty(struct2cell(S))
           CInPort = S.CInPort_001;
        end
    end
    AllInPort_sel{1,1+i-file_num(1,1)} = CInPort;
    get_first_portin = 0;
end
AllInPort = cell2mat(AllInPort_sel);

%%%%%%%%%%%%%%%%%Define the ID of timing of interest for each experiment%%%%%%%%%%%%%%%%%
switch monkeyname
    case {'Wa','Su','Se'}
        if strcmp(monkeyname, 'Su') || strcmp(monkeyname, 'Se')
            varargout= cell(nargout-4,1);
            AllTTLd_sel = cell(1,Ld);
            AllTTLu_sel = cell(1,Ld);
            count = 1;
            for t = file_num(1):file_num(end)
                TTLdata = load([monkeyname xpdate '-' sprintf('%04d', t) '.mat'], 'CTTL_001*');
                if isfield(TTLdata,'CTTL_001_TimeBegin')
                    TTL_lag = (TTLdata.CTTL_001_TimeBegin - TimeRange_EMG(1))*TTLdata.CTTL_001_KHz*1000;
                    AllTTLd_sel{count} = TTLdata.CTTL_001_Down+TTL_lag;
                    AllTTLu_sel{count} = TTLdata.CTTL_001_Up+TTL_lag;
                    count = count+1;
                end
            end
            if isfield(TTLdata,'CTTL_001_KHz')
                AllTTLd = cell2mat(AllTTLd_sel).*SampleRate./(TTLdata.CTTL_001_KHz*1000);
                AllTTLu = cell2mat(AllTTLu_sel).*SampleRate./(TTLdata.CTTL_001_KHz*1000);
                for n = 1:floor((nargout-4)/2)
                   varargout{n} = AllTTLd;
                   varargout{n*2} = AllTTLu;
                end
            end
        end
        TS = 1092; %trial start
        SPL1 = 1296; %start pulling lever 1
        EPL1 = 80; %end pulling lever 1
        SPL2 = 1104; %start pulling lever 2
        EPL2 = 336; %end pulling lever 2
        ST = 1024; %success trial
        
        TS_2 = 1092; %trial start
        SPL1_2 = 1424; %start pulling lever 1
        EPL1_2 = 80; %end pulling lever 1
        SPL2_2 = 1104; %start pulling lever 2
        EPL2_2 = 464; %end pulling lever 2
        ST_2 = 1024; %success trial
        
    case {'Ya','Ma','F'}
        TS = 34944; %trial start
        SPL1 = 49664; %start pulling lever 1
        EPL1 = 2560; %end pulling lever 1
        SPL2 = 35328; %start pulling lever 2
        EPL2 = 18944; %end pulling lever 2
        ST = 32768; %success trial
        
        TS_2 = 34944; %trial start
        SPL1_2 = 49664; %start pulling lever 1
        EPL1_2 = 2560; %end pulling lever 1
        SPL2_2 = 35328; %start pulling lever 2
        EPL2_2 = 18944; %end pulling lever 2
        ST_2 = 32768; %success trial
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Summarize the sequence of each timing and event code for a successful task.
% (Since there may be two types of event codes depending on the timing, create an array with two patterns)
perfect_task = [TS, SPL1, EPL1, SPL2, EPL2, ST];
perfect_task_2 = [TS_2, SPL1_2, EPL1_2, SPL2_2, EPL2_2, ST_2];
Lp = length(perfect_task);

% Summarize in a cell array at each timing data
Timing_sel = cell(1,Lp);
for ii = 1:Lp
    % Extract elements with timing(ii) event codes from AllInPort
    Timing_alt = AllInPort(:, find((AllInPort(2,:)==perfect_task(ii))+(AllInPort(2,:)==perfect_task_2(ii))));
    % Offset start of TimeRange to 0 (In CInport, original 0 correspond to 'TimeBegin = 0')
    Timing_alt(1,:) = Timing_alt(1,:) - TimeRange_EMG(1) * S1.CInPort_001_KHz * 1000; 
    % Match the sampling frequency after resampling
    Timing_alt(1,:) = floor(Timing_alt(1,:)/(S1.CInPort_001_KHz/(SampleRate/1000)));
    Timing_sel{ii} = Timing_alt;
end

Timing = cell2mat(Timing_sel);

% Sort 'Timing' by the value of the 1st row
[~, I] = sort(Timing(1,:));
Timing = Timing(: ,I); 

% Count the number of elements with the ID of 'success_trial'
suc = find(Timing(2,:)==perfect_task(end)); %
suc_num = length(suc);
perfect3_task = [perfect_task perfect_task perfect_task];

% Search from trial 3 to last trial to see if the condition is satisfied.
Tp_sub = zeros(suc_num-1,Lp);
for s = 3:suc_num 
    if (Timing(2, suc(s)-Lp+1) == perfect_task(1) && Timing(2, suc(s)-Lp+2) == perfect_task(2) && ...
       Timing(2, suc(s)-Lp+3) == perfect_task(3) && Timing(2, suc(s)-Lp+4) == perfect_task(4) && ...
       Timing(2, suc(s)-Lp+5) == perfect_task(5) && Timing(2, suc(s)-Lp+6) == perfect_task(6))||...
       (Timing(2, suc(s)-Lp+1) == perfect_task_2(1) && Timing(2, suc(s)-Lp+2) == perfect_task_2(2) && ...
       Timing(2, suc(s)-Lp+3) == perfect_task_2(3) && Timing(2, suc(s)-Lp+4) == perfect_task_2(4) && ...
       Timing(2, suc(s)-Lp+5) == perfect_task_2(5) && Timing(2, suc(s)-Lp+6) == perfect_task_2(6))

        Tp_sub(s-1,:) = Timing(1, suc(s)-Lp+1:suc(s));
    end
end

% Exclude trials that did not meet the condition (excluding rows with 0)
Tp = Tp_sub(Tp_sub(:,1) ~= 0,:);


% Summarize the timing of 3 consecutive successful trials.
Tp3_sub = zeros(suc_num-1,length(perfect3_task));
for s = 4:suc_num
    state = 0;
    for n = 1:3
        if (Timing(2, suc(s)-Lp*n+1) == perfect_task(1) && Timing(2, suc(s)-Lp*n+2) == perfect_task(2) && ...
           Timing(2, suc(s)-Lp*n+3) == perfect_task(3) && Timing(2, suc(s)-Lp*n+4) == perfect_task(4) && ...
           Timing(2, suc(s)-Lp*n+5) == perfect_task(5) && Timing(2, suc(s)-Lp*n+6) == perfect_task(6))||...
           (Timing(2, suc(s)-Lp*n+1) == perfect_task_2(1) && Timing(2, suc(s)-Lp*n+2) == perfect_task_2(2) && ...
           Timing(2, suc(s)-Lp*n+3) == perfect_task_2(3) && Timing(2, suc(s)-Lp*n+4) == perfect_task_2(4) && ...
           Timing(2, suc(s)-Lp*n+5) == perfect_task_2(5) && Timing(2, suc(s)-Lp*n+6) == perfect_task_2(6))
            state = state +1;
        end
    end
    if state == 3
        Tp3_sub(s-3,:) = Timing(1, suc(s)-Lp*3+1:suc(s));
    end
end
Tp3 = Tp3_sub(Tp3_sub(:,1) ~= 0,:);
end

%% 3. function to extract timing data for Nibali
function [Timing,Tp,Tp3] = makeEasyTiming_Nibali(real_name, monkeyname, xpdate, file_num, downdata_to)
load_file_path = fullfile(pwd, real_name, [monkeyname xpdate '-' sprintf('%04d', file_num(1))]);
make_timing_struct = load(load_file_path, 'CAI*', 'CTTL*');
timing_struct = struct();
multple_value = downdata_to / (make_timing_struct.CTTL_002_KHz * 1000);

% make digitai timing matrix from CAI signal
CAI_signal = make_timing_struct.CAI_001;
start_end_timing_array_candidate = find(CAI_signal > -100);

% 1.extract 'start' and 'end' timing
start_timing_array = eliminate_consective_num(start_end_timing_array_candidate, 'front');
end_timing_array = eliminate_consective_num(start_end_timing_array_candidate, 'back');

% 2. make timing_id array
start_end_num = length(start_timing_array);
start_id_array = ones(1, start_end_num) * 1;
end_id_array = ones(1, start_end_num) * 4;

% 3.resample and make array (which is consist of timing and id)
start_timing_array = round(start_timing_array * multple_value);
timing_struct.start_timing_array = [start_timing_array; start_id_array];
end_timing_array = round(end_timing_array * multple_value);
timing_struct.end_timing_array = [end_timing_array; end_id_array];

% make 'grasp on', 'grasp off' and 'success' timing
%1. assign timing data in each array
[grasp_signal, id_vector] = sort([make_timing_struct.CTTL_002_Down; make_timing_struct.CTTL_002_Up], 1);
if not(unique(id_vector(1, :)) == 1)
    error('Inconsistent sort order of "grasp on" and "grasp off"');
end
grasp_on_timing_array = grasp_signal(1, :);
grasp_off_timing_array = grasp_signal(2, :);
success_timing_array = make_timing_struct.CTTL_003_Down;

%2. assign id in each array
grasp_on_id = ones(1, length(grasp_on_timing_array)) * 2;
grasp_off_id = ones(1, length(grasp_off_timing_array)) * 3;
succcess_id = ones(1, length(success_timing_array)) * 5;

% 3.resample and make array (which is consist of timing and id)
grasp_on_timing_array = round(grasp_on_timing_array * multple_value);
timing_struct.grasp_on_timing_array = [grasp_on_timing_array; grasp_on_id];
grasp_off_timing_array = round(grasp_off_timing_array * multple_value);
timing_struct.grasp_off_timing_array = [grasp_off_timing_array; grasp_off_id];
success_timing_array = round(success_timing_array * multple_value);
timing_struct.success_timing_array = [success_timing_array; succcess_id];

% merge and crearte all_timing_data
% 1st stage screening
ref_timing_array1 = [timing_struct.start_timing_array , timing_struct.grasp_on_timing_array, timing_struct.grasp_off_timing_array, timing_struct.end_timing_array];
[~, sort_sequence] = sort(ref_timing_array1(1, :));
ref_timing_array1 = ref_timing_array1(:, sort_sequence);

% get the index of the element that matches the condition1
condition1 = [1, 2, 3, 4];
necessary_idx = [];
for ref_start_id = 1:length(ref_timing_array1)-3
    if all(ref_timing_array1(2, ref_start_id:ref_start_id+3) == condition1)
        necessary_idx = [necessary_idx ref_start_id:ref_start_id+3];
    end
end
match_1st_array = ref_timing_array1(:, necessary_idx);

% marge ref_timing_array and success_timing_array & update ref_timing_array which matches the condition2
ref_timing_array2 = [match_1st_array timing_struct.success_timing_array];
[~, sort_sequence] = sort(ref_timing_array2(1, :));
ref_timing_array2 = ref_timing_array2(:, sort_sequence);

% get the index of the element that matches the condition2
condition2 = [1, 2, 3, 4, 5];
necessary_idx = [];
for ref_start_id = 1:length(ref_timing_array2)-4
    if all(ref_timing_array2(2, ref_start_id:ref_start_id+4) == condition2)
        necessary_idx = [necessary_idx ref_start_id:ref_start_id+4];
    end
end
match_2nd_array = ref_timing_array2(:, necessary_idx);

% get the index of the element that matches the condition3
condition3 = [1 2 3 4 2 3 1 2 3 4 2 3 1 2 3 4];
necessary_idx = [];
for ref_start_id = 1:length(ref_timing_array1)-15
    if all(ref_timing_array1(2, ref_start_id:ref_start_id+15) == condition3)
        necessary_idx = [necessary_idx ref_start_id:ref_start_id+15];
    end
end
match_3rd_array = ref_timing_array1(:, necessary_idx);

% create output arguments
Timing = match_2nd_array;
Tp = reshape(Timing(1, :), 5, [])';
Tp3 = reshape(match_3rd_array(1,:), 16, [])';
end

%% for drawer task
%{
[explanation of this func]:
Function to obtain the event timing of the 'drawer task'. 
('drawer task' is the task performed in the 'Hugo' experiment. More monkeys may perform this task in the future.)

[input arguments]:
real_name: [char], full name of monkey
monkeyname: [char], prefix of file
xpdate_num: [double], date of experiment
file_num: [double list], List of numbered experimental data files for the date of interest  (ex.) [2, 4]
downdata_to: [double], Sampling rate of the signal after resampling.

[output arguments]:
Timing: [double array], Array containing the id and timing of each event timing.
Tp: [double array], Data for each timing in each trial is stored.
Tp3: [double array], Data for each timing in each trial is stored.
%}

function [Timing,Tp,Tp3, is_condition2_active] = makeEasyTiming_drawer(real_name, monkeyname, xpdate, file_num, downdata_to, success_button_count_threshold, time_restriction_flag, time_restriction_threshold)
load_file_path = fullfile(fileparts(pwd), 'useDataFold', real_name, [monkeyname xpdate '-' sprintf('%04d', file_num(1))]);
make_timing_struct = load(load_file_path, 'CAI*', 'CTTL*');
timing_struct = struct();
multple_value = downdata_to / (make_timing_struct.CTTL_002_KHz * 1000);

% make digitai timing matrix from CAI signal
CAI_signal = make_timing_struct.CAI_001;
start_end_timing_array_candidate = find(CAI_signal > -100);

% 1.extract 'start' and 'end' timing
start_timing_array = eliminate_consective_num(start_end_timing_array_candidate, 'front');
end_timing_array = eliminate_consective_num(start_end_timing_array_candidate, 'back');

% 2. make timing_id array
start_end_num = length(start_timing_array);
start_id_array = ones(1, start_end_num) * 1;
end_id_array = ones(1, start_end_num) * 6;

% 3.resample and make array (which is consist of timing and id)
start_timing_array = round(start_timing_array * multple_value);
timing_struct.start_timing_array = [start_timing_array; start_id_array];
end_timing_array = round(end_timing_array * multple_value);
timing_struct.end_timing_array = [end_timing_array; end_id_array];

% make 'drawer on', 'drawer off',  'food on', 'food off' timing.
%1. assign timing data in each array
[photo_sensor_signal, id_vector] = sort([make_timing_struct.CTTL_002_Down; make_timing_struct.CTTL_002_Up], 1);
if not(unique(id_vector(1, :)) == 1)
    error('Inconsistent sort order of "grasp on" and "grasp off"');
end
photo_on_timing_array = photo_sensor_signal(1, :);
photo_off_timing_array= photo_sensor_signal(2, :);

success_timing_array = make_timing_struct.CTTL_003_Down;

%2. assign id in each array
photo_on_id = ones(1, length(photo_on_timing_array)) * 2;
photo_off_id = ones(1, length(photo_off_timing_array)) * 3;
succcess_id = ones(1, length(success_timing_array)) * 7;

% 3.resample and make array (which is consist of timing and id)
photo_on_timing_array = round(photo_on_timing_array * multple_value);
timing_struct.photo_on_timing_array = [photo_on_timing_array; photo_on_id];
photo_off_timing_array = round(photo_off_timing_array * multple_value);
timing_struct.photo_off_timing_array = [photo_off_timing_array; photo_off_id];
success_timing_array = round(success_timing_array * multple_value);
timing_struct.success_timing_array = [success_timing_array; succcess_id];

% merge and crearte all_timing_data
% 1st stage screening
ref_timing_array1 = [timing_struct.start_timing_array , timing_struct.photo_on_timing_array, timing_struct.photo_off_timing_array, timing_struct.end_timing_array];
[~, sort_sequence] = sort(ref_timing_array1(1, :));
ref_timing_array1 = ref_timing_array1(:, sort_sequence);
ref_timing_array1 = sortAlgorithmforDrawer(ref_timing_array1);

% get the index of the element that matches the condition1
condition1 = [1, 2, 3, 2, 3, 6];
necessary_idx = [];
validate_length = length(condition1) - 1;
for ref_start_id = 1 : (length(ref_timing_array1) - validate_length)
    if all(ref_timing_array1(2, ref_start_id : (ref_start_id + validate_length)) == condition1)
        necessary_idx = [necessary_idx ref_start_id : (ref_start_id + validate_length)];
    end
end
match_1st_array = ref_timing_array1(:, necessary_idx);

% marge ref_timing_array and success_timing_array & update ref_timing_array which matches the condition2
success_button_count = length(timing_struct.success_timing_array);
is_condition2_active = false;
if success_button_count > success_button_count_threshold
    is_condition2_active = true;
end

if is_condition2_active
    ref_timing_array2 = [match_1st_array timing_struct.success_timing_array];
    [~, sort_sequence] = sort(ref_timing_array2(1, :));
    ref_timing_array2 = ref_timing_array2(:, sort_sequence);
    
    % get the index of the element that matches the condition2
    condition2 = [1, 2, 3, 2, 3, 6, 7];
    necessary_idx = [];
    validate_length = length(condition2) - 1;
    for ref_start_id = 1:length(ref_timing_array2) - validate_length
        if all(ref_timing_array2(2, ref_start_id:ref_start_id + validate_length) == condition2)
            necessary_idx = [necessary_idx ref_start_id:ref_start_id + validate_length];
        end
    end
    match_2nd_array = ref_timing_array2(:, necessary_idx);
    Timing = match_2nd_array;
    representative_condition = condition2;
else
    Timing = match_1st_array;
    representative_condition = condition1;
end

% get the index of the element that matches the condition3
condition3 = repmat([1 2 3 2 3 6], 1, 3);
necessary_idx = [];
validate_length = length(condition3) - 1;
for ref_start_id = 1:length(ref_timing_array1) - validate_length
    if all(ref_timing_array1(2, ref_start_id:ref_start_id+validate_length) == condition3)
        necessary_idx = [necessary_idx ref_start_id:ref_start_id + validate_length];
    end
end
match_3rd_array = ref_timing_array1(:, necessary_idx);

% create output arguments
Tp = reshape(Timing(1, :), length(representative_condition), [])';

if time_restriction_flag
    trial_time = (Tp(:,end) - Tp(:,1)) / downdata_to;
    Tp = Tp(trial_time(:, 1) < time_restriction_threshold, :);
end

Tp3 = reshape(match_3rd_array(1,:), length(condition3), [])';
end

%% 4.Confirm cross-talk of each other's electrodes
function [ref_trial_data, ref_trial_data_diff3] = getCTcheck(AllData_EMG,Tp, EMG_num, trial_id, sampling_rate)
% Create EMG dataset per trial
ref_trial_start_timing = Tp(trial_id, 1) + 1;
ref_trial_end_timing = Tp(trial_id, end);
ref_trial_data = zeros(EMG_num, ref_trial_end_timing - ref_trial_start_timing);
for EMG_id = 1:EMG_num
    ref_trial_data(EMG_id,:) = transpose(AllData_EMG(ref_trial_start_timing+1 : ref_trial_end_timing, EMG_id));
end

% Calculate cross-talk
ref_trial_data_diff3 = cell(EMG_num,1);
dt = 1/sampling_rate;     % step size

for EMG_id = 1:EMG_num
    ref_data = ref_trial_data(EMG_id, :);
    ref_data_1diff = diff(ref_data)/dt;   
    ref_data_2diff = diff(ref_data_1diff)/dt;   % second derivative（前のDsをさらにDsする）
    ref_data_3diff = diff(ref_data_2diff)/dt;
    ref_trial_data_diff3{EMG_id} = ref_data_3diff;
end

ref_trial_data_diff3 = cell2mat(ref_trial_data_diff3);
end

