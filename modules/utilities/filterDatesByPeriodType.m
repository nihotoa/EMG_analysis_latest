%{
[Function Description]
This function filters a list of dates based on whether they are before or after a reference date.
It is primarily used to extract pre- or post-treatment dates from a complete date list.

[Input Arguments]
date_list: [cell array or double array] List of dates to filter
period_type: [char] Type of period to filter for ('pre', 'post', or 'both')
reference_date: [char or double] Reference date used as the dividing point

[Output Arguments]
filtered_date_list: [cell array or double array] List of dates that match the specified period type
(Returns the same data type as the input list)

[Note]
The function supports both cell arrays and numeric arrays as input date formats.
When period_type is 'both', the function returns the entire date_list without filtering.
%}

function [filtered_date_list] = filterDatesByPeriodType(date_list, period_type, reference_date)
    % For 'both' period type, return all dates without filtering
    if strcmp(period_type, 'both')
        filtered_date_list = date_list;
        return;
    end
    
    % Get the number of dates in the list
    date_count = length(date_list);
    
    % Calculate days elapsed from reference date for each date in the list
    if iscell(date_list)
        % For cell array input, use makeElapsedDateList function
        [elapsed_date_list] = makeElapsedDateList(date_list, reference_date);
    elseif isa(date_list, 'double')
        % For numeric array input, calculate elapsed days directly
        elapsed_date_list = zeros(date_count, 1);
        for date_index = 1:date_count
            current_date = date_list(date_index);
            elapsed_date_list(date_index) = CountElapsedDate(current_date, reference_date);
        end
    else
        % Handle unsupported data types
        error('Unsupported data type: This function only accepts cell arrays or numeric arrays');
        return;
    end

    % Filter dates based on the specified period type
    switch period_type
        case 'pre'
            % Pre-treatment: dates before the reference date (negative elapsed days)
            filtered_date_list = date_list(elapsed_date_list < 0);
        case 'post'
            % Post-treatment: dates after the reference date (positive elapsed days)
            filtered_date_list = date_list(elapsed_date_list > 0);
        otherwise
            error('Invalid period type: Must be either "pre", "post", or "both"');
    end
end