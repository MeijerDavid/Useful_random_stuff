function Vq = interp1NormalWeighted(X,V,Xq,sd,plot_flag)
%For data points X,V (both vectors), implement a moving average filter 
%where the values are weighted by a moving Normal distribution with one
%fixed standard deviation (sd = scalar) centered at the queried points Xq. 
%N.B. At indices where isnan(x), output "Vq" will contain NaNs. 
%Values in V are simply ignored at indices where isnan(x) OR isnan(V).

if nargin < 5; plot_flag = false; end               %Set default for optional input

if all(isnan(V)); Vq = nan(size(Xq)); return; end   %Special case if V only NaNs

weights = normpdf(X(:),Xq(:)',sd);                  %2D (use implicit expansion) 
weights(isnan(V(:)),:) = NaN;                       %Ensure proper normalization 
weights = weights./nansum(weights,1);               %normalize over first dimension

Vq = reshape(nansum(weights.*V(:),1),size(Xq));     %compute weighted averages
Vq(isnan(Xq)) = NaN;                                %Correct zero to NaN (nansum(NaN)-->0)

if ~plot_flag
    return;                                         %Return if plot was not requested
end
                                                
%Plot the results
figure; hold on;
plot(X(:),V(:),'bo','MarkerSize',3);
plot(Xq(:),Vq(:),'k-');

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
% Vq = interp1NormalWeighted(X,V,Xq,sd,true)
% xlim([0 2*pi]); title('Sine wave plus random noise with a moved cosine amplitude envelope'); 
