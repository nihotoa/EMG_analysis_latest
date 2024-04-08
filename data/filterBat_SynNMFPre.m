%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code & select data by following guidance (which is displayed in command window after Running this code)

[role of this code]
Preform preprocessing on EMG data and save these filtered data (as .mat file).

[Saved data location]
location: Yachimun/new_nmf_result/'~_standard' (ex.) F170516_standard
file name: the file name changes depending on the preprocessing content.
(ex.) BRD-hp50Hz-rect-lp20Hz-ds100Hz.mat

[procedure]
pre:SAVE4NMF.m
post:makeEMGNMFbtc_Oya.m

[Improvement points(Japanaese)]

%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;

%% set param
monkeyname = 'F'; % prefix of the recorded file
nmf_fold_name = 'new_nmf_result'; % name of nmf folder

%% code section
[realname] = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname, nmf_fold_name);

% get the name of the floder that exists directly under 'Parent dir'
InputDirs   = dirdir(base_dir);
disp('【Plese select all day fold (which contains the data you want to filter】)')
InputDirs   = uiselect(InputDirs,1,'Please select folders which contains the data you want to analyze');

if(isempty(InputDirs))
    disp('User pressed cancel.')
    return;
end
InputDir    = InputDirs{1};

Tarfiles    = sortxls(dirmat(fullfile(base_dir,InputDir)));
disp('【Please select all muscle data(<muscle name>(uV).mat) which you want to filter】')
Tarfiles    = uiselect(Tarfiles,1,'Please select all muscle data');
if(isempty(Tarfiles))
    disp('User pressed cancel.')
    return;
end

for jj=1:length(InputDirs)  % each day
    try
        InputDir    = InputDirs{jj};
         for kk =1:length(Tarfiles)
             Tar = loaddata(fullfile(base_dir,InputDir,Tarfiles{kk}));
             OutputDir   = fullfile(base_dir,InputDir);

             %highpass filtering
             Tar = makeContinuousChannel([Tar.Name,'-hp50Hz'],'butter',Tar,'high',6,50,'both');

             %full wave rectification
             Tar = makeContinuousChannel([Tar.Name,'-rect'],'rectify',Tar);

             %lowpass filtering
             Tar = makeContinuousChannel([Tar.Name,'-lp20Hz'], 'butter', Tar, 'low',6,20,'both');

             %down sampling at 100Hz
             Tar = makeContinuousChannel([Tar.Name,'-ds100Hz'], 'resample', Tar, 100,0);
             
             % save data
             save(fullfile(OutputDir,[Tar.Name,'.mat']),'-struct','Tar');
             disp(fullfile(OutputDir,Tar.Name));     
         end
     catch
      disp(['****** Error occured in ',InputDirs{jj}]) ; 
    end
end
