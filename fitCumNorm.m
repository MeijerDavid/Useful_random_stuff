function [FittedParams,LL,exitflag] = fitCumNorm(StimLevels,NumPos,OutOfNum,beta_flag,num_fits,num_grid,paramIDmatrix,fixedParams)
% Fit a cumulative normal using the (beta-)binomial model and maximum
% likelihood estimation via fminsearch (Nelder-Mead optimization). 
%
% FittedParams column order is:
% - 1st parameter is mean of normal (PSE: Point of Subjective Equality)
% - 2nd parameter is SD of normal (JND: Just Noticeable Difference)
% - 3rd parameter is lapse rate (fraction of trials with a random response)
% - 4th parameter is eta (variance scaling factor of beta distribution)
%
% Optionally, you can add multiple conditions as multiple rows.
% Use "paramIDmatrix" to share parameters across conditions.
% "fixedParams" must be a vector whose indices correspond to the IDs in 
% paramIDmatrix. Any non-NaN value will serve as a fixed parameter value
% (e.g. indicating that parameter ID [at this index] will not be fitted).
%
% David Meijer, 23-03-2022

% Ensure same size for all crucial input arguments
if ~isequal(size(StimLevels),size(NumPos)) || ~isequal(size(StimLevels),size(OutOfNum))
    error('StimLevels, NumPos, and OutOfNum must be the same size: [num_conds x num_StimLevels]');
end
if (size(StimLevels,2) == 1) && ~(size(StimLevels,1) == 1) 
    StimLevels = StimLevels'; NumPos = NumPos'; OutOfNum = OutOfNum';
    warning('Input vectors StimLevels, NumPos, and OutOfNum were transposed');
end
num_conds = size(StimLevels,1);

% Set default values for some other input arguments
if (nargin < 4) || isempty(beta_flag)
    beta_flag = false;  %Set beta_flag to true to fit betabinomial model
end                     %See https://doi.org/10.1016/j.visres.2016.02.002    
if nargin < 5 || isempty(num_fits)
    num_fits = 10;      %Default number of fits (from which we choose best)
end
if nargin < 6 || isempty(num_grid)
    num_grid = 1000;    %Default number of samples for random "grid" search
end

% Determine the number of parameters per condition
if beta_flag
     num_params_per_cond = 4;
else
     num_params_per_cond = 3;
end

% Determine a one-to-one coding of parameters in a vector to those in a matrix for all conditions (allows sharing of params across conditions)   
if nargin < 7
    paramIDmatrix = reshape(1:(num_conds*num_params_per_cond),[num_params_per_cond num_conds])';    %No sharing by default (in case of sharing params in this matrix need to have the same ID)
else
    assert(isequal([num_conds num_params_per_cond],size(paramIDmatrix)),'Error: paramIDmatrix does not have the correct size [num_conds x num_params_per_cond]');
    assert(isequal(unique(paramIDmatrix)',1:max(paramIDmatrix,[],'all')),'Error: paramIDmatrix should contain all integers from 1 to number of unique parameters (incl. fixed and fitted)');
end

% Find the parameter types of all parameters
num_paramsTotal = max(paramIDmatrix,[],'all');
types_paramsTotal = nan(1,num_paramsTotal);
for i=1:num_paramsTotal
    idx_of_paramID = find(paramIDmatrix == i);
    param_type = ceil(idx_of_paramID/num_conds);                            %1=PSE, 2=JND, 3=LapseR, 4=Eta
    assert(numel(unique(param_type))==1,'Error: the parameter type is not the same for all parameters with the same ID (ensure that equal numbers appear only in one column of paramIDmatrix)');
    types_paramsTotal(i) = param_type(1);
end

% Find the fixed parameters
if nargin < 8
    fixedParams = nan(1,num_paramsTotal); %None of the parameters are fixed
else
    assert(isvector(fixedParams) && (length(fixedParams) == num_paramsTotal),'Error: fixedParams must be a vector of length equal to the number of unique parameters (incl. fixed and fitted)');
end

% Find some information about the parameters 2 fit
idx_params2fit = find(isnan(fixedParams));
num_params2fit = numel(idx_params2fit);
if num_params2fit == 0
    FittedParams = fixedParams(paramIDmatrix);
    LL = NaN;
    exitflag = NaN;
    warning('User requested to fit NO parameters. Only fixed parameter are returned.');
    return 
end
types_params2fit = types_paramsTotal(idx_params2fit);

% Define helper functions for parameter transformation
logit = @(p) log(p./(1-p));
logistic = @(x) 1./(1 + exp(-x));

% Transform the fixed parameters to log/logit space
idx_paramsFixed = find(~isnan(fixedParams));
for i=1:length(idx_paramsFixed)
    param_type = types_paramsTotal(idx_paramsFixed(i));                     %1=PSE, 2=JND, 3=LapseR, 4=Eta
    if param_type == 2
        fixedParams(idx_paramsFixed(i)) = log(fixedParams(idx_paramsFixed(i)));
    elseif (param_type == 3) || (param_type == 4)
        fixedParams(idx_paramsFixed(i)) = logit(fixedParams(idx_paramsFixed(i)));
    end
end

% Define hard and plausible boundaries on the parameters [HLB PLB PUB HUB]
% Also transform the bounds to log/logit space for fitting
range = max(StimLevels,[],2)-min(StimLevels,[],2);
PSE_bounds = range .* [0 .25 .75 1] + min(StimLevels,[],2);
JND_bounds = log(range .* [1e-9 .1 .5 10]);
Gamma_bounds = repmat(logit([1e-9 1e-3 0.1 1-1e-9]),[num_conds 1]);
Eta_bounds = repmat(logit([1e-9 1e-3 0.25 1-1e-9]),[num_conds 1]);

HLB = [PSE_bounds(:,1),JND_bounds(:,1),Gamma_bounds(:,1),Eta_bounds(:,1)];
PLB = [PSE_bounds(:,2),JND_bounds(:,2),Gamma_bounds(:,2),Eta_bounds(:,2)];
PUB = [PSE_bounds(:,3),JND_bounds(:,3),Gamma_bounds(:,3),Eta_bounds(:,3)];
HUB = [PSE_bounds(:,4),JND_bounds(:,4),Gamma_bounds(:,4),Eta_bounds(:,4)];

if ~beta_flag
    HLB(:,4)=[]; PLB(:,4)=[]; PUB(:,4)=[]; HUB(:,4)=[]; 
end

% Randomly sample a grid from within the plausible bounds
params_grid = (PUB(types_params2fit)-PLB(types_params2fit)).*rand(num_grid,num_params2fit)+PLB(types_params2fit);

% Perform a grid search and sort the results according to highest LL
LL_grid = nan(num_grid,1);
for i=1:num_grid   
    LL_grid(i,1) = ComputeLL(params_grid(i,:),StimLevels,NumPos,OutOfNum,HLB(types_params2fit),HUB(types_params2fit),beta_flag,paramIDmatrix,fixedParams,idx_params2fit,logistic); %see helper function below
end
[~,idx_sorted] = sort(LL_grid,'descend');
params_grid = params_grid(idx_sorted,:);

% Define fitting function for fminsearch (negative log likelihood is minimized)
negLL_fitfun = @(params) -ComputeLL(params,StimLevels,NumPos,OutOfNum,HLB(types_params2fit),HUB(types_params2fit),beta_flag,paramIDmatrix,fixedParams,idx_params2fit,logistic);    %see helper function below

% Set fminsearch options
optionsFminsearch = optimset('fminsearch');
optionsFminsearch = optimset(optionsFminsearch,'Display','off','MaxFunEvals',10000,'MaxIter',10000);

% Run fminsearch with num_fits promising starting points   
init_params = params_grid(1:num_fits,:);
fitted_params = nan(num_fits,num_params2fit);
exitflags = nan(num_fits,1);
LL_fitted = nan(num_fits,1);
for i=1:num_fits
    [fitted_params(i,:),negLL,exitflags(i)] = fminsearch(negLL_fitfun,init_params(i,:),optionsFminsearch);
    LL_fitted(i) = -negLL;
end

% Select the converged fit (if available) with the highest LL
convergedBool = (exitflags == 1);
if sum(convergedBool) >= 1
    LL_fitted(~convergedBool) = -Inf;
end
[~,idx_sorted] = sort(LL_fitted,'descend');
fitted_params = fitted_params(idx_sorted(1),:);
LL = LL_fitted(idx_sorted(1));
exitflag = exitflags(idx_sorted(1));

% Tranform from vector to matrix (incl. fixed parameters)
fixedParams(idx_params2fit) = fitted_params;                %full vector
FittedParams = fixedParams(paramIDmatrix);                  %full matrix

% Back-transform the parameters to meaningful space
FittedParams(:,2) = exp(FittedParams(:,2)); 
FittedParams(:,3) = logistic(FittedParams(:,3)); 
if beta_flag
    FittedParams(:,4) = logistic(FittedParams(:,4)); 
end

end %[EoF]

%%%%%%%%%%%%%%%%%%%%%%%
%%% Helper function %%%
%%%%%%%%%%%%%%%%%%%%%%%

% Compute log-likelihood (LL) of observing the data under the model and its parameters   
function LL = ComputeLL(params,StimLevels,NumPos,OutOfNum,HLB,HUB,beta_flag,paramIDmatrix,fixedParams,idx_params2fit,logistic)              
    
    if any(params <= HLB | params >= HUB)                                   
        % Ensure parameter bounds
        LL = -realmax;                                                              
    else
        
        % Tranform from vector to matrix (incl. fixed parameters)
        fixedParams(idx_params2fit) = params;                               %full vector
        params = fixedParams(paramIDmatrix);                                %full matrix
        
        % Transform cumulative normal parameters to meaningful space
        PSE = params(:,1);                                                    
        JND = exp(params(:,2));                                               
        Gamma = logistic(params(:,3));                                               

        % Compute proportion correct per stimulus level (use cumulative normal and correct for lapse rate)
        num_StimLevels = size(StimLevels,2);
        pcorrect = .5*Gamma+(1-Gamma).*normcdf(StimLevels,repmat(PSE,[1 num_StimLevels]),repmat(JND,[1 num_StimLevels]));        

        % Compute log-likelihood
        if beta_flag 

            % Beta-binomial model
            Eta = logistic(params(:,4)); 
            eta_prime = (1./Eta.^2)-1;
            alpha = pcorrect.*eta_prime;                 
            beta = (1-pcorrect).*eta_prime;
            LL = nansum(gammaln(NumPos+alpha)+gammaln((OutOfNum-NumPos)+beta)-gammaln(OutOfNum+eta_prime)+gammaln(eta_prime)-gammaln(alpha)-gammaln(beta),'all');

        else

            % Binomial model
            LL = nansum(NumPos.*log(pcorrect)+(OutOfNum-NumPos).*log(1-pcorrect),'all');   %Use nansum(x,'all') to sum over Conditions (rows) and StimLevels (columns)
                                                                                           %because according to MATLAB 0*log(0) = NaN.
        end
      
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Simple script for testing of function above %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %Beta-binomial model or not?
% beta_flag = true;
% 
% % Set some true parameter values
% num_conds = 3;
% 
% true_PSE = [-2; 0; 2];
% true_JND = 5;
% true_Gamma = 0.03;            
% true_Eta = 0.05;
% 
% num_StimLevels = 13;                                                        %More StimLevels improve accuracy of Eta
% num_StimPerLevel = 25;                                                      %More trials overall improve accuracy of PSE, JND and Gamma  
% StimLevels = repmat(linspace(-2.5*true_JND, 2.5*true_JND, num_StimLevels),[num_conds 1]);
% OutOfNum = repmat(num_StimPerLevel*ones(1,num_StimLevels),[num_conds 1]);
% 
% % Compute probability of correct responses per stimulus level
% pcorrect = .5*true_Gamma+(1-true_Gamma).*normcdf(StimLevels,true_PSE,true_JND);
% 
% % Determine parameters of beta distribution for every stimulus level
% if beta_flag
%     eta_prime = (1/true_Eta^2)-1;
%     alpha = pcorrect.*eta_prime;                 
%     beta = (1-pcorrect).*eta_prime;
%     pcorrect = betarnd(alpha,beta);                                         %Randomly sample the pcorrect value from the beta distribution!
% end                                                                         %Such random sampling needs to be done on every iteration of a bootstrap procedure
% 
% % Randomly sample the number of positive responses for each stimulus level
% rng('shuffle');
% NumPos = sum(rand([num_conds,num_StimLevels,num_StimPerLevel]) < pcorrect,3);
% 
% % Call this function to fit the data and see if the parameter values match
% paramIDmatrix = [1 2 3 4; ...
%                  5 2 3 4; ...
%                  6 2 3 4];
% 
% fixedParams = nan(1,6);
% fixedParams(3) = 0.03;
% 
% [FittedParams,LL,exitflag] = fitCumNorm(StimLevels,NumPos,OutOfNum,beta_flag,[],[],paramIDmatrix,fixedParams);
% 
% fitted_PSEs = FittedParams(:,1)
% fitted_JNDs = FittedParams(:,2)
% fitted_Gammas = FittedParams(:,3)
% if beta_flag 
%     fitted_Etas = FittedParams(:,4)
% end
