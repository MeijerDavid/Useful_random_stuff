function [hl,hp] = boxPlot(data,centrePos,barWidth,barColor,barAlpha,lineColor,lineStyle,lineWidth,horizontalBool)
%Plot a box plot in the current axes

if nargin < 4 || isempty(barColor)
    barColor = [0 0 0];
end
if nargin < 5 || isempty(barAlpha)
    barAlpha = 0.2;
end
if nargin < 6 || isempty(lineColor)
    lineColor = [0 0 0];
end
if nargin < 7 || isempty(lineStyle)
    lineStyle = '-';
end
if nargin < 8 || isempty(lineWidth)
    lineWidth = 1;
end
if nargin < 9 || isempty(horizontalBool)
    horizontalBool = false;
end

%Get coordinates
y = [min(data), quantile(data,[.25 .50 .75]), max(data)];
x = [-.5 0 .5]*barWidth + centrePos;

%Start drawing (function assumes that figure is already open and the correct axes is selected)   
hold on;

%Vertical boxplot (default)
if ~horizontalBool
    
    hp = patch(x([1 1 3 3]),y([2 4 4 2]),barColor,'facealpha',barAlpha,'edgecolor','none');
    
    %Horizontal lines
    hl = plot(x([1 3]),y([1 1]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);     %Min
    plot(x([1 3]),y([2 2]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);          %0.25 quantile
    plot(x([1 3]),y([3 3]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);          %Median
    plot(x([1 3]),y([4 4]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);          %0.75 quantile
    plot(x([1 3]),y([5 5]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);          %Max
    
    %Vertical lines
    plot(x([2 2]),y([1 2]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);          %Top 
    plot(x([1 1]),y([2 4]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);          %Left bar edge 
    plot(x([3 3]),y([2 4]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);          %Right bar edge  
    plot(x([2 2]),y([4 5]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);          %Bottom
    
%horizontal boxplot    
else
    
    hp = patch(y([2 4 4 2]),x([1 1 3 3]),barColor,'facealpha',barAlpha,'edgecolor','none');
    
    hl = plot(y([1 1]),x([1 3]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);     %Min
    plot(y([2 2]),x([1 3]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);          %0.25 quantile
    plot(y([3 3]),x([1 3]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);          %Median
    plot(y([4 4]),x([1 3]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);          %0.75 quantile
    plot(y([5 5]),x([1 3]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);          %Max
    
    plot(y([1 2]),x([2 2]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);          %Left
    plot(y([2 4]),x([1 1]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);          %Bottom bar edge
    plot(y([2 4]),x([3 3]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);          %Top bar edge
    plot(y([4 5]),x([2 2]),lineStyle,'LineWidth',lineWidth,'Color',lineColor);          %Right
end

end %[EoF]
