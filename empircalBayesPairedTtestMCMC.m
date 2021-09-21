function [ffx,rfx] = empircalBayesPairedTtestMCMC(param1,param2)
%Empirical Bayesian equivalent paired t-test to determine whether there is
%a significant difference at the group level between two fitted parameters 
%using MCMC samples (marginalised over all other parameters). 

[num_MCMC_samples,num_subjects] = size(param1);         %Input size (same for param2)

%Compute the paired differences between the parameters and normalize them per subject (i.e. use effect sizes) 
param_diff = param1-param2;               
param_diff = param_diff./std(param_diff);

%Determine a grid between the minimum and maximum parameter differences 
MIN = min(param_diff(:));
MAX = max(param_diff(:));
n = 2^14;
R=MAX-MIN; dx=R/(n-1); xmesh=MIN+[0:dx:R];  %Same as in kde1d.m

%Obtain the marginal posterior parameter distributions for each dataset (per subject)
marg_pos_density = nan(num_subjects,n);
for j=1:num_subjects
    [~,marg_pos_density(j,:)] = kde1d(param_diff(:,j),n,MIN,MAX);
end
marg_pos_prob = marg_pos_density*dx;
marg_pos_prob = dx/((num_MCMC_samples+1)*R) + (1-1/(num_MCMC_samples+1))*marg_pos_prob;  %Ensure non-zero everywhere (i.e. use a "lapse rate": one additional MCMC sample is randomly placed)

%Compute the mean param_diff per subject, and subsequently the group mean and standard deviation  
%These are parameter estimates for the t-distribution that describes the empirical belief about the mean of the parameter difference (i.e. fitted using method of moments)  
subj_mean_diff = sum(marg_pos_prob.*xmesh,2);     %subj_mean_diff = mean(param_diff); gives very similar results
group_mean_diff = mean(subj_mean_diff);
group_std_diff = std(subj_mean_diff);
dof = num_subjects-1; 

%The general t-distribution, parameterized as above, serves as a prior for the alternative hypothesis H1: allowing for a parameter difference. 
studentpdf = @(x,mu,sd,nu) exp(gammaln(nu/2 + 0.5) - gammaln(nu/2)) .* (nu.*pi.*sd.^2).^(-0.5) .* (1 + (1./(nu.*sd.^2)).*(x-mu).^2).^(-(nu+1)/2);
prior_H1 = studentpdf(xmesh,group_mean_diff,group_std_diff,dof)*dx;

%The null hypothesis assumes a point prior at 0.
[~,idx_zero] = min(abs(xmesh));
prior_H0 = zeros(1,n); prior_H0(idx_zero) = 1;

%Compute the marginal log-likelihood of the data under each hypothesis (per subject)
LLs = nan(2,num_subjects);
for j=1:num_subjects
    LLs(1,j) = log(trapz(marg_pos_prob(j,:).*prior_H0))+log(dx);            
    LLs(2,j) = log(trapz(marg_pos_prob(j,:).*prior_H1))+log(dx);            %Integrate out the unknown 'param_diff' (effect size)
end

%Perform a fixed effects analysis of the results: compute a group-level Bayes factor   
ffx.LLs_H0 = LLs(1,:);
ffx.LLs_H1 = LLs(2,:);
ffx.BF01 = exp(sum(LLs(1,:))-sum(LLs(2,:)));    %evidence in favour of null
ffx.BF10 = exp(sum(LLs(2,:))-sum(LLs(1,:)));    %1/ffx.BF01;

%Add spm to path
addpath('E:\Matlab Toolboxes\spm12');

%Perform a random effects analysis of the results: compute the protected exceedance probability (pxp)  
rfx.LLs = LLs';
[rfx.alpha,rfx.exp_r,rfx.xp,rfx.pxp,rfx.bor] = spm_BMS(LLs');

end %[EoF]
