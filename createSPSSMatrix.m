function [dataMatSPSS,conNames,tableCSV] = createSPSSMatrix(dataMatIn,subjDim,DimNamesCell,desiredDimOrderSPSS,Con_delimeter)

%Design fake data?
%nargin = 0;                                     %Flip switch for test!
if (nargin < 1) || isempty(dataMatIn)
    data1Subj1D = [1000; 2000; 3000];        
    data1Subj2D = repmat(data1Subj1D,[1 4])     + cat(2,100*ones(size(data1Subj1D)),200*ones(size(data1Subj1D)),300*ones(size(data1Subj1D)),400*ones(size(data1Subj1D)));
    data1Subj3D = repmat(data1Subj2D,[1 1 5])   + cat(3,10*ones(size(data1Subj2D)), 20*ones(size(data1Subj2D)), 30*ones(size(data1Subj2D)), 40*ones(size(data1Subj2D)), 50*ones(size(data1Subj2D)));
    dataMatIn   = repmat(data1Subj3D,[1 1 1 6]) + cat(4,1*ones(size(data1Subj3D)),  2*ones(size(data1Subj3D)),  3*ones(size(data1Subj3D)),  4*ones(size(data1Subj3D)),  5*ones(size(data1Subj3D)), 6*ones(size(data1Subj3D)));
    clear data1Subj2D data1Subj3D 
end
dimSizes = size(dataMatIn);
nDims = numel(dimSizes);   

%Set default subjects dimension to be the last one
if (nargin < 2) || isempty(subjDim)
    subjDim = nDims;    
end
nSubj = dimSizes(subjDim);

%Set default dimension names
if (nargin < 3) || isempty(DimNamesCell)
    DimNamesCell = cell(nDims,1);
    for i_dim = 1:nDims
        DimNamesCell{i_dim,1} = cell(1,dimSizes(i_dim));
        for i_dimSize = 1:dimSizes(i_dim)
            if i_dim == subjDim
                DimNamesCell{i_dim,1}{1,i_dimSize} = ['Subj_' num2str(i_dimSize)];
            else
                DimNamesCell{i_dim,1}{1,i_dimSize} = ['Dim' num2str(i_dim) '_' num2str(i_dimSize)];
            end
        end
    end
end
SubjNames = DimNamesCell{subjDim,1};

%Set default desired dimension order
if (nargin < 4) || isempty(desiredDimOrderSPSS)
    desiredDimOrderSPSS = setdiff(1:nDims,subjDim);   %Note that by default the list is sorted in ascending order
else
    %If you do provide a desiredDimOrderSPSS argument, then ensure that the subjDim is not included in this list   
    desiredDimOrderSPSS(desiredDimOrderSPSS == subjDim) = [];
end

%Set default conditions delimeter
if (nargin < 5) || isempty(Con_delimeter)
    Con_delimeter = '_x_';
end

%Determine the level nr in each dimension for each condition
nCons = prod(dimSizes(desiredDimOrderSPSS));
dimLevPerCon = cell(nDims,nCons);
nDimCons = nDims-1;
nToDiv = nCons; %Initialize
for i_dim = 1:nDimCons
    
    %Find the required dimension and the number of levels in it
    dimTmp = desiredDimOrderSPSS(i_dim);                                    %Note that we implement the desired dimension order here
    nDimLev = dimSizes(dimTmp);
    
    %Create one smaller row with all dim levels in it
    dimNrPerCon_Small = nan(1,nToDiv);
    nRepsPerLev = nToDiv/nDimLev;
    counter = 0;
    for i_lev = 1:nDimLev
        dimNrPerCon_Small(1,counter+(1:nRepsPerLev)) = i_lev;
        counter = counter + nRepsPerLev;
    end
    
    %Repeat the smaller row such that all conditions are filled
    nDivs = nCons/nToDiv;
    dimLevPerCon(dimTmp,:) = num2cell(repmat(dimNrPerCon_Small,[1 nDivs]));
    
    %Adjust the number of divisions for the next dimension
    nToDiv = nRepsPerLev;
end
dimLevPerCon(subjDim,:) = {1:nSubj};

%Create the SPSS matrix and the condition names list
dataMatSPSS = nan(nSubj,nCons);
conNames = cell(nCons,1);
for i_con = 1:nCons
    %Data of this condition
    dataMatSPSS(:,i_con) = dataMatIn(dimLevPerCon{:,i_con});
    
    %Condition name
    tmpName = '';
    for i_dim = 1:nDimCons
        dimTmp = desiredDimOrderSPSS(i_dim);                                %Note that we take into account the desired dimension order here
        if i_dim ~= 1
            tmpName = [tmpName Con_delimeter];
        end
        tmpName = [tmpName DimNamesCell{dimTmp,1}{1,dimLevPerCon{dimTmp,i_con}}]; 
    end
    conNames{i_con,1} = tmpName;
end

%Create a table for output as CSV file
tableCSV = array2table(dataMatSPSS,'VariableNames',conNames,'RowNames',SubjNames);

% %Create index matrices from the input matrix (NOT USED ... but handy syntax for later?)
% dimVectors = cell(nDims,1);
% for i_dim = 1:nDims
%     dimVectors{i_dim,1} = 1:dimSizes(i_dim);
% end
% indexMatrices = cell(nDims,1);
% [indexMatrices{:}] = ndgrid(dimVectors{:});

end %[EoF]
