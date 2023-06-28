function CSdiv = CauchySchwartzDiv(w1,mu1,var1,w2,mu2,var2)
% Compute the Cauchy-Schwartz divergence for two mixtures of univariate 
% normal distributions parameterized by weights (w), means (mu) and 
% variances (var).  
%
% The number of mixture components should be given in the 2nd dimension. 
% The 1st dimension is reserved for the number of CSdivs to compute (N0). 
%
% Kampa, Hasanbelliu & Principe (2011), Closed-form  Cauchy-Schwartz PDF
% divergence for mixture of Gaussians. DOI: 10.1109/IJCNN.2011.6033555
%
% 04-03-2023
% David Meijer
% MeijerDavid1@gmail.com

assert(isequal(size(w1,1),size(mu1,1),size(var1,1),size(w2,1),size(mu2,1),size(var2,1)),'Number of rows (N0) is not equal in all input arguments');
N0 = size(w1,1);
assert(isequal(size(w1,2),size(mu1,2),size(var1,2)),'Mixture 1 component sizes (N1) are not equal');
N1 = size(w1,2);
assert(isequal(size(w2,2),size(mu2,2),size(var2,2)),'Mixture 2 component sizes (N2) are not equal');
N2 = size(w2,2);

% %Ensure vectors in 2nd dim for mixture 1 and vectors in 3rd dim for mixture 2
% w1 = reshape(w1,[N0 N1 1]); mu1 = reshape(mu1,[N0 N1 1]); var1 = reshape(var1,[N0 N1 1]);
% w2 = reshape(w2,[N0 1 N2]); mu2 = reshape(mu2,[N0 1 N2]); var2 = reshape(var2,[N0 1 N2]);
% 
% %Compute the normalization constants z
% z12 = normpdf(mu1,mu2,sqrt(var1+var2));
% z11 = normpdf(mu1,reshape(mu1,[N0 1 N1]),sqrt(var1+reshape(var1,[N0 1 N1])));
% z22 = normpdf(reshape(mu2,[N0 N2 1]),mu2,sqrt(reshape(var2,[N0 N2 1])+var2));
% 
% %Compute the divergence in three separate terms (equation 3 in reference paper)
% term1 = -log(sum(w1.*w2.*z12,[2 3]));
% term2 = .5*log(sum(w1.*reshape(w1,[N0 1 N1]).*z11,[2 3]));
% term3 = .5*log(sum(reshape(w2,[N0 N2 1]).*w2.*z22,[2 3]));

%Ensure vectors in 2nd dim for mixture 1 and vectors in 3rd dim for mixture 2
log_w1 = log(reshape(w1,[N0 N1 1])); mu1 = reshape(mu1,[N0 N1 1]); var1 = reshape(var1,[N0 N1 1]);
log_w2 = log(reshape(w2,[N0 1 N2])); mu2 = reshape(mu2,[N0 1 N2]); var2 = reshape(var2,[N0 1 N2]);

%Compute the log-normalization constants z
log_z12 = normlogpdf(mu1,mu2,sqrt(var1+var2));
log_z11 = normlogpdf(mu1,reshape(mu1,[N0 1 N1]),sqrt(var1+reshape(var1,[N0 1 N1])));
log_z22 = normlogpdf(reshape(mu2,[N0 N2 1]),mu2,sqrt(reshape(var2,[N0 N2 1])+var2));

%Compute the divergence in three separate terms (equation 3 in reference paper)
term1 = -logsumexp(log_w1+log_w2+log_z12,[2 3]);
term2 = .5*logsumexp(log_w1+reshape(log_w1,[N0 1 N1])+log_z11,[2 3]);
term3 = .5*logsumexp(reshape(log_w2,[N0 N2 1])+log_w2+log_z22,[2 3]);

%Put them together by summing:
CSdiv = term1+term2+term3;

end %[EoF]
