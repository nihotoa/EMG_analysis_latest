%{
[Function Description]
This function processes event data from lever pull task experiments.
It extracts timing information from port input signals, identifies successful trials,
and calculates the timing of key events such as lever on/off. The function handles
data from multiple recording files and combines them into a unified timing structure.

[Input Arguments]
monkey_prefix: [char] Prefix identifying the monkey
experiment_day: [char] Date of experiment as a string
validate_file_range: [double array] Range of files to process
SampleRate: [double] Sampling rate of the recorded data in Hz
TimeRange_EMG: [double array] Time range of EMG data

[Output Arguments]
transposed_success_timing: [double array] Timing data for successful trials with dimensions
    [trials x timing_events], containing sample indices for each timing event
%}
function [transposed_success_timing] = processLeverPullTaskEvents(monkey_prefix, experiment_day, validate_file_range, SampleRate, TimeRange_EMG)
Ld = validate_file_range(end)-validate_file_range(1)+1;
%number of file
AllInPort_sel = cell(1,Ld);
get_first_portin = 1;
for i = validate_file_range(1,1):validate_file_range(1,end)
    if get_first_portin
        S1 = load([monkey_prefix experiment_day '-' sprintf('%04d', i) '.mat'], 'CInPort*');
        CInPort = S1.CInPort_001;
    else
        
        S = load([monkey_prefix experiment_day '-' sprintf('%04d', i) '.mat'], 'CInPort_001');
        if ~isempty(struct2cell(S))
           CInPort = S.CInPort_001;
        end
    end
    AllInPort_sel{1,1+i-validate_file_range(1,1)} = CInPort;
    get_first_portin = 0;
end
AllInPort = cell2mat(AllInPort_sel);

%%%%%%%%%%%%%%%%%Define the ID of timing of interest for each experiment%%%%%%%%%%%%%%%%%
switch monkey_prefix
    case {'Wa','Su','Se'}
        if strcmp(monkey_prefix, 'Su') || strcmp(monkey_prefix, 'Se')
            varargout= cell(nargout-4,1);
            AllTTLd_sel = cell(1,Ld);
            AllTTLu_sel = cell(1,Ld);
            count = 1;
            for t = validate_file_range(1):validate_file_range(end)
                TTLdata = load([monkey_prefix experiment_day '-' sprintf('%04d', t) '.mat'], 'CTTL_001*');
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
transposed_success_timing = Tp_sub(Tp_sub(:,1) ~= 0,:);


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
