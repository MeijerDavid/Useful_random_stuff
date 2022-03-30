function [bms,bms_fac] = bms_Acerbi(lme,factors,alpha0)
% Bayesian model selection using Luigi Acerbi's code
%
% This function assumes that Luigi Acerbi's "Robust Bayesian Model 
% Selection" (rbms) toolbox has been added to the Matlab path.
%
% INPUT:
% - lme = matrix of (cross-validated) log-likelihoods of size: Ns x Nk
%   (number of subjects x number of models). 
% - factors (optional) = cell array of length 1 x Nf (number of factors). 
%   For each factor (i.e. cell) a logical matrix of size Nfc x Nk defines
%   whether each model contains a certain model factor component (fc). 
%   If no factors are given, regular BMS is performed.
% - alpha0 = vector of size 1 x Nk that specifies the Dirichlet prior over
%   model frequencies. Default for no factors = ones(1,Nk). Default for
%   factorial analysis = ones(1,Nk) * (average number of factor components
%   divided by total number of models) 

%Set defaults
[Ns,Nk] = size(lme);
if nargin < 2 %no factors present
    factors = cell(0,0);
    alpha0 = ones(1,Nk);                                                    % how often 
elseif nargin < 3 %factors present but no alpha0 specified
    avg_Nfc = mean(cellfun(@(x)size(x,1),factors));                         % average number of factor components   
    alpha0 = avg_Nfc*ones(1,Nk)/Nk;                                         % alpha0 as defined in Acerbi et al., 2018 PLoS Comp. Biology  
end                                                                         % this attempts to ensure that the prior alpha per model component is approximately 1 (summed over models belonging to that component)
Nf = length(factors);   % Number of factors (to compare)
nsamples = 1e6;         % Samples used to compute the exceedance probabilities
bmshyper = 0;           % BMS hyperprior (Default = 0: standard BMS with fixed alpha0 as in spm_BMS :: Set to 1 if you wish to use a Nemenman-Shafee-Bialek hyperprior, see rbms_logprior)

%Initialize output
bms = [];
bms.lme = lme;
bms.alpha0 = alpha0;
bms.alpha = nan(1,Nk);
bms.exp_r = nan(1,Nk);
bms.xp = nan(1,Nk);
bms.pxp = nan(1,Nk);
bms.bor = nan;
bms.g = nan(Ns,Nk);
bms_fac = cell(size(factors));

%Keep only models with nonzero priors
i_nonZeroModels = alpha0 > 0;
lme = lme(:,i_nonZeroModels);
alpha0 = alpha0(i_nonZeroModels);
for i=1:Nf
    factors{i} = factors{i}(:,i_nonZeroModels); 
end

%Set model prior weights
if bmshyper == 0
    w_k = alpha0;
else
    w_k = alpha0./mean(alpha0);     %Ensure mean of weights = 1 (i.e. sum of weights is Nk)
end

%Perform standard Bayesian model selection (using variational bayesian method for fast approximation)    
[exp_r,xp,pxp,output] = rbms(lme,'PriorWeights',w_k,'HyperPrior',bmshyper);
bms.alpha(i_nonZeroModels) = output.alpha; 
bms.exp_r(i_nonZeroModels) = exp_r;
bms.xp(i_nonZeroModels) = xp;
bms.pxp(i_nonZeroModels) = pxp;
bms.bor = output.bor;
bms.g(:,i_nonZeroModels) = output.g;                                        %Matrix of individual posterior probabilities

%Perform BMS on factor comparisons
for i=1:Nf
    
    fac = [];                   %Initialize
    factorsTmp = factors{i};
    Nfc = size(factorsTmp,1);   %Number of factor components for this factor

    % Sum alpha levels across factor component models
    alpha_fac = sum(bsxfun(@times, bms.alpha, factorsTmp),2)';              %Sum alphas of models per factor component
    alpha0_fac = sum(bsxfun(@times, bms.alpha0, factorsTmp),2)';             
    alpha_fac = max(alpha_fac, sqrt(eps));                                  %Ensure alphas are not zero..
    alpha0_fac = max(alpha0_fac, sqrt(eps));
    
    %Set factor component prior weights
    if bmshyper == 0
        w_fac = alpha0_fac;
    else
        w_fac = alpha0_fac/mean(alpha0_fac);                                %Ensure mean of weights = 1 (i.e. sum of weights is Nk)
    end
    
    % Normalize factorsTmp                                                  
    factorsTmp_norm = bsxfun(@rdivide, factorsTmp, sum(factorsTmp,1));      %In case one model contributes to multiple factor components..
                                                                            %I.e. ensure that the sum across factors == 1 for each model      
    % Compute posterior and likelihood summed over factor components
    g_fac = zeros(Ns, Nfc);
    lme_fac = zeros(Ns, Nfc);
    for f = 1:Nfc
        g_fac(:,f) = sum(bsxfun(@times, bms.g, factorsTmp_norm(f,:)),2);    %Sum across models per factor component  
        idx = logical(factorsTmp_norm(f,:));
        maxlme = max(lme(:,idx),[],2);
        if isempty(maxlme); maxlme = 0; end                                 %Be careful with lme because it's log transformed...
        lme_fac(:,f) = log(sum(bsxfun(@times,exp(bsxfun(@minus,lme(:,idx),maxlme)),factorsTmp_norm(f,idx)/sum(factorsTmp_norm(f,idx),2)),2)) + maxlme;  %Average across models per factor component
    end
    lme_fac(isinf(lme_fac)) = -(1/sqrt(eps));                               %Avoid -inf (use -veryMuch instead)
    
    % Different methods to assess Bayes Omnibus Risk for factorsTmp

    % Method 1: Compute correct ELBO for variational factorial model                        %Works only with orthogonal factorsTmp
    facs = bsxfun(@rdivide,factorsTmp,sum(factorsTmp,2))/size(factorsTmp,1)*sum(w_k);
    [~,~,~,~,F0] = rbms_fvb(lme,facs,0,1,1);                                                %Compute free energy of null: log(p(m|H0)) for this factor (i.e. taking into account the component structure for this factor)
    F1 = rbms_FE(lme,bms.alpha,bms.g,w_k,0);                                                %Compute free energy of data: log(p(m|H1)). Note that this does not depend on the factor / component structure
    bor1 = 1/(1+exp(F1-F0));

    % Method 2: Use current variational solution, approximate factorial ELBO
    [fac.xp,bor2] = rbms_exceedance(alpha_fac,lme_fac,g_fac,nsamples,w_fac,bmshyper);       %Exceedance probability is computed based on alpha_fac only 
    % Compute moments                                                                       %Note that we don't normally use bor2, for which we needed lme_fac and g_fac (only when factor components are not orthogonal)     
    [fac.exp_r,fac.cov_r] = rbms_rmom(alpha_fac,output.qlnalpha0);

    % Method 3: Recompute variational solution                                              %Commented out by Luigi Acerbi              
    % priorw_fac = sum(w_k)/size(factorsTmp,1)*ones(1,size(factorsTmp,1));
    % [fac.exp_r,fac.xp,~,output] = rbms(lme_fac,'Method','vb','Nsamp',nsamples,'PriorWeights',priorw_fac,'HyperPrior',0);
    % fac.cov_r = output.cov_r;
    % bor3 = output.bor;

    % Assign Bayes Omnibus Risk
    if any(sum(factorsTmp > 0,1) > 1)
        fac.bor = bor2; % Non-orthogonal, use approximation                                 %When one model is part of two 'opposing' factor components
    else
        fac.bor = bor1; % Orthogonal, use correct ELBO
    end

    % Compute protected exceedance probabilities for model factorsTmp
    fac.pxp = fac.xp*(1 - fac.bor) + fac.bor/Nfc;
    % ww = sum(bsxfun(@rdivide, factorsTmp, sum(factorsTmp,1)),2)';                         %Alternative? Commented out by Luigi Acerbi    
    % fac.pxp = fac.xp*(1 - fac.bor) + fac.bor/Nk .* ww;

    %Save this factor comparison
    bms_fac{i} = fac;
end

end %[EoF]
