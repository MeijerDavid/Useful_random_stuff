function SSE = compSSEnormalFit(params,x,y_pdf)
%Compute sum of squared errors for a normal distribution fit
%Note that the first parameter is log(sd), and the second parameter is mu (optional; 0=default)  

sd = exp(params(1));

if length(params) > 1
    mu = params(2);
else
    mu = 0; %default mu
end

y1_pdf = normpdf(x,mu,sd);

SSE = sum((y_pdf-y1_pdf).^2);

end