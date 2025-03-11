%{
[Function Description]
This function applies a series of filters to raw EMG data to prepare it for analysis.
The processing pipeline includes offset removal, high-pass filtering, rectification,
low-pass filtering, and downsampling. The function also adjusts timing data to match
the new sampling rate.

[Input Arguments]
raw_emg_data: [double array] Raw EMG data with dimensions [samples x channels]
common_sampling_rate: [double] Original sampling rate of the EMG data in Hz
EMG_num: [integer] Number of EMG channels
success_timing_event_data: [double array] Timing event data for successful trials

[Output Arguments]
filtered_EMG_data: [double array] Processed EMG data after filtering and downsampling
resampled_timing_data: [double array] Timing data adjusted to match the new sampling rate
filter_parameters_struct: [struct] Contains filter parameters with fields:
    - whose: [char] Identifier of the filtering method
    - Hp: [double] High-pass cutoff frequency in Hz
    - Rect: [char] Rectification status ('on' or 'off')
    - Lp: [double] Low-pass cutoff frequency in Hz
    - down: [double] Downsampling rate in Hz
%}
function [filtered_EMG_data, resampled_timing_data, filter_parameters_struct] = filterEMG(raw_emg_data, common_sampling_rate, EMG_num, success_timing_event_data)
    high_pass_cutoff_Hz = 50; 
    low_pass_cutoff_Hz = 20;  
    resampling_rate = 100;   
    
    % offset
    offset_removed_data = zeros(size(raw_emg_data));
    for i = 1:EMG_num
        offset_removed_data(:,i) = raw_emg_data(:,i) - mean(raw_emg_data(:,i));
    end

    % high pass filter
    [hp_coeff_b, hp_coeff_a] = butter(6, (high_pass_cutoff_Hz .* 2) ./ common_sampling_rate, 'high');
    high_pass_filtered_data = zeros(size(offset_removed_data));
    for i = 1:EMG_num
        high_pass_filtered_data(:,i) = filtfilt(hp_coeff_b, hp_coeff_a, offset_removed_data(:,i));
    end
    
    % rectify
    rectified_data = abs(high_pass_filtered_data);

    % low pass filter
    [lp_coeff_b, lp_coeff_a] = butter(6, (low_pass_cutoff_Hz .* 2) ./ common_sampling_rate, 'low');
    low_pass_filtered_data = zeros(size(rectified_data));
    for i = 1:EMG_num
        low_pass_filtered_data(:,i) = filtfilt(lp_coeff_b, lp_coeff_a, rectified_data(:,i));
    end

    % down sampling
    filtered_EMG_data = resample(low_pass_filtered_data, resampling_rate, common_sampling_rate);
    resampled_timing_data = success_timing_event_data * resampling_rate / common_sampling_rate;
    
    % create struct for compiling these data
    filter_parameters_struct = struct(...
        'whose',  'Uchida', ...
        'Hp',     high_pass_cutoff_Hz, ...
        'Rect',   'on', ...
        'Lp',     low_pass_cutoff_Hz, ...
        'down',   resampling_rate ...
    );
end
