function [ outStruct ] = GaussianFit(x,y,sigma_y,tol)
%GaussianFit: Performs a nonlinear weighted fit on data and calculates
%             uncertainties on the fit parameters [A;mu;sigma]
%             y = A*exp(-0.5*(x-mu).^2/sigma^2)
%
%
%    Note: Be wary of offset Gaussians. If the tails of the distribution do
%          not decay to zero, the fit will not work properly. In this case
%          it is recommended that the user either modify the code to add
%          parameters for the background (e.g. a Gaussian plus a constant)
%          or that the user first subtract the background noise and then
%          fit the data near the peak.
%
%    Note: This program uses Gauss-Newton iteration to determine the fit
%          parameters, which for some cases might not converge. In this
%          case, it is recommended that the tails of the distribution be
%          cut off, with most of the data kept near the peak.
%
%
%    INPUTS: x, y, (sigma_y), (tol)
%        x:       Independant variable (follows a Gaussian distribution)
%        y:       Dependant variable (counts or intensity of x)
%        sigma_y: Uncertainties on the dependant variable
%        tol:     Relative tolerance for the numerical iteration
%
%      The inputs x, y, and possibly sigma_y must be the same size and 1xN
%      or Nx1. If sigma_y is not provided, the fit will assume equal
%      weighting and will solve for the sigma_y that makes the reduced
%      chi-squared equal to 1. If tol is not provided, the iteration will
%      use a preset tolerance for its stop criterion.
%
%
%    OUTPUTS: A structure array containing the following fields:
%        A:            Amplitude of the Gaussian
%        mu:           Mean of the Gaussian
%        sigma:        Standard deviation of the Gaussian
%        sig_[var]:    Uncertainties of the fit parameters
%        corr_[vars]:  Correlation coefficients of the fit parameters
%        fit_x, fit_y: The x and y coordinates of the fit
%        chi2:         The chi-squared estimate of goodness-of-fit
%        chi2red:      Reduced chi-squared
%        sigma_y:      If not an input, estimates the uncertainty of y
%
%      For an equal-weighted fit, a sigma_y will be found such that the
%      reduced chi-squared will be 1.


x = x(:); y = y(:); %Resizes as column arrays

%Initial guess of fit parameters
mu0 = x'*y/sum(y);
sigma0 = sqrt((x'-mu0).^2*y/sum(y));
A0 = max(y);

%Shifts Gaussian to improve numerics
yn = y/A0;
xn = (x-mu0)/sigma0;
P = [1;0;1]; %Estimates of shifted [Amplitude; Mean; Standard Deviation]

if (~exist('sigma_y','var')) %No uncertainties given (unweighted fit)
    u = 1;
    sigma_yn = ones(size(y)); %Temporarily sets all uncertainties to 1
                              %This is rescaled once sigma_y is estimated
else
    u = 0;
    sigma_y(sigma_y<=0) = min(sigma_y(sigma_y>0)); %Resets nonpositive
                                                   %uncertainties
    sigma_yn = sigma_y/A0;
end

if (~exist('tol','var')) %No relative tolerance given
    tol = 1e-12;
end

%Weight matrix
W = diag(sigma_yn.^-2);

%Gaussian and Jacobian derivative with respect to fit parameters
f = @(x,A,mu,sigma)(A*exp(-.5*((x-mu)/sigma).^2));
Df = @(x,A,mu,sigma)([f(x,A,mu,sigma)/A,(x-mu)/sigma^2.*f(x,A,mu,sigma),...
    (x-mu).^2/sigma^3.*f(x,A,mu,sigma)]);

%Gauss-Newton iteration
err = Inf;
while err > tol
    J = Df(xn,P(1),P(2),P(3));
    dyn = yn-f(xn,P(1),P(2),P(3));
    N = J'*W*J;
    c = J'*W*dyn;
    dP = N\c;
    P = P+dP;
    if P(3)<0
        P(3) = -P(3); %Ensures a positive standard deviation
    end
    err = sqrt((c'*dP)/(dyn'*W*dyn));
end

%Unscales
A = P(1)*A0;
mu = P(2)*sigma0+mu0;
sigma = P(3)*sigma0;

df = length(x)-length(P); %Degrees of freedom
dy = y-f(x,A,mu,sigma);
J = Df(x,A,mu,sigma);
N = J'*W*J;

if u==1 %Unweighted fit; W (and hence N) is scaled to match uncertainties
    chi2red = 1;
    chi2 = df;
    s_y = sqrt((dy'*dy)/df); %Estimates the uncertainty in y
    V = N\eye(size(N))*s_y^2; %Matrix of variances and covariances
else %Weighted fit; W (and hence N) is unscaled here
    chi2 = dy'*W*dy/A0^2;
    chi2red = chi2/df;
    V = N\eye(size(N))*A0^2; %Matrix of variances and covariances
end

outStruct = struct();
outStruct.A = A;
outStruct.sig_A = sqrt(V(1,1));
outStruct.mu = mu; %Kitty kitty kitty kitty kitty kitty!
outStruct.sig_mu = sqrt(V(2,2));
outStruct.sigma = sigma;
outStruct.sig_sigma = sqrt(V(3,3));
outStruct.corr_A_mu = V(1,2)/sqrt(V(1,1)*V(2,2));
outStruct.corr_A_sigma = V(1,3)/sqrt(V(1,1)*V(3,3));
outStruct.corr_mu_sigma = V(2,3)/sqrt(V(2,2)*V(3,3));

outStruct.fit_x = x;
outStruct.fit_y = f(x,A,mu,sigma);
outStruct.chi2 = chi2;
outStruct.chi2red = chi2red;
if u==1
    outStruct.sigma_y = s_y;
end
end %Fine structure