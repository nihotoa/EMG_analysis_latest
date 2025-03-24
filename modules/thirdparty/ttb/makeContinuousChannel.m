function Y  = makeContinuousChannel(filter_detail_name, command, varargin)
% Y   = makeContinuousChannel(filter_detail_name, 'histogram', refchan(timestamp), sampling rate(Hz));
% Y   = makeContinuousChannel(filter_detail_name, 'spike kernel smoothing', refchan(timestamp), sample rate(Hz), gausian_sd(sec));
% Y   = makeContinuousChannel(filter_detail_name, 'unit conversion', refchan(continuous), gain, offset, unit);   gain＝1Vがいくつになるか(指定した単位による)を指定する。
% Y   = makeContinuousChannel(filter_detail_name, 'resample', refchan(continuous), sample rate(Hz), average_flag);
% Y   = makeContinuousChannel(filter_detail_name, 'linear smoothing', refchan(continuous), window(sec));
% Y   = makeContinuousChannel(filter_detail_name, 'kernel smoothing', refchan(continuous), gausian_sd(sec));
% Y   = makeContinuousChannel(filter_detail_name, 'butter', refchan(continuous),filter_type('low','high','stop'), filter_order, filter_w(Hz), filter_direction('normal','reverse','both');
% Y   = makeContinuousChannel(filter_detail_name, 'cheby2', refchan(continuous),filter_type('low','high','stop'), filter_order, filter_w(Hz), filter_R(dB), filter_direction('normal','reverse','both'));
% Y   = makeContinuousChannel(filter_detail_name, 'fir1', refchan(continuous),filter_type('low','high','stop','bandpass'), filter_order, filter_w(Hz), filter_direction('normal','reverse','both');

% Y   = makeContinuousChannel(filter_detail_name, 'interspike interval', refchan(timestamp), sample rate(Hz));
% Y   = makeContinuousChannel(filter_detail_name, 'remove artifact', refchan(continuous), ArtifactTimes(timestamp chan), timewindow);
% Y   = makeContinuousChannel(filter_detail_name, 'detrend', refchan(continuous), varargin);
%         ex1. S=makeContinuousChannel('New','detrend',s)
%         ex1. S=makeContinuousChannel('New','detrend',s,'const')
%         ex1. S=makeContinuousChannel('New','detrend',s,'linear',10)
%         see also detrend
% Y   = makeContinuousChannel(filter_detail_name, 'rectify', refchan(continuous));
% Y   = makeContinuousChannel(filter_detail_name, 'conversion', refchan(timestamp or interval), sample rate(Hz));
% Y   = makeContinuousChannel(filter_detail_name, 'derivative', refchan(continuous), N(th));
% Y   = makeContinuousChannel(filter_detail_name, 'integral',   refchan(continuous), N(th));

switch command
    case 'histogram' % filter_detail_name, 'histogram', refchan(continuous), sampling rate
        ref = varargin{1};
        common_sample_rate  = varargin{2};
        TotalTime   = ref.TimeRange(2)-ref.TimeRange(1);
        
        XData       = linspace(0,TotalTime,TotalTime*common_sample_rate + 1);   % sec
        XData(end)  = [];
        
        if(isempty(ref.EMG_data))
            
            Y.TimeRange = ref.TimeRange;
            Y.filter_detail_name      = filter_detail_name;
            Y.Class     = 'continuous channel';
            Y.common_sample_rate= common_sample_rate;
            Y.EMG_data      = zeros(size(XData));
            Y.Unit      = 'sps';
        else

            % output
            Y.TimeRange = ref.TimeRange;
            Y.filter_detail_name      = filter_detail_name;
            Y.Class     = 'continuous channel';
            Y.common_sample_rate= common_sample_rate;
            Y.EMG_data      = ref.EMG_data  / ref.common_sample_rate;  % sec
            Y.EMG_data      = hist(Y.EMG_data,XData)*common_sample_rate;
            Y.Unit      = 'sps';
            
        end
        
    case 'spike kernel smoothing' % filter_detail_name, 'threshold', refchan(continuous), rising th(V), falling th(V)
        ref = varargin{1};
        common_sample_rate  = varargin{2};
        sd  = varargin{3};
                
        
        Y   = makeContinuousChannel(filter_detail_name,'histogram',ref,common_sample_rate);
        Y   = makeContinuousChannel(filter_detail_name,'kernel smoothing',Y,sd);
        
        
    case 'unit conversion' % filter_detail_name, 'threshold', refchan(continuous), rising th(V), falling th(V)
        Y       = varargin{1};
        gain    = varargin{2};
        offset  = varargin{3};
        unit    = varargin{4};
        cfactor    = 1;
        Y.filter_detail_name  = filter_detail_name;
        Y.EMG_data  = (Y.EMG_data + offset)*cfactor*gain;
        Y.Unit  = unit;
        
        
    case 'resample' % Y   = makeContinuousChannel(filter_detail_name, 'resample', refchan(continuous), sample rate(Hz), average_flag);
        ref             = varargin{1};
        common_sample_rate      = varargin{2};
        if(nargin<5)
            average_flag    = 0;
        else
            average_flag    = varargin{3};
        end
        
        
        if(ref.common_sample_rate == common_sample_rate)
            Y       = ref;
            Y.filter_detail_name  = filter_detail_name;
            return;
        end
        Y           = ref;
        Y.filter_detail_name  = filter_detail_name;
        
        Y.resample_rate  = common_sample_rate;
        nData       = length(Y.EMG_data);
        XData       = ((1:nData)-1)./ref.common_sample_rate + ref.TimeRange(1); % sec
        TotalTime   = ref.TimeRange(2) - ref.TimeRange(1);
        newnData    = floor(TotalTime*common_sample_rate);
        newTotalTime    = newnData/common_sample_rate;
        newTimeRange   = [0 newTotalTime]+ref.TimeRange(1);
        newXData    = ((1:newnData)-1)./common_sample_rate + newTimeRange(1);
        Y.TimeRange = newTimeRange;
        
        if(average_flag==1)
            disp('resample: average')
            ws      = 1./common_sample_rate;
            ref     = makeContinuousChannel(ref.filter_detail_name, 'linear smoothing', ref, ws);
            
        end
        
        if(ref.common_sample_rate > common_sample_rate)
            % downsample: "interp1" with 'nearest' method
            disp('resample: downsample')
            
            Y.EMG_data  = interp1(XData,ref.EMG_data,newXData,'nearest');
            
        elseif (ref.common_sample_rate < common_sample_rate)
            % upsample: "interp1" with 'spline' method
            disp('resample: upsample')
            
            Y.EMG_data  = interp1(XData,ref.EMG_data,newXData,'spline');
        end
        
        
        
        
    case 'resampleold' % Y   = makeContinuousChannel(filter_detail_name, 'resample', refchan(continuous), sample rate(Hz), average_flag);
        ref             = varargin{1};
        common_sample_rate      = varargin{2};
        if(nargin<5)
            average_flag    = 0;
        else
            average_flag    = varargin{3};
        end
        
        if(ref.common_sample_rate > common_sample_rate)
            % downsample
            disp('resample: downsample')
            
            Y           = ref;
            Y.filter_detail_name      = filter_detail_name;
            
            dind        = ceil(ref.common_sample_rate/common_sample_rate);
            Y.common_sample_rate  = ref.common_sample_rate./dind;
            
            if(average_flag==1)
                disp('resample: average')
                if(mod(dind,2)==0)
                    wn  = [0.5,ones(1,dind-1),0.5]./dind;
                else
                    wn  = ones(1,dind)./dind;
                end
                Y.EMG_data  = conv2(Y.EMG_data,wn,'same');
                %                 Y.EMG_data  = smoothing(Y.EMG_data,wn,'manual');
            end
            
            Y.EMG_data  = Y.EMG_data(1:dind:end);
            
            
        elseif(ref.common_sample_rate < common_sample_rate)
            disp('resample: upsample')
            
            Y       = ref;
            Y.filter_detail_name  = filter_detail_name;
            
            
            TotalTime   = ref.TimeRange(2) - ref.TimeRange(1);
            XData       = linspace(0,TotalTime,TotalTime*ref.common_sample_rate+1);
            XData(end)  = [];
            XDatai      = linspace(0,TotalTime,TotalTime*common_sample_rate+1);
            XDatai(end) = [];
            Y.EMG_data      = interp1(XData,ref.EMG_data,XDatai,'*spline');
            Y.common_sample_rate= common_sample_rate;
        else
            Y       = ref;
            Y.filter_detail_name  = filter_detail_name;
            
        end
        
        
        
        
        

    case 'linear smoothing'        % (filter_detail_name, 'linear smoothing', refchan(continuous), window(sec));
        Y      = varargin{1};
        window = varargin{2};  %sec
        npnt   = round(window * Y.common_sample_rate);
        
        kernel  = ones(1,npnt)/npnt;
        Y.filter_detail_name  = filter_detail_name;
        Y.EMG_data  = conv2(Y.EMG_data,kernel,'same');
        
%         Y.EMG_data  = smoothing(Y.EMG_data,npnt,'boxcar');

        
    case 'kernel smoothing' % filter_detail_name, 'threshold', refchan(continuous), rising th(V), falling th(V)
        ref = varargin{1};
        sd  = varargin{2};
                        
        
        sd  = round(sd * ref.common_sample_rate);
        kernel  = normpdf(-sd*5:sd*5,0,sd);
        
        Y       = ref;
        Y.filter_detail_name  = filter_detail_name;
        Y.EMG_data  = conv2(ref.EMG_data,kernel,'same');
        
    case 'butter'           % filter_detail_name, 'butter', refchan(continuous),,filter_type('low','high','stop'), filter_order, filter_w
        
%         lbuf            = 50000;
        Y               = varargin{1};
        filter_type     = varargin{2};
        filter_order    = varargin{3};
        filter_w        = varargin{4};
        if(length(varargin)>4)
            filter_direction    = varargin{5};
        else
            filter_direction    = 'normal';
        end
        filter_w        = (filter_w .* 2) ./ Y.common_sample_rate;
%         nData           = length(Y.EMG_data);
%         nbuf            = ceil(nData ./ lbuf);
        
        [B,A]   = butter(filter_order,filter_w,filter_type);
        Y.filter_detail_name  = filter_detail_name;
        
        switch lower(filter_direction)
            case 'normal'
                Y.EMG_data  = filter(B,A,Y.EMG_data);
            case 'reverse'
                Y.EMG_data  = filter(B,A,Y.EMG_data(end:-1:1));
                Y.EMG_data  = Y.EMG_data(end:-1:1);
            case 'both'
                Y.EMG_data  = filtfilt(B,A,Y.EMG_data);
        end

    case 'band-pass'           % filter_detail_name, 'butter', refchan(continuous),,filter_type('low','high','stop'), filter_order, filter_w
        Y = varargin{1};
        band_pass_freq = varargin{2};
        
        % peform band-pass filter
        Y.EMG_data = bandpass(Y.EMG_data, band_pass_freq, Y.common_sample_rate);
        Y.filter_detail_name  = filter_detail_name; 

    case 'cheby2'           % filter_detail_name, 'butter', refchan(continuous),,filter_type('low','high','stop'), filter_order, filter_w
        Y               = varargin{1};
        filter_type     = varargin{2};
        filter_order    = varargin{3};
        filter_w        = varargin{4};
        filter_R        = varargin{5};
        if(nargin>5)
            filter_direction    = varargin{6};
        else
            filter_direction    = 'normal';
        end
        filter_w        = (filter_w .* 2) ./ Y.common_sample_rate;
        
        [B,A]   = cheby2(filter_order,filter_R,filter_w,filter_type);
        Y.filter_detail_name  = filter_detail_name;
        
        switch lower(filter_direction)
            case 'normal'
                Y.EMG_data  = filter(B,A,Y.EMG_data);
            case 'reverse'
                Y.EMG_data  = filter(B,A,Y.EMG_data(end:-1:1));
                Y.EMG_data  = Y.EMG_data(end:-1:1);
            case 'both'
                Y.EMG_data  = filtfilt(B,A,Y.EMG_data);
        end
        
        
    case 'fir1'           % filter_detail_name, 'fir1', refchan(continuous),filter_type('low','high','stop','bandpass'), filter_order, filter_w
        
        Y               = varargin{1};
        filter_type     = varargin{2};
        filter_order    = varargin{3};
        filter_w        = varargin{4};
        if(length(varargin)>4)
            filter_direction    = varargin{5};
        else
            filter_direction    = 'normal';
        end
        filter_w        = (filter_w .* 2) ./ Y.common_sample_rate;
        
        B   = fir1(filter_order,filter_w,filter_type);
        Y.filter_detail_name  = filter_detail_name;
        
        switch lower(filter_direction)
            case 'normal'
                Y.EMG_data  = filter(B,1,Y.EMG_data);
            case 'reverse'
                Y.EMG_data  = filter(B,1,Y.EMG_data(end:-1:1));
                Y.EMG_data  = Y.EMG_data(end:-1:1);
            case 'both'
                Y.EMG_data  = filtfilt(B,1,Y.EMG_data);
        end



    case 'interspike interval'%filter_detail_name, 'interspike interval',refchan(timestamp), common_sample_rate(Hz)
        
        ref = varargin{1};
        common_sample_rate  = varargin{2};
%         ref = makeTimestampChannel(filter_detail_name,'resample',ref,common_sample_rate);
        
        if(isempty(ref.EMG_data))
            
            Y.TimeRange = ref.TimeRange;
            Y.filter_detail_name      = filter_detail_name;
            Y.Class     = 'continuous channel';
            Y.common_sample_rate= ref.common_sample_rate;
            Y.EMG_data      = zeros(1,(ref.TimeRange(2)-ref.TimeRange(1))*ref.common_sample_rate);
            Y.Unit      = 'sps';
        else

            % output
            Y.TimeRange = ref.TimeRange;
            Y.filter_detail_name      = filter_detail_name;
            Y.Class     = 'continuous channel';
            Y.common_sample_rate= ref.common_sample_rate;
            Y.EMG_data      = zeros(1,(ref.TimeRange(2)-ref.TimeRange(1))*ref.common_sample_rate);
            nData       = length(ref.EMG_data);
            
            for iData=2:nData
                if( (ref.EMG_data(iData) - ref.EMG_data(iData-1))~=0)

                    ind = [ref.EMG_data(iData-1) ref.EMG_data(iData)];
                    n   = ind(2) - ind(1) + 1;
                    FR  = ref.common_sample_rate / (ind(2) - ind(1));
                    
%                     % method#1 scalar interpolation
                    Y.EMG_data((ind(1)+1):ind(2))   = FR; 

                    % method#2linear interpolation
%                     Y.EMG_data(ind(1):ind(2)) = linspace(Y.EMG_data(ind(1)),FR,n);
                end
            end

            Y.Unit      = 'sps';
        end
        
        Y   = makeContinuousChannel(Y.filter_detail_name, 'resample', Y, common_sample_rate, 1);  % resample (and average)
        
    case 'remove artifact with noise'
        ref   = varargin{1};
        AT  = varargin{2};
        window  = varargin{3};
        
        window  = round(window * ref.common_sample_rate);
        windowlength    = window(2) - window(1) + 1;  
        AT.EMG_data = round(AT.EMG_data * ref.common_sample_rate / AT.common_sample_rate);
        nAT = length(AT.EMG_data);
        
%         sd  = std(ref.EMG_data,0);
        
        Y   = ref;
        Y.filter_detail_name  = filter_detail_name;
        
        for iAT =1:nAT
            ind = AT.EMG_data(iAT) + window;
            sd  = std(ref.EMG_data(ind),0);
            Y.EMG_data(ind(1):ind(2))  = linspace(ref.EMG_data(ind(1)),ref.EMG_data(ind(2)),windowlength) + sd .* randn(1,windowlength);
        end
        
        
    case 'remove artifact'
        ref   = varargin{1};
        AT  = varargin{2};
        window  = varargin{3};
        
        window  = (window * AT.common_sample_rate);
%         AT.EMG_data = round(AT.EMG_data * ref.common_sample_rate / AT.common_sample_rate);
        nAT = length(AT.EMG_data);
        nData   = length(ref.EMG_data);
        
%         sd  = std(ref.EMG_data,0);
        
        Y   = ref;
        Y.filter_detail_name  = filter_detail_name;
        
        for iAT =1:nAT
            ind = ceil((AT.EMG_data(iAT) + window)* ref.common_sample_rate / AT.common_sample_rate);
%             ind = AT.EMG_data(iAT) + window;
            ind = [max(1,ind(1)) min(nData,ind(2))];
            windowlength    = ind(2) - ind(1) + 1;
%             sd  = std(ref.EMG_data(ind),0);
            Y.EMG_data(ind(1):ind(2))  = linspace(Y.EMG_data(ind(1)),Y.EMG_data(ind(2)),windowlength);
        end
        
    case 'detrend'
        ref   = varargin{1};
        varargin(1) =[];
        
        Y   = ref;
        Y.filter_detail_name  = filter_detail_name;
        if(isempty(varargin))
            Y.EMG_data  = detrend(Y.EMG_data);
        else
            Y.EMG_data  = detrend(Y.EMG_data,varargin{:});
        end
        
    case 'rectify'
        ref   = varargin{1};
                
        Y   = ref;
        Y.filter_detail_name  = filter_detail_name;
        Y.EMG_data  = abs(Y.EMG_data);
        
    case 'conversion'
        ref         = varargin{1};
        common_sample_rate  = varargin{2};
        
        switch ref.Class
            case 'interval channel'
                
                S   = makeTimestampChannel(filter_detail_name,'regular',ref.TimeRange,common_sample_rate);
                ref = filterTimestampChannel(filter_detail_name,'within interval',S,ref);
                clear('S');
                
            case 'timestamp channel'
                ref = makeTimestampChannel(filter_detail_name,'resample',ref,common_sample_rate);
        end
        
        Y.TimeRange = ref.TimeRange;
        Y.filter_detail_name      = filter_detail_name;
        Y.Class     = 'continuous channel';
        Y.common_sample_rate= common_sample_rate;
        nData       = (Y.TimeRange(2)-Y.TimeRange(1))*Y.common_sample_rate;
        Y.EMG_data      = false(1,nData);
        Y.EMG_data(ref.EMG_data+1)    = true;      
    
    case 'derivative'   % Y   = makeContinuousChannel(filter_detail_name, 'derivative', refchan(continuous), N(th));

        ref     = varargin{1};
        N       = varargin{2};
        
        Y       = ref;
        Y.filter_detail_name  = filter_detail_name;
        Y.EMG_data  = deriv(Y.EMG_data,N);
        
    case 'integral'   % Y   = makeContinuousChannel(filter_detail_name, 'derivative', refchan(continuous), N(th));

        ref     = varargin{1};
        N       = varargin{2};
        
        Y       = ref;
        Y.filter_detail_name  = filter_detail_name;
        Y.EMG_data  = integ(Y.EMG_data,N);
end
end
