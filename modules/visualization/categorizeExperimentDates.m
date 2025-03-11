%{
[Function Description]
This function categorizes experimental dates as pre-surgery, post-surgery, or both based on reference dates.
It analyzes Pdata files in the specified directory and determines the period type based on
the position of the first and last selected files relative to the surgery date.

[Input Arguments]
surgery_day: [char] Surgery day in 'yymmdd' format used as reference point
data_directory: [char] Path to the folder containing Pdata files
first_file_name: [char] Name of the first Pdata file selected by the user
last_file_name: [char] Name of the last Pdata file selected by the user

[Output Arguments]
filtered_days: [double array] List of days that match the determined period type
period_type: [char] Identified period type ('pre', 'post', or 'both')
%}

function [filtered_days, period_type] = categorizeExperimentDates(surgery_day, data_directory, first_file_name, last_file_name)
    % Get all Pdata files in the specified folder
    pdata_files = dirPlus(fullfile(data_directory, '*_Pdata.mat'));
    file_names = {pdata_files.name};
    total_files = length(file_names);
    
    % Extract date numbers from file names
    experiment_dates = zeros(total_files, 1);
    for file_index = 1:total_files
        % Extract number part from file name (format: yymmdd_Pdata.mat)
        date_matches = regexp(file_names{file_index}, '\d+', 'match');
        experiment_date = date_matches{1};
        experiment_dates(file_index) = str2double(experiment_date);
    end

    % Determine period type based on the first and last selected files
    first_date_matches = regexp(first_file_name, '\d+', 'match');
    first_reference_date = first_date_matches{1};
    days_from_surgery_first = CountElapsedDate(first_reference_date, surgery_day);
    
    last_date_matches = regexp(last_file_name, '\d+', 'match');
    last_reference_date = last_date_matches{1};
    days_from_surgery_last = CountElapsedDate(last_reference_date, surgery_day);
    
    % Categorize based on both files' positions relative to surgery day
    if days_from_surgery_first < 0 && days_from_surgery_last < 0
        % Both files are before surgery
        period_type = 'pre';
    elseif days_from_surgery_first >= 0 && days_from_surgery_last >= 0
        % Both files are after surgery
        period_type = 'post';
    else
        % Files span across the surgery date
        period_type = 'both';
    end
    
    % Get days that match the determined period type
    if strcmp(period_type, 'both')
        % Return all experiment dates for 'both' period type
        filtered_days = experiment_dates;
    else
        % Filter dates based on period type
        filtered_days = filterDatesByPeriodType(experiment_dates, period_type, surgery_day);
    end
end