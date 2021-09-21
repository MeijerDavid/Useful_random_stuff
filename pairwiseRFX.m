function [median_sum_diffs,CI95_sum_diffs] = pairwiseRFX(LLs,refModelNr,nBootstrap,displayBool,colors)
%Perform a bootstrap fixed effects model comparison analysis and plot

%Find number of subjects and models
[nSubjects,nModels] = size(LLs);

%Set some defaults
if nargin < 2
    refModelNr = 1;
end
if nargin < 3
    nBootstrap = 10000;
end
if nargin < 4
    displayBool = 1;
end
if nargin < 5
    colors = [];
end

pxps2 = nan(nModels,nModels);
bors2 = nan(nModels,nModels);
for i=1:nModels
    for j=1:nModels
        [~,~,~,pxps2_tmp,bors2(i,j)] = spm_BMS(PSISLOOs(:,[i j]));          %Pairwise comparison shows that model 4 is better than 5 (pxps: 0.7328 vs. 0.2672)
        pxps2(i,j) = pxps2_tmp(1);
    end
end

%Plot the results
barWidth = 0.97;
figure(3); clf; hold on; box on;
for i=1:nModels             %i = x-axis
    for j=1:nModels         %j = y-axis
        xTemp_j = [i-barWidth/2 i-barWidth/2 i+barWidth/2];      %[L L R]
        yTemp_j = [j-barWidth/2 j+barWidth/2 j+barWidth/2];      %[B T T]
        xTemp_i = [i-barWidth/2 i+barWidth/2 i+barWidth/2];      %[L R R]
        yTemp_i = [j-barWidth/2 j-barWidth/2 j+barWidth/2];      %[B B T]
        
        if (bors2(i,j) < 0.5) && (pxps2(i,j) > pxps2(j,i))       %above chance (BF10 > 1)
            patch(xTemp_i,yTemp_i,1,'Parent',gca,'EdgeColor',colors(i,:),'LineStyle','-','Linewidth',1.5,'FaceColor',colors(i,:),'FaceAlpha',0.2);
            patch(xTemp_j,yTemp_j,1,'Parent',gca,'EdgeColor',colors(j,:),'LineStyle','-','Linewidth',1.5,'FaceColor',colors(j,:),'FaceAlpha',0.2);
        elseif i~=j
            edgeColor_i = interp1([0 1], [1 1 1; colors(i,:)], 0.1);
            edgeColor_j = interp1([0 1], [1 1 1; colors(i,:)], 0.1);
            patch(xTemp_i,yTemp_i,1,'Parent',gca,'EdgeColor',edgeColor_i,'LineStyle','-','Linewidth',0.5,'FaceColor',colors(i,:),'FaceAlpha',0.03);
            patch(xTemp_j,yTemp_j,1,'Parent',gca,'EdgeColor',edgeColor_j,'LineStyle','-','Linewidth',0.5,'FaceColor',colors(j,:),'FaceAlpha',0.03);
        end
    end
end
xlim([0.5,nModels+0.5]); ylim([0.5,nModels+0.5]); xlabel('model number'); ylabel('comparison model'); title('random effects pairwise comarisons: pxp > 0.5, bor < 0.5');
