function p = permFisher(d)
%Fisher's permutation test (non-parametric paired t-test, 
%similar to the Wilcoxon signed rank test, but without using ranks)
%See Section 3.1 in Holt & Sullivan, 2023 (https://doi.org/10.1007/s10683-023-09799-6)
%
%Input d is a vector of differences (between paired samples)
%The test checks whether the mean of d is significantly different from zero
%
%Note that the test can take a considerable time to compute if length(d)>10
%
%David Meijer, 07-02-2024 

d = d(:);
T_obs = mean(d);    %the test statistic (e.g. mean, median, etc.)

n=length(d);
num_perms = 2^n;

n_larger = 0;
for i=1:num_perms
    perm_signs = 2*(double(dec2bin(i-1,n))-48)-1;           %permute the signs (using binary representation of idx i)
    T_i = mean((perm_signs').*d);                           
    n_larger = n_larger + double(abs(T_i) >= abs(T_obs));
end

p = n_larger / num_perms;                                   %Equation 5 in Holt & Sullivan, 2023

end %[EoF]


