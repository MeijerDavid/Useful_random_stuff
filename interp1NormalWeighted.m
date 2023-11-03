function [Vq,SE] = interp1NormalWeighted(X,V,Xq,sd,plot_flag)
%For data points X,V (both vectors), implement a moving average filter 
%where the values are weighted by a moving Normal distribution with one
%fixed standard deviation (sd = scalar) centered at the queried points Xq. 
%N.B. At indices where isnan(x), output "Vq" will contain NaNs. 
%Values in V are simply ignored at indices where isnan(x) OR isnan(V).
%Optionally, also compute standard errors for interpolated estimates Vq.

if nargin < 5; plot_flag = false; end               %Set default for optional input

if all(isnan(V)); Vq = nan(size(Xq)); return; end   %Special case if V only NaNs

weights = normpdf(X(:),Xq(:)',sd);                  %2D (use implicit expansion) 
weights(isnan(V(:)),:) = NaN;                       %Ensure proper normalization 
weights = weights./nansum(weights,1);               %normalize over first dimension

Vq = reshape(nansum(weights.*V(:),1),size(Xq));     %compute weighted averages
Vq(isnan(Xq)) = NaN;                                %Correct zero to NaN (nansum(NaN)-->0)

%Compute the standard error of the estimate if requested
if nargout >= 2 
    
    variance = nansum(weights.*(V(:)-Vq(:)').^2,1); %compute weighted variances
    variance(isnan(Xq)) = NaN;                      %Correct zero to NaN (nansum(NaN)-->0)
    
    % Following: http://seismo.berkeley.edu/~kirchner/Toolkits/Toolkit_12.pdf
    % See also: http://www.analyticalgroup.com/download/WEIGHTED_MEAN.pdf
    
    % Compute the effective sample sizes
    n_eff = 1 ./ nansum(weights.^2,1);                          %Eq. 4
    
    % Apply Bessel's correction to the variance estimates
    variance_corrected = variance .* n_eff ./ (n_eff-1);        %Eq. 5
    
    % Compute the standard error of the mean
    SE = reshape(sqrt(variance_corrected ./ n_eff),size(Xq));   %Eq. 6    
end
    
%Plot the results
if plot_flag
    figure; hold on; box on;
    plot(X(:),V(:),'bo','MarkerSize',3);
    if nargout <= 1 
        plot(Xq(:),Vq(:),'r-');
    elseif nargout >= 2
        x_row = Xq(:)';
        SE_high = Vq(:)'+SE(:)';
        Vq_row = Vq(:)';
        SE_low = Vq(:)'-SE(:)';
        boundedLine_DM(x_row(~isnan(Xq)),[SE_high(~isnan(Xq)); Vq_row(~isnan(Xq)); SE_low(~isnan(Xq))],[1 0 0]); %See helper function below
    end
end

end %[EoF]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Helper function for plotting %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [hl,hp] = boundedLine_DM(x,y,color)
%Simple adaptation of boundedline function from:
%https://github.com/kakearney/boundedline-pkg
%Ensure that x is a row vector, and y has size [3 x length(x)]
    
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
% X = sort(rand(1,num_samples)*2*pi);
% Xq = sort(rand(1,num_samples)*2*pi);
% 
% % Sample a sine wave with varying noise
% noise_sd = (cos(X)+1)/2;
% V = sin(X) + noise_sd.*randn(1,num_samples);
% 
% % Determine the width of the moving gaussian window
% width_factor = 3;
% sd = width_factor*std(diff(X));
% 
% %Add some NaNs at random indices
% num_NaNs_X = 3;
% X(randperm(num_samples,num_NaNs_X)) = NaN;
% num_NaNs_V = 5;
% V(randperm(num_samples,num_NaNs_V)) = NaN;
% 
% % Apply the Gaussian weighted moving average
% [Vq,SE] = interp1NormalWeighted(X,V,Xq,sd,true)
% xlim([0 2*pi]); title('Sine wave plus random noise with a moved cosine amplitude envelope'); 
