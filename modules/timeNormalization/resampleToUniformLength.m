%{
[Function Description]
This function aligns datasets of different lengths to a common target length.
It unifies data length differences between sessions (dates) or trials by resampling
each dataset to the specified target length. The function handles both cell arrays
and double arrays, applying appropriate resampling methods based on the relative
lengths of the input and target data.

[Input Arguments]
inputData: [cell array or double array] Input data to be aligned, where each cell or row
      contains activity data of potentially different lengths
targetLength: [double] Target unified length to which all data will be resampled

[Output Arguments]
resampledData: [cell array or double array] Resampled data with unified length (targetLength)
%}

function [resampledData] = resampleToUniformLength(inputData, targetLength)
% This function changes the construction of data and resamples it to match the target length
if iscell(inputData)
    numElements = max(size(inputData));
    resampledData = cell(numElements, 1);
    for elementIndex = 1:numElements
        [resampledData{elementIndex}] = resampleMatrixData(inputData{elementIndex}, targetLength);
    end
else
   [resampledData] = resampleMatrixData(inputData, targetLength);
end

end

%% Local function definition
function [resampledMatrix] = resampleMatrixData(dataMatrix, targetLength)
% Transpose data matrix to work with column-oriented data
transposedData = dataMatrix';
originalLength = length(transposedData);

% Time normalization by comparing the length of the data with the target length
if length(originalLength) == targetLength
   resampledMatrix = transposedData;
elseif length(originalLength) < targetLength 
   % If data is shorter than target, use interpolation to expand
   resampledMatrix = interpft(transposedData, targetLength, 1);
else
   % If data is longer than target, use resampling to reduce
   resampledMatrix = resample(transposedData, targetLength, length(originalLength));
end

% Re-transpose data matrix to restore original orientation
resampledMatrix = resampledMatrix';
end