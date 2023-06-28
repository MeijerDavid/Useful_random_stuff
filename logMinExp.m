function lme = logminexp(l1,l2)
%Robustly compute difference of two log-transformed values (e.g. probabilities p)
%Input matrices l1=log(p1) and l2=log(p2).
%Output matrix lme = log(exp(l1) - exp(l2)).

%Following: https://stats.stackexchange.com/questions/383523/subtracting-very-small-probabilities-how-to-compute
%lme = l1 + log1p(-exp(-(l1-l2)));

i1_smaller = (l1 < l2);
if any(i1_smaller,'all')
    %Switch l1 and l2, then add i*pi to the output: https://math.stackexchange.com/questions/2089690/log-of-a-negative-number
    %Avoid indexing because it can be slow
    l1_copy = l1;
    l1 = ~i1_smaller.*l1 + i1_smaller.*l2;
    l2 = ~i1_smaller.*l2 + i1_smaller.*l1_copy;
    lme = l1 + log1mexp(l1-l2) + i1_smaller*(1i*pi);
else
    lme = l1 + log1mexp(l1-l2);
end

end %[EoF]

%%%%%%%%%%%%%%%%%%%%%%%
%%% Helper function %%%
%%%%%%%%%%%%%%%%%%%%%%%

function y = log1mexp(a)
%Compute log(1-exp(-|a|)) accurately (i.e. input "a" must be >0).
%
%See Machler 2012:
%https://cran.r-project.org/web/packages/Rmpfr/vignettes/log1mexp-note.pdf

a0 = log(2);

y = nan(size(a));

i_small = a < a0;
y(i_small) = log(-expm1(-a(i_small)));
y(~i_small) = log1p(-exp(-a(~i_small)));

end %[EoF]
