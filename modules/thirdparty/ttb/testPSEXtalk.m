function testPSEXtalk(psename)


xfactor     = 2;

% ParentDir   = uigetdir(fullfile(datapath,'STA'),'SpTA�f�[�^�������Ă���e�t�H���_��I�����Ă��������B');


ParentDir   = getconfig(mfilename,'ParentDir');
try
    if(~exist(ParentDir,'dir'));
        ParentDir   = pwd;
    end
catch
    ParentDir   = pwd;
end
ParentDir   = uigetdir(ParentDir,'SpTA�f�[�^�������Ă���e�t�H���_��I�����Ă��������B');
if(ParentDir==0)
    disp('User pressed cancel.')
    return;
else
    setconfig(mfilename,'ParentDir',ParentDir);
end


InputDirs   = uiselect(dirdir(ParentDir),1,'�ΏۂƂ���Experiments��I�����Ă�������');



InputDir    = InputDirs{1};
files       = dirmat(fullfile(ParentDir,InputDir));
files       = strfilt(files,'~._');
files       = uiselect(files,1,'�ΏۂƂ���t�@�C����I�����Ă��������B');
[Trigs,EMG_name_list]= getRefTarName(files);
EMG_name_list        = sortxls(unique(EMG_name_list));


nDirs       = length(InputDirs);
nEMG        = length(EMG_name_list);
uiwait(msgbox(EMG_name_list',['�m�F nEMG=',num2str(nEMG)],'modal'));

% XtalkDir    = uigetdir(fullfile(datapath,'XTALKMTX'),'XTALKMTX�f�[�^�������Ă���t�H���_��I�����Ă��������B');


XtalkDir    = getconfig(mfilename,'XtalkDir');
try
    if(~exist(XtalkDir,'dir'));
        XtalkDir    = pwd;
    end
catch
    XtalkDir    = pwd;
end
XtalkDir    = uigetdir(XtalkDir,'XTALKMTX�f�[�^�������Ă���t�H���_��I�����Ă�������(��''XTALKMTX'')�B');
if(XtalkDir==0)
    disp('User pressed cancel.')
    return;
else
    setconfig(mfilename,'XtalkDir',XtalkDir);
end






for iDir=1:nDirs
    InputDir    = InputDirs{iDir};
    Xtalk       = zeros(nEMG,1);

    try
        for iEMG=1:nEMG
            EMG = EMG_name_list{iEMG};
            %                 file    = ['STA (',Trig,', ',EMG,').mat'];
            file    = strfilt(files,[EMG,' ~._']);
            if(length(file)~=1)
                error('�t�B���^�[���Ă��B��̃t�@�C���ɂȂ�܂���ł����B�t�@�C���̖��O�̕t����������ȉ\��������܂��B')
            end
            file    = file{1};

            s   = load(fullfile(ParentDir,InputDir,file));
            %             if(~isempty(s.sigpeakind))
            if(isfield(s,psename))
                if(~isempty(s.(psename).sigpeakindTW))
                    %                 Xtalk(iEMG) = s.peaks(s.maxsigpeakind).peakd;
                    Xtalk(iEMG) = s.(psename).peaks(s.(psename).maxsigpeakindTW).peakd;
                else
                    Xtalk(iEMG) = NaN;
                end
            else
                Xtalk(iEMG) = NaN;
            end


        end

        Xtalk   = (repmat(Xtalk',nEMG,1) ./ repmat(Xtalk,1,nEMG)) * 100;
        Xtalk(logical(eye(size(Xtalk,1))))  = NaN;
        
        if(exist(fullfile(XtalkDir,'AVEXtalkMTX.mat'),'file'))
            s   = load(fullfile(XtalkDir,'AVEXtalkMTX.mat'));
            disp(fullfile(XtalkDir,'AVEXtalkMTX.mat'));
        else
            s   = load(fullfile(XtalkDir,InputDir(1:end-2)));
            disp(fullfile(XtalkDir,InputDir(1:end-2)));
        end

        
        if(length(s.EMGName)==nEMG)
            mismatch    = zeros(nEMG,1);
            for iEMG=1:nEMG
                a   = EMG_name_list{iEMG};
                ind = strfind(a,'l');
                a(ind)  = [];
                b   = s.EMGName{iEMG};
                ind = strfind(b,'l');
                b(ind)  = [];
%                 
%                 mismatch(iEMG)  = isempty(strfind(a,b));
                mismatch(iEMG)  = ~strcmp(parseEMG(a),parseEMG(b));
            end
        else
            mismatch    = 1;
        end

        if(any(mismatch))
            error('�p���Ă���EMG���Ή����Ă܂���')
        else
            disp('EMG matched!')
        end
        Outputfile  = fullfile(ParentDir,InputDir,'PSEXtalk');

        if(exist([Outputfile,'.mat'],'file'))
            S = load(Outputfile);
            
        else
            S=[];
        end
        
        
        S.AnalysisType          = 'PSEXtalk';
        S.(psename).EMGName   = EMG_name_list;
        S.(psename).PSERatio  = Xtalk;
        S.(psename).xtIndex   = (Xtalk ./ s.Xtalk);
        S.(psename).xtFactor  = xfactor;
        S.(psename).isXtalkMTX= (S.(psename).xtIndex < xfactor & S.(psename).xtIndex > 0);
        S.(psename).isXtalk   = any(S.(psename).isXtalkMTX,1)';


        save(Outputfile,'-struct','S');
        disp(Outputfile)
        
        for iEMG=1:nEMG
            clear('s')
            EMG = EMG_name_list{iEMG};
            %                 file    = ['STA (',Trig,', ',EMG,').mat'];
            file    = strfilt(files,[EMG,' ~._']);
            if(length(file)~=1)
                error('�t�B���^�[���Ă��B��̃t�@�C���ɂȂ�܂���ł����B�t�@�C���̖��O�̕t����������ȉ\��������܂��B')
            end
            file    = file{1};
            
            s   = load(fullfile(ParentDir,InputDir,file));
            s.(psename).isXtalk   = S.(psename).isXtalk(iEMG);
            save(fullfile(ParentDir,InputDir,file),'-struct','s');
            disp(['L-- ',fullfile(ParentDir,InputDir,file)])

        end

    catch
        errormsg    = ['****** Error occured in ',InputDirs{iDir}];
        disp(errormsg)
        errorlog(errormsg);
    end
    %     indicator(0,0)

end