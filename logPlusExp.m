function lpe = logplusexp(l1,l2)
%Robustly compute sum of two log-transformed values (e.g. probabilities)
%Input matrices l1=log(p1) and l2=log(p2).
%Output matrix lpe = log(exp(l1) + exp(l2)).

%Following: https://stats.stackexchange.com/questions/379335/adding-very-small-probabilities-how-to-compute

lpe = max(l1,l2) + log1p(exp(-abs(l1-l2)));

%Take care of special case log(0)+log(0); this would otherwise return NaN
lpe((l1 == -inf) & (l2 == -inf)) = -inf;

end %[EoF]