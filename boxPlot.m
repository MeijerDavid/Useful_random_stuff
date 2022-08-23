function [hl,hp] = boxPlot(data,centrePos,barWidth,lineWidth,lineColor,faceAlpha,horizontalBool)
%Plot a box plot in the current axes

if nargin < 4 || isempty(lineWidth)
    lineWidth = 1;
end
if nargin < 5 || isempty(lineColor)
    lineColor = [0 0 0];
end
if nargin < 6 || isempty(faceAlpha)
    faceAlpha = 0.2;
end
if nargin < 7 || isempty(horizontalBool)
    horizontalBool = false;
end

%Get coordinates
y = [min(data), quantile(data,[.25 .50 .75]), max(data)];
x = [-.5 0 .5]*barWidth + centrePos;

%Start drawing (function assumes that figure is already open and the correct axes is selected)   
hold on;

%Vertical boxplot (default)
if ~horizontalBool
    
    hp = patch(x([1 1 3 3]),y([2 4 4 2]),lineColor,'facealpha',faceAlpha,'edgecolor','none');
    
    hl = plot(x([1 3]),y([1 1]),'-','LineWidth',lineWidth,'Color',lineColor);    %Min
    plot(x([1 3]),y([2 2]),'-','LineWidth',lineWidth,'Color',lineColor);    %0.25 quantile
    plot(x([1 3]),y([3 3]),'-','LineWidth',lineWidth,'Color',lineColor);    %Median
    plot(x([1 3]),y([4 4]),'-','LineWidth',lineWidth,'Color',lineColor);    %0.75 quantile
    plot(x([1 3]),y([5 5]),'-','LineWidth',lineWidth,'Color',lineColor);    %Max
    
    plot(x([2 2]),y([1 2]),'-','LineWidth',lineWidth,'Color',lineColor);    
    plot(x([1 1]),y([2 4]),'-','LineWidth',lineWidth,'Color',lineColor);    
    plot(x([3 3]),y([2 4]),'-','LineWidth',lineWidth,'Color',lineColor);    
    plot(x([2 2]),y([4 5]),'-','LineWidth',lineWidth,'Color',lineColor);    
    
%horizontal boxplot    
else
    
    hp = patch(y([2 4 4 2]),x([1 1 3 3]),lineColor,'facealpha',faceAlpha,'edgecolor','none');
    
    hl = plot(y([1 1]),x([1 3]),'-','LineWidth',lineWidth,'Color',lineColor);    %Min
    plot(y([2 2]),x([1 3]),'-','LineWidth',lineWidth,'Color',lineColor);    %0.25 quantile
    plot(y([3 3]),x([1 3]),'-','LineWidth',lineWidth,'Color',lineColor);    %Median
    plot(y([4 4]),x([1 3]),'-','LineWidth',lineWidth,'Color',lineColor);    %0.75 quantile
    plot(y([5 5]),x([1 3]),'-','LineWidth',lineWidth,'Color',lineColor);    %Max
    
    plot(y([1 2]),x([2 2]),'-','LineWidth',lineWidth,'Color',lineColor);    
    plot(y([2 4]),x([1 1]),'-','LineWidth',lineWidth,'Color',lineColor);    
    plot(y([2 4]),x([3 3]),'-','LineWidth',lineWidth,'Color',lineColor);    
    plot(y([4 5]),x([2 2]),'-','LineWidth',lineWidth,'Color',lineColor);    
end

end %[EoF]
