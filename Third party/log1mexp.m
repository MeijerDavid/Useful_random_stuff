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