function BoxPlotFormat(ax,groupNumber,varargin)
%BoxPlotFormat(ax,groupNumber,'PlotElement1','Element1Property,'PropertyValue','PlotElement2','Element2Property,'PropertyValue',...)
%AX is the axis of the plot (e.g., ax = gca)
%groupNumber is which groups of the boxplot the modifications should apply
%to. Input is either an integer, a vector of integers, or 'all'.

%Plot elements can be, with supported properties
%   Outliers    MarkerSize, Marker, MarkerEdgeColor, MarkerFaceColor
%   Median      Color, LineStyle, LineWidth
%   Box         Color, LineStyle, LineWidth
%   Whiskers    Color, LineStyle, LineWidth
%   WhiskerCaps  Color, LineStyle, LineWidth, CapWidth

% Version 1.0, 16/Aug/2024
% Robert Groth 2024, grothqut@gmail.com
% ---------------------------------------------------- %

numArgs = nargin - 2; % Number of variable args
if mod(numArgs,3) ~= 0
    error('Number of variable input arguments must be a multiple of 3.')
end
% Initialise in case 'all' is selected, improves readability and
% performance
if isa(groupNumber,'double') ~= 1
    groupNumber = 1:length(findobj(ax,'tag','Box'));
end

% Empty cell arrays for plot properties we want to change
bp_elements = cell(1,numArgs/3); % Elements are features of box plot (e.g., Outliers, Median - see above)
bp_properties = bp_elements; % Properties are parts of elements (e.g., Color, LineWidth - see above)
bp_values = bp_elements; % Values are the input to the properties (e.g., LineWidth = 2, Color = 'r')
% Populate cell arrays
for ii = 1:numArgs/3
    bp_elements(ii) = varargin(3*ii - 2);bp_properties(ii) = varargin(3*ii - 1);bp_values(ii) = varargin(3*ii);
end

% Correct for input formatting UX
appendElements = {}; appendProps = {}; appendVals = {}; % Cells to append 
cellPops = zeros(size(bp_elements)); % Cells to remove
for ii = 1:length(bp_elements)
    if strcmp(char(bp_elements(ii)),'Outlier') == 1
        bp_elements(ii) = {'Outliers'}; % Change Outlier to Outliers
    elseif strcmp(char(bp_elements(ii)),'Whiskers') == 1
        appendElements = [appendElements,'Lower Whisker','Upper Whisker'];
        appendProps = [appendProps,bp_properties(ii),bp_properties(ii)];
        appendVals = [appendVals,bp_values(ii),bp_values(ii)];
        cellPops(ii) = 1;
    elseif strcmp(char(bp_elements(ii)),'WhiskerCaps') == 1
        appendElements = [appendElements,'Lower Adjacent Value','Upper Adjacent Value'];
        appendProps = [appendProps,bp_properties(ii),bp_properties(ii)];
        appendVals = [appendVals,bp_values(ii),bp_values(ii)];
        cellPops(ii) = 1;
    end
end
% Pop
cellPops = logical(cellPops);
bp_elements(cellPops) = []; bp_properties(cellPops) = []; bp_values(cellPops) = []; % Pop
bp_elements = [bp_elements,appendElements];bp_properties = [bp_properties,appendProps];bp_values = [bp_values,appendVals]; % Append

% Modify plot properties
for ii = 1:length(bp_elements) % Loop over number of PlotElements
    foundElements = findobj(ax,'tag',char(bp_elements(ii)));
    for jj = 1:length(groupNumber) % Loop over groupNumbers
        propInsert = char(bp_properties(ii));
        if strcmp(propInsert,'CapWidth') == 1
            capXdata = foundElements(groupNumber(jj)).XData;
            oldCapWidth = capXdata(2) - capXdata(1);
            capMidpoint = capXdata(1) + oldCapWidth/2; % This is probably == groupNumber(ii) but I can't be bothered verifying
            newCapWidth = str2double(string(bp_values(ii)))*oldCapWidth/2;
            foundElements(groupNumber(jj)).XData = [capMidpoint-newCapWidth, capMidpoint+newCapWidth];
        else
            if strcmp(propInsert,'MarkerSize') == 1 | strcmp(propInsert,'LineWidth') == 1
                valueInsert = str2double(string(bp_values(ii)));
            elseif strcmp(propInsert,'Color') == 1 | strcmp(propInsert,'MarkerEdgeColor') == 1 | strcmp(propInsert,'MarkerFaceColor') == 1
                try
                    valueInsert = char(bp_values(ii)); % if this works, its a char, else, its a rgb triplet
                catch
                    valueInsert = cell2mat(bp_values(ii));
                end
            else
                valueInsert = char(bp_values(ii));
            end
            foundElements(groupNumber(jj)).(propInsert) = valueInsert;
        end
    end
end
end % fend