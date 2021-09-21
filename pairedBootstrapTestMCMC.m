function p_value = pairedBootstrapTestMCMC(param1,param2,num_bootstrap)
%One sided bootstrap test for a difference in the mean of two parameters: 
%"param1-param2 > 0"? This test takes parameter variance into account both 
%within (from MCMC posterior) and between subjects.

[num_MCMC_samples,num_subjects] = size(param1);

%Compute the paired differences between the parameters
param_diff = param1-param2;               

%Bootstrap the group-means of the differences
mean_group_diffs = nan(num_bootstrap,1);
for i=1:num_bootstrap
    idx_subj = randsample(num_subjects,num_subjects,true);                  
    idx_mcmc = randsample(num_MCMC_samples,num_subjects,true);            
    idx_combined = sub2ind([num_MCMC_samples,num_subjects],idx_mcmc,idx_subj);    
    mean_group_diffs(i) = mean(param_diff(idx_combined));                
end

%Compute the one-sided p_value against zero
p_value = sum(mean_group_diffs <= 0)/num_bootstrap;                   

end %[EoF]
