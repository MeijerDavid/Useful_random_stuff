function [twoDimTable,twoDimMat,rowNames,columnNames,columnIndexing] = nDimMat2TwoDimTable(nDimMat,newFirstDim,newOtherDimOrder,DimNamesCell,LevelNamesCell,ConditionDelimeter)
%Transform N-Dimensional matrix, "nDimMat" into a 2D table, where the rows
%are given by the "newFirstDim" dimension of the input matrix (default=1). 
%The other dimensions will be combined into the columns of the new table 
%with the combination order defined by "newOtherDimOrder" (default = 
%setdiff(1:numel(size(nDimMat)),newFirstDim); i.e. the sorted other dims).

%For example, if input matrix nDimMat is 4 dimensional, and each dimension
%has two levels (i.e. size(nDimMat) == [2 2 2 2]), then the output matrix 
%twoDimMat will have a size of [2 x 8]. The two rows are given by the
%newFirstDim dimension, whereas the eight columns will be given by all 
%possible combinations of the levels of the other three dimensions, where 
%the order of the columns depends on newOtherDimOrder. Suppose newFirstDim
%equals 1, and newOtherDimOrder equals [2 3 4], then:
%column 1 = D2_L1_x_D3_L1_x_D4_L1 
%column 2 = D2_L1_x_D3_L1_x_D4_L2 
%column 3 = D2_L1_x_D3_L2_x_D4_L1 
%column 4 = D2_L1_x_D3_L2_x_D4_L2 
%column 5 = D2_L2_x_D3_L1_x_D4_L1 
%column 6 = D2_L2_x_D3_L1_x_D4_L2 
%column 7 = D2_L2_x_D3_L2_x_D4_L1 
%column 8 = D2_L2_x_D3_L2_x_D4_L2 
%Adjusting the columns order may make it easier to assign condition factors
%in some statistical software packages (e.g. SPSS, JASP) - i.e. columns 
%could represent conditions and rows represent repetitions. 

%Other optional input arguments:
% - "DimNamesCell" is a cell array of 1 x N cells. Each cell contains a
%   character array with the name of this dimension. By default, dimension
%   names are labeled as "D1", "D2", etc.
% - "LevelNamesCell" is a cell array of 1 x N cells, one for each 
%   dimension. Each cell contains another cell array of 1 x L cells, with 
%   L equal to the number of levels in this dimension. Each of these cells
%   contains a character array with the name of this level. By default, 
%   level names are labeled as "L1", "L2", etc.
% - "ConditionDelimeter" is the delimiter that is used to separate the
%   dimension and level combinations in the column names. Default = '_x_'.

% David Meijer, 23-08-2022

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Set default input arguments %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Design fake data?
%nargin = 0;                                     %Flip switch for test with useful example input!
if (nargin < 1) || isempty(nDimMat)
    data1Subj1D = [1000; 2000; 3000];        
    data1Subj2D = repmat(data1Subj1D,[1 4])     + cat(2,100*ones(size(data1Subj1D)),200*ones(size(data1Subj1D)),300*ones(size(data1Subj1D)),400*ones(size(data1Subj1D)));
    data1Subj3D = repmat(data1Subj2D,[1 1 5])   + cat(3,10*ones(size(data1Subj2D)), 20*ones(size(data1Subj2D)), 30*ones(size(data1Subj2D)), 40*ones(size(data1Subj2D)), 50*ones(size(data1Subj2D)));
    nDimMat   = repmat(data1Subj3D,[1 1 1 6]) + cat(4,1*ones(size(data1Subj3D)),  2*ones(size(data1Subj3D)),  3*ones(size(data1Subj3D)),  4*ones(size(data1Subj3D)),  5*ones(size(data1Subj3D)), 6*ones(size(data1Subj3D)));
    clear data1Subj1D data1Subj2D data1Subj3D 
    %To understand this toy example data look at the output for: disp(size(dataMatIn)); disp([dataMatIn(1,1,1,1); dataMatIn(1,2,3,6); dataMatIn(3,1,2,5)]);     
end
dimSizes = size(nDimMat);
nDims = numel(dimSizes);   

%Set default rows dimension to be the first
if (nargin < 2) || isempty(newFirstDim)
    newFirstDim = 1;    
end
nLevFirstDim = dimSizes(newFirstDim);

%Set default desired dimension order for the column conditions
if (nargin < 3) || isempty(newOtherDimOrder)
    newOtherDimOrder = setdiff(1:nDims,newFirstDim);   %Note that by default the list is sorted in ascending order
else
    %If the user does provide a newOtherDimOrder argument, then silently ensure that the newFirstDim is not included in this list   
    newOtherDimOrder(newOtherDimOrder == newFirstDim) = [];
end

%Set default dimension names
if (nargin < 4) || isempty(DimNamesCell)
    DimNamesCell = cell(1,nDims);
    for i_dim = 1:nDims
        DimNamesCell{i_dim} = ['D' num2str(i_dim)];
    end
end

%Set default level names
if (nargin < 5) || isempty(LevelNamesCell)
    LevelNamesCell = cell(1,nDims);
    for i_dim = 1:nDims
        LevelNamesCell{i_dim} = cell(1,dimSizes(i_dim));
        for i_lev = 1:dimSizes(i_dim)
            LevelNamesCell{i_dim}{i_lev} = ['L' num2str(i_lev)];
        end
    end
end

%Set default conditions delimeter
if (nargin < 6) || isempty(ConditionDelimeter)
    ConditionDelimeter = '_x_';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Do the actual work %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%

%For each table column, determine the level nr of each 'other' dimension 
nColumns = prod(dimSizes(newOtherDimOrder));
dimLevPerColumn = cell(nDims,nColumns);
nDim4Columns = nDims-1;
nToDiv = nColumns; %Initialize
for i_dim = 1:nDim4Columns
    
    %Find the required dimension and the number of levels in it
    dimTmp = newOtherDimOrder(i_dim);                                       %Note that we implement the desired dimension order here
    nDimLev = dimSizes(dimTmp);
    
    %Create one smaller row with all dim levels in it
    dimNrPerColumn_Small = nan(1,nToDiv);
    nRepsPerLev = nToDiv/nDimLev;
    counter = 0;
    for i_lev = 1:nDimLev
        dimNrPerColumn_Small(1,counter+(1:nRepsPerLev)) = i_lev;
        counter = counter + nRepsPerLev;
    end
    
    %Repeat the smaller row such that all conditions are filled
    nDivs = nColumns/nToDiv;
    dimLevPerColumn(dimTmp,:) = num2cell(repmat(dimNrPerColumn_Small,[1 nDivs]));
    
    %Adjust the number of divisions for the next dimension
    nToDiv = nRepsPerLev;
end
dimLevPerColumn(newFirstDim,:) = {1:nLevFirstDim};

%Create row names
rowNames = cell(dimSizes(newFirstDim),1);
for i_row = 1:dimSizes(newFirstDim)
    rowNames{i_row} = [DimNamesCell{newFirstDim} '_' LevelNamesCell{newFirstDim}{i_row}];
end

%Create the 2D matrix and the column names list
twoDimMat = nan(nLevFirstDim,nColumns);
columnNames = cell(1,nColumns);
for i_col = 1:nColumns
    
    %Data of this column
    twoDimMat(:,i_col) = nDimMat(dimLevPerColumn{:,i_col});
    
    %Column name
    tmpName = '';
    for i_dim = 1:nDim4Columns
        dimTmp = newOtherDimOrder(i_dim);                                   %Note that we take the desired dimension order into account here
        if i_dim ~= 1
            tmpName = [tmpName ConditionDelimeter];
        end
        tmpName = [tmpName DimNamesCell{dimTmp} '_' LevelNamesCell{dimTmp}{dimLevPerColumn{dimTmp,i_col}}]; 
    end
    columnNames{i_col} = tmpName;
end

%Create a table for output as CSV file
twoDimTable = array2table(twoDimMat,'VariableNames',columnNames,'RowNames',rowNames);

%Create index vectors for which level number of each dimension belongs to which column    
if nargout > 4
    for i_dim = 1:nDim4Columns
        dimTmp = newOtherDimOrder(i_dim);                                   %Note that we take the desired dimension order into account here
        columnIndexing.(DimNamesCell{dimTmp}) = cell2mat(dimLevPerColumn(dimTmp,:));
    end
end

end %[EoF]
