function tcorr_btc(maxlag,TimeRange,PairingMethod,diff3_flag,RefDataType)
% time-shifted correlation
% tcorr_btc(maxlag,TimeRange,PairingMethod,diff3_flag,RefDataType)
% PairingMethod    = 'all', one-to-one, 'combination';
% RefDataType   = direction of Target data {'normal'} 'inverse' 'transpose2'

if nargin < 2
    TimeRange       = [-inf inf];
    PairingMethod      = 'all';
    diff3_flag      = 0;
    RefDataType   = 'normal'; % direction of Target data {'normal'} 'inverse' 'transpose2'
elseif nargin < 3
    PairingMethod      = 'all';
    diff3_flag      = 0;
    RefDataType   = 'normal'; % direction of Target data {'normal'} 'inverse' 'transpose2'
elseif nargin < 4
    diff3_flag      = 0;
    RefDataType   = 'normal'; % direction of Target data {'normal'} 'inverse' 'transpose2'
elseif nargin < 5
    RefDataType   = 'normal'; % direction of Target data {'normal'} 'inverse' 'transpose2'
end

if(isempty(PairingMethod))
    PairingMethod      = 'all';
end

disp(['RefDataType= ' RefDataType])
alpha   = 0.05;

warning('off');


ParentDir   = getconfig(mfilename,'ParentDir');
try
    if(~exist(ParentDir,'dir'))
        ParentDir   = pwd;
    end
catch
    ParentDir   = pwd;
end
ParentDir   = uigetdir(ParentDir,'�e�t�H���_��I�����Ă��������B');
if(ParentDir==0)
    disp('User pressed cancel.')
    return;
else
    setconfig(mfilename,'ParentDir',ParentDir);
end

InputDirs   = uiselect(dirdir(ParentDir),1,'�ΏۂƂ���Experiments��I�����Ă�������');

InputDir    = InputDirs{1};
unique_name_list    = dirmat(fullfile(ParentDir,InputDir));
unique_name_list    = strfilt(unique_name_list,'~._');


Reffiles    = uiselect(sortxls(unique_name_list),1,'Reference file��I�����Ă�������');
Tarfiles    = uiselect(sortxls(unique_name_list),1,'Target file��I�����Ă�������');

Tar         = load(fullfile(ParentDir,InputDir,Tarfiles{1}));
if(~isfield(Tar,'XData')) % data�̂Ƃ�
    Trigfile     = uichoice(sortxls(unique_name_list),'TimeRange�̃g���K�[�ƂȂ�Time Stamp channel��I�����Ă�������');
    
    if(iscell(Trigfile))
        Trigfile     = Trigfile{1};
    end
    
    if(~isempty(Trigfile))
        StartTriggerIndex   = inputdlg({'Start Trigger Index:'},'Start Trigger',1,{'1'});
        if(isempty(StartTriggerIndex))
            disp('User Pressed cancel')
            return;
        else
            StartTriggerIndex   = str2double(StartTriggerIndex{1});
        end
    else
        StartTriggerIndex   = [];
    end
    mda_flag    = true;
else    % sta file�̂Ƃ�
    Trigfile      = [];
    StartTriggerIndex   = [];
    mda_flag   = false;
end


nDir    = length(InputDirs);
nRef    = length(Reffiles);
nTar    = length(Tarfiles);

switch PairingMethod
    case 'all'
        RefInd  = reshape(repmat(1:nRef,nTar,1),nRef*nTar,1);
        TarInd  = reshape(repmat((1:nTar)',1,nRef),nRef*nTar,1);
        nPair   = nRef*nTar;
    case 'one-to-one'
        if(nRef~=nTar)
            error('Reference files��Target files�̐����Ⴂ�܂�.')
        end
        RefInd  = (1:nRef)';
        TarInd  = (1:nTar)';
        nPair   = nRef;
    case 'combination'
        if(nRef~=nTar)
            error('Reference files��Target files�̐����Ⴂ�܂�.')
        end
        RefInd  = sortrows([nchoosek(1:nRef,2);repmat((1:nRef)',1,2)]);
        TarInd  = RefInd(:,2);
        RefInd  = RefInd(:,1);
        nPair  = length(RefInd);
end




OutputDir   = getconfig(mfilename,'OutputDir');
try
    if(~exist(OutputDir,'dir'))
        OutputDir   = pwd;
    end
catch
    OutputDir   = pwd;
end
OutputDir   = uigetdir(OutputDir,'�o�̓t�H���_��I�����Ă��������B');
if(OutputDir==0)
    disp('User pressed cancel.')
    return;
else
    setconfig(mfilename,'OutputDir',OutputDir);
end


for iDir=1:nDir
    try
        
        InputDir    = InputDirs{iDir};
        disp([num2str(iDir),'/',num2str(nDir),':  ',InputDir])
        
        
        if(mda_flag && ~isempty(Trigfile))
            Trig        = load(fullfile(ParentDir,InputDir,Trigfile));
            Trig.Data   = Trig.Data ./ Trig.SampleRate;
            StartTime   = Trig.Data(StartTriggerIndex);
            TimeRange2  = TimeRange + StartTime;
        else                    % sta file�̂Ƃ�
            TimeRange2  = TimeRange;
        end
        for iPair=1:nPair
            
            % load Reference
            if(iPair==1)
                Reffile = Reffiles{RefInd(iPair)};
                Ref     = load(fullfile(ParentDir,InputDir,Reffile));
            elseif(RefInd(iPair-1)~=RefInd(iPair))
                Reffile = Reffiles{RefInd(iPair)};
                Ref     = load(fullfile(ParentDir,InputDir,Reffile));
            else
                Reffile = Reffiles{RefInd(iPair)};
            end
            
            if(~mda_flag)    % sta file�̂Ƃ�
                
                ind = (Ref.XData >= TimeRange2(1) & Ref.XData <= TimeRange2(2));
                X   = Ref.YData(ind)';
                
            else            % continuous file�̂Ƃ�
                XData   = ([1:length(Ref.Data)]-1)/Ref.SampleRate;
                ind     = (XData >= TimeRange2(1) & XData <= TimeRange2(2));
                X       = Ref.Data(ind)';
            end
            
            if(diff3_flag)
                X   = filter([1 -3 3 -1],1,X);% Apply 3rd order difference;
            end
            
            switch RefDataType
                case 'normal'
                    X   = X;
                case 'inverse'
                    X   = X(end:-1:1);
                    disp('RefDataType: inverse');
                case 'transpose2'
                    halfind = round(size(X,1)/2);
                    X   = X([(halfind+1):end,1:halfind]);
                    disp('RefDataType: tranpose2');
            end
            
            % load Target 
            if(iPair==1)
                Tarfile = Tarfiles{TarInd(iPair)};
                Tar     = load(fullfile(ParentDir,InputDir,Tarfile));
            elseif(TarInd(iPair-1)~=TarInd(iPair))
                Tarfile = Tarfiles{TarInd(iPair)};
                Tar     = load(fullfile(ParentDir,InputDir,Tarfile));
            else
                Tarfile = Tarfiles{TarInd(iPair)};
            end
            
            
            if(~mda_flag)    % sta file�̂Ƃ�
                ind     = (Tar.XData >= TimeRange2(1) & Tar.XData <= TimeRange2(2));
                Y       = Tar.YData(ind)';
            else            % continuous file�̂Ƃ�
                XData   = ([1:length(Tar.Data)]-1)/Tar.SampleRate;
                ind     = (XData >= TimeRange2(1) & XData <= TimeRange2(2));
                Y       = Tar.Data(ind)';
            end
            
            
            if(diff3_flag)
                Y   = filter([1 -3 3 -1],1,Y);% Apply 3rd order difference;
            end

            
            
            % Prepare Output S
            clear('S');
                S.Name          = ['TCORR (',Ref.Name,', ',Tar.Name,')'];
                S.diff3_flag    = diff3_flag;
                S.PairingMethod = PairingMethod;
                S.TimeRange     = TimeRange2;
                S.maxlag        = maxlag;
                S.AnalysisType  = 'TCORR';
                S.TargetName    = deext(Tarfile);
                S.ReferenceName = deext(Reffile);
                S.TriggerName   = deext(Trigfile);
                S.StartTriggerIndex = StartTriggerIndex;
                if(~isempty(Trigfile))
                    S.nTrigger      = sum(Trig.Data >= TimeRange2(1) & Trig.Data <= TimeRange2(2));
                else
                    S.nTrigger  = [];
                end
                S.RefDataType   = RefDataType;
                
                % ���ݑ��֌W���s��
                maxlagind   = round(maxlag * Tar.SampleRate);
                lagind      = (-maxlagind):maxlagind;
                lag         =  lagind / Tar.SampleRate;
                nlag        = length(lag);
                
                S.xcorrlag      = lag;  % ch1��lag(i)���x���N�������Ƃ���ch2�Ƃ̑��֌W����S.xcorr(:,i)�ɓ����Ă���B
                S.xcorrlaghelp  = 'Target(ex EMG)��lag(ii)�������N�������Ƃ���Reference(ex Spike)�Ƃ̑��֌W����S.xcorr(1,ii)�ɓ����Ă���B';
                S.xcorr         = zeros(1,nlag);
                S.xcorrP        = zeros(1,nlag);
                S.xcorrH        = false(1,nlag);
                S.xcorrLO       = zeros(1,nlag);
                S.xcorrUP       = zeros(1,nlag);
                S.xcorrN        = zeros(1,nlag);
                S.xcorrLOLim    = zeros(1,nlag);
                S.xcorrUPLim    = zeros(1,nlag);
                S.xcorrRmax     = zeros(1,1);
                S.xcorrRmaxlag  = zeros(1,1);
                S.xcorrRmaxP    = zeros(1,1);
                S.xcorrRmaxH    = false(1,1);
                
                if(~mda_flag)    % sta file�̂Ƃ�
                    datalength  = size(X,1);
                    X1  = X(:,1);
                else                        % continuous file�̂Ƃ�
                    datalength  = size(X,1) - maxlagind * 2;
                    X1  = X((maxlagind+1):(maxlagind+datalength),1);
                end
                
                if(~mda_flag)    % sta file�̂Ƃ�
                    Y   = [nan(maxlagind,1);Y(:,1);nan(maxlagind,1)];
                else                        % continuous file�̂Ƃ�
                    Y   = Y;
                end
                for ilag = 1:nlag
                    Y1  = Y(ilag:(ilag+datalength-1));
                    
                    [temp,tempP,tempLO,tempUP]  = corrcoef(Y1,X1,'alpha',alpha,'rows','complete');
                    S.xcorr(1,ilag)      = temp(1,2);
                    S.xcorrP(1,ilag)     = tempP(1,2);
                    S.xcorrH(1,ilag)     = S.xcorrP(1,ilag) < alpha;
                    S.xcorrLO(1,ilag)    = tempLO(1,2);
                    S.xcorrUP(1,ilag)    = tempUP(1,2);
                    N                    = sum(~isnan(X1) & ~isnan(Y1));
                    S.xcorrN(1,ilag)     = N;
                    S.xcorrUPLim(1,ilag) = t2r(tinv(1-alpha/2,N-2),N);
                    S.xcorrLOLim(1,ilag) = - S.xcorrUPLim(1,ilag);
                end
                
                [temp,xcorrRmaxind] = max(abs(S.xcorr(1,:)));
                S.xcorrRmax(1)   = S.xcorr(1,xcorrRmaxind);
                S.xcorrRmaxlag(1)= S.xcorrlag(xcorrRmaxind);
                S.xcorrRmaxP(1)  = S.xcorrP(1,xcorrRmaxind);
                S.xcorrRmaxH(1)  = S.xcorrH(1,xcorrRmaxind);
                
                
                %             S.Name      = Name;
                if(isfield(Tar,'Unit'))
                    S.Unit      = Tar.Unit;
                end
                
                %                     if(any(isnan(S.xcorr)))
                %                         disp('nan�������Ă܂��B')
                %                         keyboard
                %                     end
                
                Outputfile  = fullfile(OutputDir,InputDir,[S.Name,'.mat']);
                if(~exist(fileparts(Outputfile),'dir'))
                    mkdir(fileparts(Outputfile));
                end
                save(Outputfile,'-struct','S');
                disp([num2str(iPair),'/',num2str(nPair),': ',Outputfile])
%             end % iTar
        end % iRef
        
    catch
        errormsg    = ['****** Error occured in ',InputDirs{iDir}];
        disp(errormsg)
        errorlog(errormsg);
    end % try
end % iDir




warning('on');



