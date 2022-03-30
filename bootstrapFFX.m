function [median_sum_diffs,CI95_sum_diffs] = bootstrapFFX(lme,refModelNr,nBootstrap,displayBool,colors)
%Perform a bootstrap fixed effects model comparison analysis and plot

%Find number of subjects and models
[nSubjects,nModels] = size(lme);

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

%Bootstrap the mean differences
rng('shuffle');
diffWithRef = lme-repmat(lme(:,refModelNr),[1 nModels]);                    %Subtract the lme of the reference model from all other models
bootstrap_sum_diffs = nan(nBootstrap,nModels);
for b=1:nBootstrap
    idxB = randsample(nSubjects,nSubjects,true);                            %Pick at random nSubjects subjIDs (with replacement) 
    bootstrap_sum_diffs(b,:) = sum(diffWithRef(idxB,:),1);                  %Sum the differences (fixed effects analysis)
end
median_sum_diffs = median(bootstrap_sum_diffs,1);                           %Compute the median
CI95_sum_diffs = prctile(bootstrap_sum_diffs,[2.5;97.5],1);                 %Compute the 95% confidence interval

%Plot the results?
if displayBool
    if isempty(colors)
        colors = hsv(nModels);                          %Take some colors from the HSV colormap
        %colormap(colors); figure; colorbar()           %--> Take a quick look at the colors
    end
    
    %Plot the results
    barWidth = 0.85;
    figure; clf; hold on; box on;
    %Plot reference model as thick line
    plot([0.5 nModels+0.5],[0 0],'-','linewidth',3,'Color',colors(1,:));
    for i=1:nModels
        %Plot CI as a bar
        xTemp = [i-barWidth/2 i-barWidth/2 i+barWidth/2 i+barWidth/2];                                  %[L L R R]
        yTemp = [CI95_sum_diffs(1,i) CI95_sum_diffs(2,i) CI95_sum_diffs(2,i) CI95_sum_diffs(1,i)];      %[B T T B]
        patch(xTemp,yTemp,1,'Parent',gca,'EdgeColor',colors(i,:),'LineStyle','-','Linewidth',1.5,'FaceColor',colors(i,:),'FaceAlpha',0.2); 

        %Add median as a colored line
        plot([i-barWidth/2 i+barWidth/2],[median_sum_diffs(i) median_sum_diffs(i)],'-','linewidth',1.5,'Color',colors(i,:));
    end
    xlim([0.5 nModels+0.5]); title('Boostrapped fixed effects analysis (median and 95% CI)'); xlabel('model nr'); ylabel(['sum(lme-lme(ref model ' num2str(refModelNr) '))']); xticks(1:nModels);
end

end %[EoF]
