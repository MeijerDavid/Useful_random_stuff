function lme = logMinExp(l1,l2)
%Robustly compute difference of two log-transformed values (e.g. probabilities)
%Input matrices l1=log(p1) and l2=log(p2).
%Output matrix lme = log(exp(l1) - exp(l2)).

%Following: https://stats.stackexchange.com/questions/383523/subtracting-very-small-probabilities-how-to-compute

lme = l1 + log1p(-exp(-(l1-l2)));

end %[EoF]