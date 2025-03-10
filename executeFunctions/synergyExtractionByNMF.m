%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code & select data by following guidance (which is displayed in command window after Running this code)

[role of this code]
Perform muscle synergy analysis and save the results (as .mat file)

[Saved data location]
location:
EMG_analysis/data/Yachimun/new_nmf_result/selected_folder_name (ex.) F170516_standard
file name: selected_folder_name + .mat (ex.)F170516_standard.mat => this file contains analysis conditions, VAF, and other data
                t_ + selected_folder_name + .mat (ex.)t_F170516_standard.mat => this file contains synergy data

[procedure]
pre:filterEMGForNMF.m
post:
if you want to plot VAF value
    => visualizeVAF.m
if you want to find the optimal number of synergy from the synergy data of each session(day)
    =>determineOptimalSynergyNumber.m

[Improvement points(Japanaese)]
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkey_prefix = 'Hu'; % prefix of recorded data
use_EMG_type = 'only_task'; %' full' / 'only_task'

% about algorithm & threshold
kf = 4; % How many parts of data to divide in cross-validation
nrep = 20; % repetition number of synergy search
nshuffle = 1; % whether you want to confirm shuffle
alg = 'mult'; % algorism of nnmf (mult: Multiplicative Update formula, als: Alternating Least Squares formula)

%% code section
root_dir_path = fileparts(pwd);
warning('off');

% get the real monkey name
full_monkey_name = getFullMonkeyName(monkey_prefix);
base_dir_path = fullfile(root_dir_path, 'saveFold', full_monkey_name, 'data', 'Synergy', 'filtered_EMG_data', use_EMG_type);

% get info about dates of analysis data and used EMG
disp('�yPlease select all day folders you want to analyze (Multiple selections are possible)�z)')
day_folder_list   = uiselect(dirdir(base_dir_path),1,'Please select folders which contains the data you want to analyze');

if isempty(day_folder_list)
    disp('user pressed "cancel" button');
    return
end

ref_day_folder = day_folder_list{1};

% Assign all file names contained in day_folder_list{1} to filtered_EMG_file_list
filtered_EMG_file_list = sortxls(dirmat(fullfile(base_dir_path,ref_day_folder)));
disp('�yPlease select used EMG Data�z')
filtered_EMG_file_list = uiselect(filtered_EMG_file_list,1,'Please select all filtered muscle data');

% determine OutputDirs(where to save the result data)
common_extracted_synergy_save_dir = strrep(base_dir_path, 'filtered_EMG_data', 'extracted_synergy');
common_synergy_detail_save_dir = strrep(base_dir_path, 'filtered_EMG_data', 'synergy_detail');

% prev_day = day_part{1};
if isempty(filtered_EMG_file_list)
    disp('User pressed cancel.')
    return;
end


%% Extract synergies from each measurement data by daily iterations
day_num = length(day_folder_list);
muscle_num = length(filtered_EMG_file_list);

for day_id=1:day_num
    ref_day_folder    = day_folder_list{day_id};
    disp([num2str(day_id),'/',num2str(day_num),':  ',ref_day_folder])
    trimmed_flag = 0;

    % create matrix of EMG data(XData)
    for muscle_id=1:muscle_num % each muscle
        clear('ref_filtered_EMG_data_struct')
        ref_filtered_EMG_file = filtered_EMG_file_list{muscle_id};
        ref_filtered_EMG_file_path = fullfile(base_dir_path,ref_day_folder,ref_filtered_EMG_file);
        
        if  muscle_id == 1
            if contains(ref_filtered_EMG_file, '-trimmed')
                trimmed_flag = 1;
                load(ref_filtered_EMG_file_path, "event_timings_after_trimmed");
            end
        end

        % load filtered EMG (and assign it to ref_filtered_EMG_data)
        ref_filtered_EMG_data_struct     = load(ref_filtered_EMG_file_path);
        ref_filtered_EMG = ref_filtered_EMG_data_struct.Data;
        XData   = ((1:length(ref_filtered_EMG))-1)/ref_filtered_EMG_data_struct.SampleRate;
        
        % make the empty double matrix to store all selected EMG (which is filtered)
        if(muscle_id==1)
            X   = zeros(muscle_num,size(ref_filtered_EMG, 2));
            Name = cell(muscle_num,1);
        end
        X(muscle_id,:)   = ref_filtered_EMG;
        Name{muscle_id}  = deext(ref_filtered_EMG_data_struct.Name);
    end

    % Preprocessing for matrix of EMG dataset (X)
    % 1. offset so that the minimum value is 0
    X   = offset(X,'min');
    
    % 2. Each EMG is normalized by the mean of each EMG
    normalization_method    = 'mean';
    X     = normalize(X,normalization_method);
    
    % 3. set negative values to 0 (to avoind taking negative values)
    X(X<0)  = 0;
    
    % Perform NNMF(Non Negative Matrix Factorization) & extract muscle(it takes a lot of time!)
    [Y,Y_dat] = makeEMGNMFOya(X, kf, nrep, nshuffle, alg);

    % Postprocess
    % Add various information to structure Y
    Y.Name          = ref_day_folder;
    Y.AnalysisType  = 'EMGNMF';
    Y.TargetName    = Name;
    Y.Info.Class        = ref_filtered_EMG_data_struct.Class;
    Y.Info.SampleRate   = ref_filtered_EMG_data_struct.SampleRate;
    Y.Info.Unit         = ref_filtered_EMG_data_struct.Unit;
    
    % create a full path of the file to save
    temp = regexp(ref_day_folder, '\d+', 'match');
    
    Y.use_EMG_type = 'full';
    Y_dat.use_EMG_type = 'full';
    if trimmed_flag
        Y.use_EMG_type = 'trimmed';
        Y_dat.use_EMG_type = 'trimmed';
        Y.event_timings_after_trimmed = event_timings_after_trimmed;
        Y_dat.event_timings_after_trimmed = event_timings_after_trimmed;
    end

    % save setting
    extracted_synergy_save_dir = fullfile(common_extracted_synergy_save_dir, ref_day_folder);
    synergy_detail_save_dir = fullfile(common_synergy_detail_save_dir, ref_day_folder);
    makefold(extracted_synergy_save_dir)
    makefold(synergy_detail_save_dir)

    extracted_synergy_file_name = ['t_' ref_day_folder '.mat'];
    synergy_detail_file_name = [ref_day_folder '.mat'];
    
    % save structure data to the specified path(contents of Outputfile & Outputfile_dat)
    save(fullfile(extracted_synergy_save_dir, extracted_synergy_file_name), '-struct','Y_dat');
    disp(fullfile(extracted_synergy_save_dir, extracted_synergy_file_name))
    save(fullfile(synergy_detail_save_dir, synergy_detail_file_name), '-struct','Y');
    disp(fullfile(synergy_detail_save_dir, synergy_detail_file_name))
end
warning('on');