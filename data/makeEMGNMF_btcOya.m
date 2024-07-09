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
pre:fitlerBat_SynNMFPre.m
post:
if you want to plot VAF value 
    => plotVAF.m
if you want to find the optimal number of synergy from the synergy data of each session(day)
    =>FindOptimalSynergyNum.m

[Improvement points(Japanaese)]
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
%% set param
monkeyname = 'F'; % prefix of recorded data
nmf_fold_name = 'new_nmf_result'; % name of nmf folder

% about algorithm & threshold
kf = 4; % How many parts of data to divide in cross-validation
nrep = 20; % repetition number of synergy search
nshuffle = 1; % whether you want to confirm shuffle
alg = 'mult'; % algorism of nnmf (mult: Multiplicative Update formula, als: Alternating Least Squares formula)

%% code section
warning('off');

% get the real monkey name
[realname] = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname, nmf_fold_name);

% get info about dates of analysis data and used EMG
disp('ÅyPlease select all day folders you want to analyze (Multiple selections are possible)Åz)')
InputDirs   = uiselect(dirdir(base_dir),1,'Please select folders which contains the data you want to analyze');

InputDir    = InputDirs{1};
% Assign all file names contained in InputDirs{1} to Tarfiles
Tarfiles = sortxls(dirmat(fullfile(base_dir,InputDir)));
disp('ÅyPlease select used EMG DataÅz')
Tarfiles    = uiselect(Tarfiles,1,'Please select all filtered muscle data');

% determine OutputDirs(where to save the result data)
OutputDir   = fullfile(base_dir, InputDir);
day_part = regexp(InputDir, '\d+', 'match');
prev_day = day_part{1};
if(OutputDir==0)
    disp('User pressed cancel.')
    return;
else
    setconfig(mfilename,'OutputDir',OutputDir);
end


%% Extract synergies from each measurement data by daily iterations
nDir    = length(InputDirs);
nTar    = length(Tarfiles);

for iDir=1:nDir
    try
        InputDir    = InputDirs{iDir};
        disp([num2str(iDir),'/',num2str(nDir),':  ',InputDir])

        % create matrix of EMG data(XData)
        for iTar=1:nTar % each muscle
            clear('Tar')
            Tarfile     = Tarfiles{iTar};
            Inputfile   = fullfile(base_dir,InputDir,Tarfile);

            % load filtered EMG (and assign it to Tar)
            Tar     = load(Inputfile);
            XData   = ((1:length(Tar.Data))-1)/Tar.SampleRate;
            
            % make the empty double matrix to store all selected EMG (which is filtered)
            if(iTar==1)
                X   = zeros(nTar,size(Tar.Data, 2));
                Name = cell(nTar,1);
            end
            X(iTar,:)   = Tar.Data;
            Name{iTar}  = deext(Tar.Name);
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
        Y.Name          = InputDir;
        Y.AnalysisType  = 'EMGNMF';
        Y.TargetName    = Name;
        Y.Info.Class        = Tar.Class;
        Y.Info.SampleRate   = Tar.SampleRate;
        Y.Info.Unit         = Tar.Unit;
        
        % create a full path of the file to save
        temp = regexp(InputDir, '\d+', 'match');
        current_day = temp{1};
        OutputDir = strrep(OutputDir, prev_day, current_day);
        prev_day = current_day;
        Outputfile      = fullfile(OutputDir,[InputDir,'.mat']);
        Outputfile_dat  = fullfile(OutputDir,['t_',InputDir,'.mat']);
        
        % save structure data to the specified path(contents of Outputfile & Outputfile_dat)
        save(Outputfile,'-struct','Y');
        disp(Outputfile)
        save(Outputfile_dat,'-struct','Y_dat');
        disp(Outputfile_dat)
    catch 
        errormsg    = ['****** Error occured in ',InputDirs{iDir}];
        disp(errormsg)
        errorlog(errormsg);
    end
end
%MailClient;
%sendmail('toya@ncnp.go.jp',InputDir,'makeEMGNMF_btc Analysis Done!!!');
warning('on');