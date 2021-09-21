function lcs = logcumsumexp(X, varargin)
% LOGCUMSUMEXP(X, dim) Computes log(cumsum(exp(X), dim)) robustly
%
%     lcs = logcumsumexp(X[, dim])
%
% SEE ALSO: LOGSUMEXP LOGPLUSEXP

% Iain Murray, May 2004, September 2010

lcs = ndhelper(@logcumsumexp_cols, X, varargin{:});


function lcs = logcumsumexp_cols(X)
% log(cumsum(exp(X), 1)) for matrix X, but more robustly.

% There will be a neater and faster way to do this.
% For the moment I'm just getting a (hopefully) correct version down.

lcs = zeros(size(X));
if ~isempty(X)
    lcs(1,:) = X(1,:);
    for ii = 2:size(X,1)
        bb = max(lcs(ii-1,:), X(ii,:));
        cc = min(lcs(ii-1,:), X(ii,:));
        %lcs(ii,:) = bb + log(1+exp(cc-bb));
        % The routine is slow anyway, may as well be careful!
        lcs(ii,:) = bb + log1p(exp(cc-bb));
        % Make sure consecutive infinities never cause NaNs:
        lcs(ii,cc==-Inf) = bb(1, cc==-Inf);
        lcs(ii,bb==Inf) = Inf;
    end

    % Corner cases: fix up NaNs caused by NaNs in X
    for jj = 1:size(X,2)
        first_nan = find(isnan(X(:, jj)), 1);
        if first_nan
            lcs(first_nan:end, jj) = NaN;
        end
    end
end