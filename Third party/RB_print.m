function RB_print(fig,FigSize,fn,FontSize,MarkerSize,Resolution,LineWidth)
% RB_print - Print PNGs
%
% Usage:  RB_print(fig,FigSize,fn)
%         RB_print(fig,FigSize,fn,FontSize,MarkerSize,Resolution,LineWidth)
%
% Default settings:
%   FontSize = 8;
%   Resolution = '-r600';
%   LineWidth = 1;
%   MarkerSize = 4;

% AUTHOR: Robert Baumgartner

if not(exist('FontSize','var'))
  FontSize = 8;
end
if not(exist('MarkerSize','var'))
  MarkerSize = 4;
end
if not(exist('Resolution','var'))
  Resolution = '-r600';
end
if not(exist('LineWidth','var'))
  LineWidth = 1;
end

set(findall(fig,'-property','FontWeight'),'FontWeight','normal')
set(findall(fig,'-property','FontSize'),'FontSize',FontSize)
set(findall(fig,'-property','LineWidth'),'LineWidth',LineWidth)
set(findall(fig,'-property','MarkerSize'),'MarkerSize',MarkerSize)
set(fig,'PaperUnits','centimeters','PaperPosition',[0,0,FigSize])
% OuterPosition = get(gca,'OuterPosition');
% set(gca,'OuterPosition',OuterPosition+0.05*[1,0.5,-1,-0.5])
print(fig,Resolution,'-dpng',fn)

end