function lpe = logplusexp(A, B)
% LOGPLUSEXP(A, B) computes log(exp(A) + exp(B)) robustly, actually log(bsxfun(@plus, exp(A), exp(B)))
%
%     lpe = logplusexp(A, B);
%
% Avoids overflow when both A and B are large.
%
% This function also avoids underflow when A or B is (close to) zero and the
% other is moderately negative. This case rarely comes up in my usage, and is
% neglected in the log(cum)sumexp routines.
%
% SEE ALSO: LOGSUMEXP LOGCUMSUMEXP

% Iain Murray, September 2010

mx = bsxfun(@max, A, B);
mn = bsxfun(@min, A, B);
%lcs = mx + log(1 + exp(mn-mx));
lpe = mx + log1p(exp(mn-mx));

% Fix up NaN and Inf special cases:
inf_mask = bsxfun(@or, isinf(A), isinf(B));
lpe(inf_mask) = mx(inf_mask);
lpe(bsxfun(@or, isnan(A), isnan(B))) = NaN;