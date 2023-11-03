% fast linear model (ordinary least squares univariate regression) without rank checks (c.f. Matlab's "regress")
% derived from https://it.mathworks.com/matlabcentral/fileexchange/74669-fast-and-essential-linear-regression
% see also: https://en.wikipedia.org/wiki/Ordinary_least_squares
% 
% 2022-06-03 Roberto Barumerli
% 2022-12-08 David Meijer (modifications and commments)
% 2023-09-26 David Meijer (added support for LOO CV statistic)

function [betas, loglik, rsquared, pval, cv, loglik_cv] = lm_fast(X, y, flag_intercept)
% INPUTS (nans are removed)
% X:                nxp regressor matrix of n observations across p regressors
% y:                nx1 vector of responses 
% flag_intercept    add intercept (default: false) internally adds a column of ones to X(:,p+1). If true, the last beta returns the intercept. 
%
% OUTPUT
% betas:            px1 vector of the estimated coefficients
% loglik:           scalar for log likelihood (summed over samples)   
% rsquared:         scalar for R squared (coefficient of determination)
% pval:             px1 vector of p-values for significant difference from zero
% cv:               leave-one-out cross validation statistic (MSE of LOO predictions)
% loglik_cv:        cross-validated log-likelihood

if nargin < 3
    flag_intercept = false;
end

% check that size matches
y = y(:);
assert(size(X, 1) == size(y,1))

% remove nans
nans = logical(sum(isnan(y) | isnan(X),2));
X(nans, :) = [];
y(nans) = [];

% add intercept if requested
if flag_intercept
    X = [X, ones(size(y))];
end

% compute betas (regression coefficients)
betas = (X'*X)\X'*y;

% compute log likelihoods of y
if nargout >= 2 
    y_pred = X*betas;
    SSE = sum((y-y_pred).^2);                       %sum of squared errors
    RMSE = sqrt(SSE/size(y,1));                     %root mean squared error
    
    %loglik = sum(log(normpdf(y,y_pred,RMSE)));
    loglik = sum(-0.5*((y-y_pred)./RMSE).^2-log(RMSE)-0.5*log(2*pi));
    
%     %Alternatively, to keep loglik per sample (take care of NaNs):
%     loglik = nan(size(nans));
%     loglik(~nans) = -0.5*((y-y_pred)./RMSE).^2-log(RMSE)-0.5*log(2*pi);
end

% compute R squared (coefficient of determination)
if nargout >= 3 
    SST = sum((y-mean(y)).^2);                      %sum of squares total
    rsquared = 1-SSE/SST;                           %note that R squared can be negative if no intercept was used
end    
    
% compute p values for the betas
if nargout >= 4 
    df   = max(0,-diff(size(X)));                   %degree of freedom for residuals (n-p)
    s2   = SSE/df;                                  %regression error variance estimate
    se   = sqrt(s2*diag(inv(X'*X)));                %standard errors of betas
    T    = betas./se;                               %t values of betas
    pval = 2*tcdf(abs(T),df,'upper');               %two sided p values of betas
end       

%Compute leave one out cross-validation statistic
%See: https://robjhyndman.com/hyndsight/loocv-linear-models/
%and https://otexts.com/fpp2/regression-matrices.html#regression-matrices
if nargout >= 5
    %H = X*(X'*X)\X';                               %hat matrix 
    H = X*(inv(transpose(X)*X))*transpose(X);       
    h = diag(H);                                    %diagonal values
    cv = mean(((y-y_pred)./(1-h)).^2);              %MSE of LOO predictions
end

% cross validated log likelihood
if nargout >= 6
    squared_pe = ((y-y_pred)./(1-h)).^2;            %squared prediction errors
    loglik_cv = sum(-0.5*squared_pe./cv-log(sqrt(cv))-0.5*log(2*pi));
end

end %[EoF]
