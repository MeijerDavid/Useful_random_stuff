function [ffx,rfx] = empircalBayesTtestMCMC(param1,param2)
%Empirical Bayesian equivalent two-sample t-test to determine whether there
%is significant difference at the group level between two fitted parameters 
%using MCMC samples (marginalised over all other parameters). 

assert(isequal(size(param1),size(param2)),'Matrix size of param1 and param2 must be equal');
[num_MCMC_samples,num_subjects] = size(param1);         %Input size (same for param2)

%Concatenate the parameters to form a collection of params under H0
param0 = [param1; param2];

%Determine a grid between the minimum and maximum parameter differences 
MIN = min(param0(:));
MAX = max(param0(:));
n = 2^14; R=MAX-MIN; dx=R/(n-1); 
xmesh=MIN+(0:dx:R);  %Same as in kde1d.m

%Obtain the marginal posterior kernel density estimates for each parameter set (per subject)
marg_pos_density_0 = nan(num_subjects,n);
marg_pos_density_1 = nan(num_subjects,n);
marg_pos_density_2 = nan(num_subjects,n);
for j=1:num_subjects
    [~,marg_pos_density_0(j,:)] = kde1d(param0(:,j),n,MIN,MAX);
    [~,marg_pos_density_1(j,:)] = kde1d(param1(:,j),n,MIN,MAX);
    [~,marg_pos_density_2(j,:)] = kde1d(param2(:,j),n,MIN,MAX);
end

%Convert the KDEs to probability distributions (n.b. ensure non-zero everywhere: use a "lapse rate" --> one additional MCMC sample is randomly placed)
comp_marg_pos_prob = @(kde) dx/((num_MCMC_samples+1)*R) + (1-1/(num_MCMC_samples+1))*kde*dx;
marg_pos_prob_0 = comp_marg_pos_prob(marg_pos_density_0);
marg_pos_prob_1 = comp_marg_pos_prob(marg_pos_density_1);
marg_pos_prob_2 = comp_marg_pos_prob(marg_pos_density_2);

    %Declare a nested function that we can use to compute empirical Bayesian priors (t-distributions) 
    function prior = compEmpBayesPrior(marg_pos_prob)
        
        %Compute the mean param per subject and subsequently the group mean and standard deviation  
        %These are parameter estimates for the t-distribution that describes the empirical belief about the mean of the parameters (i.e. fitted using method of moments)  
        subj_mean = sum(marg_pos_prob.*xmesh,2);     
        group_mean = mean(subj_mean);
        group_std = std(subj_mean);
        dof = num_subjects-1; 

        %The general t-distribution serves as a group-level prior 
        studentpdf = @(x,mu,sd,nu) exp(gammaln(nu/2 + 0.5) - gammaln(nu/2)) .* (nu.*pi.*sd.^2).^(-0.5) .* (1 + (1./(nu.*sd.^2)).*(x-mu).^2).^(-(nu+1)/2);
        prior = studentpdf(xmesh,group_mean,group_std,dof)*dx;
    end

%Compute the prior distributions
prior_0 = compEmpBayesPrior(marg_pos_prob_0);
prior_1 = compEmpBayesPrior(marg_pos_prob_1);
prior_2 = compEmpBayesPrior(marg_pos_prob_2);

%Compute the marginal log-likelihood of the data under each hypothesis (per subject)
LLs = nan(2,num_subjects);
for j=1:num_subjects
    LLs(1,j) = log(trapz(marg_pos_prob_1(j,:).*marg_pos_prob_2(j,:).*prior_0));                             %H0 
    LLs(2,j) = log(trapz(marg_pos_prob_1(j,:).*prior_1))+log(trapz(marg_pos_prob_2(j,:).*prior_2));         %H1    
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
