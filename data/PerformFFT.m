%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
THIS FUNCTION IS NOT REQUIRED TO COMPLETE THE ANALYSIS.
IF YOU WANT TO COMPLETE ANALYSIS, PLEASE FOLLOW THE PROCEDURE OF ESSENTIAL FUNCTION 

[your operation]
1. Change some parameters (please refer to 'set param' section)
2. Please run this code

[role of this code]
・function to confirm waveform and power spectrum of signal .
(Please use for considering the detail of filtering(cut off frequency, type of filter, sequence of filter, etc...))

[Saved data location]
as datas:
    EMG_analysis_latest/data/<realname>/easyData/spectrum_datas/<processing-contents>
as figures:
    EMG_analysis_latest/data/<realname>/easyData/power_spectrum_figures/<processing-contents>

[procedure]
pre: runnningEasyfunc.m
post: (if you want), EvaluateSignal.m

[caution!! (japanese)]
highpass, rect, lowpassの処理から複数選択して行う場合は処理の順番は順不同なので注意してください
(highpass => rect => lowpassの順番で行われる)

[Improvement points(Japanaese)]
フィルタリングの順番が順不同なので、変えられるように変更する
フィルタリング後のEMGデータは保存されないので注意(フィルタリング後の筋電の保存はfilterBat_SynNMFPre.mで行ってください)
コードが冗長
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear;
%% set param
monkeyname = 'Ni';
disp_freq_window = [5 500]; % range of frequency which is showed on  power spectrum;
fig_row = 4; %number of rows in subplot (number of columns are desided automatically with reference to this)
EMG_trim_range = [50 60]; % range to display in figure of EMG(0 is record start timing)

filter_on = 1; %1: the case you want to check the filtered EMG, 0: the case you want to check the RAW EMG
% setting of filter(if filter_on==1)
band_pass_on = 0;
band_pass_freq = [50 250];
high_pass_on = 1;
high_pass_freq = 50; % cut off frequency[Hz] of filter
rect_on = 1;
low_pass_on = 0;
low_pass_freq = 450; % cut off freqency[Hz] of filter

%% code section
% get the real monkey name
[realname] = get_real_name(monkeyname);
base_dir = fullfile(pwd, realname, 'easyData');

% get the list of directory name
disp('【Please select all day folders you want to analyze (Multiple selections are possible)】)')
InputDirs   = uiselect(dirdir(base_dir),1,'Please select folders which contains the data you want to analyze');

% set the path to save figures
spectrum_data_save_dir_path = fullfile(base_dir, 'spectrum_datas');
spectrum_fig_save_dir_path = fullfile(base_dir, 'power_spectrum_figures');
EMG_fig_save_dir_path = fullfile(base_dir, 'EMG_figures');
if filter_on==1
    band_pass_message = '';
    hp_message =  '';
    rect_message =  '';
    lp_message =  '';
    original_disp_freq_window = disp_freq_window;

    if band_pass_on == 1
        band_pass_message = ['high-' num2str(band_pass_freq(1)) 'Hz_low-' num2str(band_pass_freq(2)) 'Hz'];
        % change the range of frequency to display
        disp_freq_window = [band_pass_freq(1)-10 band_pass_freq(2) + 10];
    end

    if high_pass_on == 1
        hp_message = ['high-' num2str(high_pass_freq) 'Hz'];
        % change the range of frequency to display
        disp_freq_window(1) = high_pass_freq - 10;
    end

    if  rect_on == 1
        rect_message = 'rect';
        disp_freq_window = original_disp_freq_window;
        % eliminate 0 from disp_freq_window(bacause power of DC component is very huge after rectify)
        if disp_freq_window(1) == 0
            disp_freq_window(1) = 1;
        end
    end

    if low_pass_on == 1
         lp_message = ['low-' num2str(low_pass_freq) 'Hz'];
         % change the range of frequency to display
         disp_freq_window(2) = low_pass_freq + 10;
    end
    message_cell = {band_pass_message hp_message, rect_message, lp_message};
    message_cell = message_cell(~cellfun(@isempty, message_cell));
    message = join(message_cell, '_');
    
    spectrum_data_save_dir_path =  fullfile(spectrum_data_save_dir_path, message{1});
    spectrum_fig_save_dir_path = fullfile(spectrum_fig_save_dir_path, message{1});
    EMG_fig_save_dir_path = fullfile(EMG_fig_save_dir_path, message{1});
else
    spectrum_data_save_dir_path = fullfile(spectrum_data_save_dir_path, 'RAW-data');
    spectrum_fig_save_dir_path = fullfile(spectrum_fig_save_dir_path, 'RAW-data');
    EMG_fig_save_dir_path = fullfile(EMG_fig_save_dir_path, 'RAW-data');
end
makefold(spectrum_data_save_dir_path);
makefold(spectrum_fig_save_dir_path);
makefold(EMG_fig_save_dir_path);

% make empty arrays to sotre the powerspectrum data
power_spectrum_struct = struct();
power_spectrum_struct.exp_days  = cell(length(InputDirs), 1);

% display power spectrum for each EMG of each date
for day_id = 1:length(InputDirs)
    % load signal data(EMG data)
    necessary_part = strrep(InputDirs{day_id}, '_standard', '');
    day_string = strrep (necessary_part, monkeyname, '');
    try
        load(fullfile(base_dir, InputDirs{day_id}, [necessary_part '_EasyData.mat']), 'AllData_EMG', 'SampleRate', 'EMGs');
    catch
        disp([necessary_part '_EasyData.mat does not exist'])
        continue
    end
    AllData_EMG = transpose(AllData_EMG);
    [EMG_num, signal_length] = size(AllData_EMG);

    % setting for FFT
    measured_time = signal_length / SampleRate;
    t = 0:(1/SampleRate):measured_time - (1/SampleRate); %時間の指定(Ts間隔でプロットする用)
    
    % setting for plot
    fig_spectrum = figure("position", [100, 100, 1200, 800]);
    fig_EMG = figure("position", [100, 100, 1200, 800]);
    fig_col = ceil(EMG_num / fig_row);
    x = linspace(0, measured_time, length(AllData_EMG));

    for muscle_id = 1:EMG_num
        ref_signal = AllData_EMG(muscle_id, :);
        % perform offset to eliminate DC components
        ref_signal = ref_signal - mean(ref_signal);

        if filter_on==1
            raw_signal = ref_signal;

            % band-pass filter
            if band_pass_on == 1
                ref_signal = bandpass(ref_signal, band_pass_freq, SampleRate);
            end

            % high-pass filter
            if high_pass_on
                [B,A] = butter(6, (high_pass_freq .* 2) ./ SampleRate, 'high');
                 ref_signal = filtfilt(B,A,ref_signal);
            end

            % rectify
            if rect_on == 1
                ref_signal = abs(ref_signal);
            end

            % low-pass filter
            if low_pass_on == 1
                 [B,A] = butter(6, (low_pass_freq .* 2) ./ SampleRate, 'low');
                 ref_signal = filtfilt(B,A,ref_signal);
            end
        end

        % plot EMG
        figure(fig_EMG);
        subplot(fig_row, fig_col, muscle_id)
        hold on;

        if filter_on==1
            plot(x, raw_signal, DisplayName='raw-signal')
            plot(x, ref_signal, DisplayName='ref-signal', LineWidth=1.2)
            legend();
        else
            plot(x, ref_signal)
        end

        % decoration
        xlim(EMG_trim_range);
        xlabel('elapsed time from start[s]')
        ylabel('Amplitude[uV]');
        grid on;
        title(['EMG of ' EMGs{muscle_id}]);
        hold off;

        % peform fft
        freq_signal = fft(ref_signal);
        f = (0:length(freq_signal)-1) * (1/measured_time); %fを(1/t)倍する ([0 1]Hzの周波数帯の範囲を[0   SR]Hzの周波数帯に拡張するため)
        fshift = (-signal_length/2:signal_length/2-1) * (SampleRate/signal_length); %[0 2pi]から[-pi pi]に変更(共役複素数の関係で)
        yshift = fftshift(freq_signal); %実際にシフト

        % 各周波数でのパワースペクトルを求める
        power = abs(yshift).^2/signal_length; %和になっているので、signal_lengthで割ることを忘れない
        
        % plot spectrum
        figure(fig_spectrum)
        subplot(fig_row, fig_col, muscle_id)
        hold on;
        plot(fshift, power)
     
        % decoration
        xlim(disp_freq_window);
        xlabel('Frequency(Hz)')
        ylabel('power');
        title(['Power Spector of ' EMGs{muscle_id}]);
        hold off;

        %ここにstruct.spectrum_data.<筋肉の名前>フィールドにスペクトルの値を代入するための処理を書く
        power_spectrum_struct.spectrum_data.(necessary_part).(EMGs{muscle_id}) = power;
    end

    % save figure
    if filter_on == 1
         figure(fig_EMG)
         saveas(gcf, fullfile(EMG_fig_save_dir_path, [necessary_part '-EMG(' message{1} ').png']));
         figure(fig_spectrum)
         saveas(gcf, fullfile(spectrum_fig_save_dir_path, [necessary_part '-PowerSpectrum(' message{1} ').png']));
    else
        figure(fig_EMG)
        saveas(gcf, fullfile(EMG_fig_save_dir_path, [necessary_part '-EMG.png']));
        figure(fig_spectrum)
        saveas(gcf, fullfile(spectrum_fig_save_dir_path, [necessary_part '-PowerSpectrum.png']));
    end
    close all;

    % add 'exp_days' field into 'power_spectrum_struct'
    power_spectrum_struct.exp_days{day_id} = day_string;
    power_spectrum_struct.freq_axis.(necessary_part) = fshift;
end
power_spectrum_struct.exp_days = power_spectrum_struct.exp_days(~cellfun('isempty', power_spectrum_struct.exp_days));

%% save data of powerspectrum
save(fullfile(spectrum_data_save_dir_path, ['spectrum_data(' power_spectrum_struct.exp_days{1} '_to_' power_spectrum_struct.exp_days{end} '_' num2str(length(InputDirs)) ').mat']), 'power_spectrum_struct')
