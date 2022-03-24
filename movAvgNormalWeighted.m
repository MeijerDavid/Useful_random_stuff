function [avg,SD] = movAvgNormalWeighted(x,y,sd,plot_flag)
%For data points y on irregular grid x (both vectors), implement a moving
%average filter where the values are weighted by a moving Gaussian with one
%fixed standard deviation (sd = scalar). 
%Optionally, also compute the weighted SD (2nd output argument) and plot 
%the results (set "plot_flag" to true). 

if nargin < 4; plot_flag = false; end           %Set default for optional input

weights = normpdf(x(:),x(:)',sd);               %2D (use implicit expansion) 
weights = weights./sum(weights,1);              %normalize over first dimension

avg = reshape(sum(weights.*y(:),1),size(y));    %compute weighted averages

if (nargout <= 1) && ~plot_flag
    return;                                     %Return if SD was not requested
end
                                                
SD = reshape(sqrt(sum(weights.*(y(:)-avg(:)).^2,1)),size(y)); %compute weighted SD

if ~plot_flag; return; end                      %Return if plots were not requested

%Plot the results
figure; hold on;
plot(x,y,'ko-','MarkerSize',3);

SD_high = avg(:)'+SD(:)';
SD_low = avg(:)'-SD(:)';

boundedLine_DM(x,[SD_high; avg; SD_low],[1 0 0]); %See helper function below

end %[EoF]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Helper function for plotting %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [hl,hp] = boundedLine_DM(x,y,color)
%Simple adaptation of boundedline function from:
%https://github.com/kakearney/boundedline-pkg
    
if numel(x) == 1    %special case
    hp = plot([x x],y([1 3]),'-','Linewidth',1.5,'Color',[color 0.2]);
    hl = plot(x,y(2,:),'.','Color',color,'MarkerSize',10);
else                %default behavior
    x2 = [x fliplr(x)];
    y2 = [y(1,:) fliplr(y(3,:))];
    hp = patch(x2,y2,color,'facealpha', 0.2, 'edgecolor', 'none');
    hl = plot(x,y(2,:),'-','Color',color,'Linewidth',1.5);
end

end %[EoF]

%%%%%%%%%%%%%%%%% 
% Tester code %%%
%%%%%%%%%%%%%%%%%
% 
% %Create an irregular grid
% num_samples = 100;
% x = sort(rand(1,num_samples)*2*pi);
% 
% % Sample a sine wave with varying noise
% noise_sd = (cos(x)+1)/2;
% y = sin(x) + noise_sd.*randn(1,num_samples);
% 
% % Determine the width of the moving gaussian window
% width_factor = 3;
% sd = width_factor*std(diff(x));
% 
% % Apply the Gaussian weighted moving average
% [avg,SD] = movAvgNormalWeighted(x,y,sd,true);
% xlim([0 2*pi]); title('Sine wave plus random noise with a moved cosine amplitude envelope'); 
