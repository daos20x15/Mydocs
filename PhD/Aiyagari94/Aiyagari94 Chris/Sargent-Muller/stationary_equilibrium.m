function [residual,at,K] = stationary_equilibrium(r0,crit,I,T,Amat,Ymat,alpha,b,delta,rho,varphi,A0,C0,H)
% this function
% (1) solves for the consumption decision rule, given an
% intereste rate, r0
% (2) simulates the stationary equilibrium associated with the interest
% rate, r0
% (3) (i) returns the residual between the given interes rate r0 and the one
% implied by the stationary aggregate capital and labor supply.
% (ii) returns as an optional output the wealth distribution.

% get dimensions of the grid
[M,N] = size(Amat);

% get productivity realizations from the first row
%
y1 = Ymat(1,1);
y2 = Ymat(1,2);
%}
%
y3 = Ymat(1,3);
y4 = Ymat(1,4);
y5 = Ymat(1,5);
y6 = Ymat(1,6);
y7 = Ymat(1,7);
Y = [y1,y2,y3,y4,y5,y6,y7];
%}
% compute the wage according to marginal pricing and a Cobb-Douglas 
% production function
w0 = (1-alpha)*(alpha/(r0+delta))^(alpha/(1-alpha));

% initial guess on future consumption (consume asset income plus labor
% income from working h=1.
cp0 = r0*Amat+Ymat*w0;

%%% iterate on the consumption decision rule

% distance between two successive functions
% start with a distance above the convergence criterion
dist    = crit+1;
% maximum iterations (avoids infinite loops)
maxiter = 10^(3);
% counter
iter    = 1;

fprintf('Inner loop, running... \n');
    
while (dist>crit&&iter<maxiter)

    % derive current consumption
    c0 = C0(cp0,r0);

    % derive current assets
    a0 = A0(Amat,Ymat,c0,r0,w0);

    %%% update the guess for the consumption decision

    % consumption decision rule for a binding borrowing constraint
    % can be solved as a quadratic equation
    % c^(2)-((1+r)a+b)c-(yw)^(1+2/3) = 0
    % general formula and notation: ax^(2)+bx+c = 0
    % x = (-b+sqrt(b^2-4ac))/2a
    cpbind = ((1+r0)*Amat+b)/2+sqrt(((1+r0)*Amat+b).^(2)+4*(Ymat*w0).^(1+varphi))/2;
    % % slow alternative: rootfinding gives the same result
    % cpbind  = zeros(M,N);
    % options = optimset('Display','off');
    % cpbind(:,1) = fsolve(@(c) (1+r0)*Amat(:,1)+H(c,Y(1),w0).*Y(1).*w0-c+b,cp0(:,1),options);
    % cpbind(:,2) = fsolve(@(c) (1+r0)*Amat(:,2)+H(c,Y(2),w0).*Y(2).*w0-c+b,cp0(:,2),options);

    % consumption for nonbinding borrowing constraint
    cpnon = zeros(M,N);
    % interpolation conditional on productivity realization
    % instead of extrapolation use the highest value in a0
    %cpnon(:,1)  = interp1(a0(:,1),c0(:,1),Amat(:,1),'spline');
    %cpnon(:,2)  = interp1(a0(:,2),c0(:,2),Amat(:,2),'spline');
    for i=1:N
        cpnon(:,i)  = interp1(a0(:,i),c0(:,i),Amat(:,i),'spline');
    end
    % merge the two, separate grid points that induce a binding borrowing constraint
    % for the future asset level (the first observation of the endogenous current asset grid is the 
    % threshold where the borrowing constraint starts binding, for all lower values it will also bind
    % as the future asset holdings are monotonically increasing in the current
    % asset holdings).
    %cpnext(:,1) = (Amat(:,1)>a0(1,1)).*cpnon(:,1)+(Amat(:,1)<=a0(1,1)).*cpbind(:,1);
    %cpnext(:,2) = (Amat(:,2)>a0(1,2)).*cpnon(:,2)+(Amat(:,2)<=a0(1,2)).*cpbind(:,2);
    for i =1:N
        cpnext(:,i) = (Amat(:,i)>a0(1,i)).*cpnon(:,i)+(Amat(:,i)<=a0(1,i)).*cpbind(:,i);
    end
    % distance measure
    dist = norm((cpnext-cp0)./cp0);

    % display every 100th iteration
    if mod(iter,100) == 1
        fprintf('Inner loop, iteration: %3i, Norm: %2.6f \n',[iter,dist]);
    end

    % increase counter
    iter = iter+1;

    % update the guess on the consumption function
    cp0 = cpnext;

end

fprintf('Inner loop, done. \n');

fprintf('Starting simulation... \n');




%%% simulate the stationary wealth distribution

% initialize variables
at      = zeros(I,T+1);
yt      = zeros(I,T);
ct      = zeros(I,T);
ht      = zeros(I,T);

at(:,1) = 1;            % initial asset level
state_it = zeros(I,N,T);
%[~,state] = markov(rho,T+1,1);
for i =1:I
    s0 = unifrnd(0,1,1,1);
    s1 = (s0<=1/7)+(s0>1/7&s0<=2/7).*2+(s0>2/7&s0<=3/7).*3+(s0>3/7&s0<=4/7).*4+(s0>4/7&s0<=5/7).*5+(s0>5/7&s0<=6/7).*6+(s0>6/7).*7;
    [~,state] = markov(rho,T+1,s1);
    state_it(i,:,:) =state;  
end
Y_aux = zeros(I,T);
for t = 1:T
   % consumption
   Y_aux(:,t) = sum(Y.*state_it(:,:,t),2);
   ct(:,t)   = (Y_aux(:,t)==y1).*interp1(Amat(:,1),cp0(:,1),at(:,t),'spline')...
              +(Y_aux(:,t)==y2).*interp1(Amat(:,2),cp0(:,2),at(:,t),'spline')...
              +(Y_aux(:,t)==y3).*interp1(Amat(:,3),cp0(:,3),at(:,t),'spline')...
              +(Y_aux(:,t)==y4).*interp1(Amat(:,4),cp0(:,4),at(:,t),'spline')...
              +(Y_aux(:,t)==y5).*interp1(Amat(:,5),cp0(:,5),at(:,t),'spline')...
              +(Y_aux(:,t)==y6).*interp1(Amat(:,6),cp0(:,6),at(:,t),'spline')...
              +(Y_aux(:,t)==y7).*interp1(Amat(:,7),cp0(:,7),at(:,t),'spline');
   % labor supply
   ht(:,t)   = H(ct(:,t),Y_aux(:,t),w0);

   % future assets
   at(:,t+1) = (1+r0)*at(:,t)+ht(:,t).*Y_aux(:,t).*w0-ct(:,t); 
end
%{
for t=1:T
   % draw uniform random numbers across individuals
   s = unifrnd(0,1,I,6);
   %{
pi(1,1) = rho;                  % transition from state 1 to state 1
pi(1,2) = 1-rho;                % transition from state 2 to state 1
   %}
   %{
   if t>1   % persistence for t>1
       %{
       yt(:,t) = ((s<=rho)&(yt(:,t-1)==y1)).*y1+((s>rho)&(yt(:,t-1)==y2)).*y1...
                +((s<=rho)&(yt(:,t-1)==y2)).*y2+((s>rho)&(yt(:,t-1)==y1)).*y2;
       %}
       %
  
       %{
       yt(:,t) = ((s(:,1)<=rho(1,1))&(yt(:,t-1)==y1)).*y1...
                +((s(:,1)>rho(1,1))&(s(:,2)<=rho(1,2))&(yt(:,t-1)==y2)).*y1...
                +((s(:,1)>rho(1,1))&(s(:,2)>rho(1,2))&(s(:,3)<=rho(1,3))&(yt(:,t-1)==y3)).*y1...
                +((s(:,1)>rho(1,1))&(s(:,2)>rho(1,2))&(s(:,3)>rho(1,3))&(s(:,4)<=rho(1,4))&(yt(:,t-1)==y4)).*y1...
                +((s(:,1)>rho(1,1))&(s(:,2)>rho(1,2))&(s(:,3)>rho(1,3))&(s(:,4)>rho(1,4))&(s(:,5)<=rho(1,5))&(yt(:,t-1)==y5)).*y1...
                +((s(:,1)>rho(1,1))&(s(:,2)>rho(1,2))&(s(:,3)>rho(1,3))&(s(:,4)>rho(1,4))&(s(:,5)>rho(1,5))&(s(:,6)<=rho(1,6))&(yt(:,t-1)==y6)).*y1...
                +((s(:,1)>rho(1,1))&(s(:,2)>rho(1,2))&(s(:,3)>rho(1,3))&(s(:,4)>rho(1,4))&(s(:,5)>rho(1,5))&(s(:,6)>rho(1,6))&(yt(:,t-1)==y7)).*y1...
 +((s(:,1)<=rho(2,1))&(yt(:,t-1)==y1)).*y2...
                +((s(:,1)>rho(2,1))&(s(:,2)<=rho(2,2))&(yt(:,t-1)==y2)).*y2...
                +((s(:,1)>rho(2,1))&(s(:,2)>rho(2,2))&(s(:,3)<=rho(2,3))&(yt(:,t-1)==y3)).*y2...
                +((s(:,1)>rho(2,1))&(s(:,2)>rho(2,2))&(s(:,3)>rho(2,3))&(s(:,4)<=rho(2,4))&(yt(:,t-1)==y4)).*y2...
                +((s(:,1)>rho(2,1))&(s(:,2)>rho(2,2))&(s(:,3)>rho(2,3))&(s(:,4)>rho(2,4))&(s(:,5)<=rho(2,5))&(yt(:,t-1)==y5)).*y2...
                +((s(:,1)>rho(2,1))&(s(:,2)>rho(2,2))&(s(:,3)>rho(2,3))&(s(:,4)>rho(2,4))&(s(:,5)>rho(2,5))&(s(:,6)<=rho(2,6))&(yt(:,t-1)==y6)).*y2...
                +((s(:,1)>rho(2,1))&(s(:,2)>rho(2,2))&(s(:,3)>rho(2,3))&(s(:,4)>rho(2,4))&(s(:,5)>rho(2,5))&(s(:,6)>rho(2,6))&(yt(:,t-1)==y7)).*y2...
 +((s(:,1)<=rho(3,1))&(yt(:,t-1)==y1)).*y3...
                +((s(:,1)>rho(3,1))&(s(:,2)<=rho(3,2))&(yt(:,t-1)==y2)).*y3...
                +((s(:,1)>rho(3,1))&(s(:,2)>rho(3,2))&(s(:,3)<=rho(3,3))&(yt(:,t-1)==y3)).*y3...
                +((s(:,1)>rho(3,1))&(s(:,2)>rho(3,2))&(s(:,3)>rho(3,3))&(s(:,4)<=rho(3,4))&(yt(:,t-1)==y4)).*y3...
                +((s(:,1)>rho(3,1))&(s(:,2)>rho(3,2))&(s(:,3)>rho(3,3))&(s(:,4)>rho(3,4))&(s(:,5)<=rho(3,5))&(yt(:,t-1)==y5)).*y3...
                +((s(:,1)>rho(3,1))&(s(:,2)>rho(3,2))&(s(:,3)>rho(3,3))&(s(:,4)>rho(3,4))&(s(:,5)>rho(3,5))&(s(:,6)<=rho(3,6))&(yt(:,t-1)==y6)).*y3...
                +((s(:,1)>rho(3,1))&(s(:,2)>rho(3,2))&(s(:,3)>rho(3,3))&(s(:,4)>rho(3,4))&(s(:,5)>rho(3,5))&(s(:,6)>rho(3,6))&(yt(:,t-1)==y7)).*y3...
 +((s(:,1)<=rho(4,1))&(yt(:,t-1)==y1)).*y4...
                +((s(:,1)>rho(4,1))&(s(:,2)<=rho(4,2))&(yt(:,t-1)==y2)).*y4...
                +((s(:,1)>rho(4,1))&(s(:,2)>rho(4,2))&(s(:,3)<=rho(4,3))&(yt(:,t-1)==y3)).*y4...
                +((s(:,1)>rho(4,1))&(s(:,2)>rho(4,2))&(s(:,3)>rho(4,3))&(s(:,4)<=rho(4,4))&(yt(:,t-1)==y4)).*y4...
                +((s(:,1)>rho(4,1))&(s(:,2)>rho(4,2))&(s(:,3)>rho(4,3))&(s(:,4)>rho(4,4))&(s(:,5)<=rho(4,5))&(yt(:,t-1)==y5)).*y4...
                +((s(:,1)>rho(4,1))&(s(:,2)>rho(4,2))&(s(:,3)>rho(4,3))&(s(:,4)>rho(4,4))&(s(:,5)>rho(4,5))&(s(:,6)<=rho(4,6))&(yt(:,t-1)==y6)).*y4...
                +((s(:,1)>rho(4,1))&(s(:,2)>rho(4,2))&(s(:,3)>rho(4,3))&(s(:,4)>rho(4,4))&(s(:,5)>rho(4,5))&(s(:,6)>rho(4,6))&(yt(:,t-1)==y7)).*y4...
  +((s(:,1)<=rho(5,1))&(yt(:,t-1)==y1)).*y5...
                +((s(:,1)>rho(5,1))&(s(:,2)<=rho(5,2))&(yt(:,t-1)==y2)).*y5...
                +((s(:,1)>rho(5,1))&(s(:,2)>rho(5,2))&(s(:,3)<=rho(5,3))&(yt(:,t-1)==y3)).*y5...
                +((s(:,1)>rho(5,1))&(s(:,2)>rho(5,2))&(s(:,3)>rho(5,3))&(s(:,4)<=rho(5,4))&(yt(:,t-1)==y4)).*y5...
                +((s(:,1)>rho(5,1))&(s(:,2)>rho(5,2))&(s(:,3)>rho(5,3))&(s(:,4)>rho(5,4))&(s(:,5)<=rho(5,5))&(yt(:,t-1)==y5)).*y5...
                +((s(:,1)>rho(5,1))&(s(:,2)>rho(5,2))&(s(:,3)>rho(5,3))&(s(:,4)>rho(5,4))&(s(:,5)>rho(5,5))&(s(:,6)<=rho(5,6))&(yt(:,t-1)==y6)).*y5...
                +((s(:,1)>rho(5,1))&(s(:,2)>rho(5,2))&(s(:,3)>rho(5,3))&(s(:,4)>rho(5,4))&(s(:,5)>rho(5,5))&(s(:,6)>rho(5,6))&(yt(:,t-1)==y7)).*y5...
 +((s(:,1)<=rho(6,1))&(yt(:,t-1)==y1)).*y6...
                +((s(:,1)>rho(6,1))&(s(:,2)<=rho(6,2))&(yt(:,t-1)==y2)).*y6...
                +((s(:,1)>rho(6,1))&(s(:,2)>rho(6,2))&(s(:,3)<=rho(6,3))&(yt(:,t-1)==y3)).*y6...
                +((s(:,1)>rho(6,1))&(s(:,2)>rho(6,2))&(s(:,3)>rho(6,3))&(s(:,4)<=rho(6,4))&(yt(:,t-1)==y4)).*y6...
                +((s(:,1)>rho(6,1))&(s(:,2)>rho(6,2))&(s(:,3)>rho(6,3))&(s(:,4)>rho(6,4))&(s(:,5)<=rho(6,5))&(yt(:,t-1)==y5)).*y6...
                +((s(:,1)>rho(6,1))&(s(:,2)>rho(6,2))&(s(:,3)>rho(6,3))&(s(:,4)>rho(6,4))&(s(:,5)>rho(6,5))&(s(:,6)<=rho(6,6))&(yt(:,t-1)==y6)).*y6...
                +((s(:,1)>rho(6,1))&(s(:,2)>rho(6,2))&(s(:,3)>rho(6,3))&(s(:,4)>rho(6,4))&(s(:,5)>rho(6,5))&(s(:,6)>rho(6,6))&(yt(:,t-1)==y7)).*y6...          
  +((s(:,1)<=rho(7,1))&(yt(:,t-1)==y1)).*y7...
                +((s(:,1)>rho(7,1))&(s(:,2)<=rho(7,2))&(yt(:,t-1)==y2)).*y7...
                +((s(:,1)>rho(7,1))&(s(:,2)>rho(7,2))&(s(:,3)<=rho(7,3))&(yt(:,t-1)==y3)).*y7...
                +((s(:,1)>rho(7,1))&(s(:,2)>rho(7,2))&(s(:,3)>rho(7,3))&(s(:,4)<=rho(7,4))&(yt(:,t-1)==y4)).*y7...
                +((s(:,1)>rho(7,1))&(s(:,2)>rho(7,2))&(s(:,3)>rho(7,3))&(s(:,4)>rho(7,4))&(s(:,5)<=rho(7,5))&(yt(:,t-1)==y5)).*y7...
                +((s(:,1)>rho(7,1))&(s(:,2)>rho(7,2))&(s(:,3)>rho(7,3))&(s(:,4)>rho(7,4))&(s(:,5)>rho(7,5))&(s(:,6)<=rho(7,6))&(yt(:,t-1)==y6)).*y7...
                +((s(:,1)>rho(7,1))&(s(:,2)>rho(7,2))&(s(:,3)>rho(7,3))&(s(:,4)>rho(7,4))&(s(:,5)>rho(7,5))&(s(:,6)>rho(7,6))&(yt(:,t-1)==y7)).*y7;           
            %}   
    else     % random allocation in t=0
       %yt(:,t) = (s<=1/2).*y1+(s>1/2).*y2;
       yt(:,t) = (s(:,1)<=1/7).*y1+(s(:,1)>1/7&s(:,1)<=2/7).*y2+(s(:,1)>2/7&s(:,1)<=3/7).*y3+(s(:,1)>3/7&s(:,1)<=4/7).*y4+(s(:,1)>4/7&s(:,1)<=5/7).*y5+(s(:,1)>5/7&s(:,1)<=6/7).*y6+(s(:,1)>6/7).*y7;
   
   end
    %}
   % consumption
   %
   ct(:,t)   = (yt(:,t)==y1).*interp1(Amat(:,1),cp0(:,1),at(:,t),'spline')...
              +(yt(:,t)==y2).*interp1(Amat(:,2),cp0(:,2),at(:,t),'spline')...
              +(yt(:,t)==y3).*interp1(Amat(:,3),cp0(:,3),at(:,t),'spline')...
              +(yt(:,t)==y4).*interp1(Amat(:,4),cp0(:,4),at(:,t),'spline')...
              +(yt(:,t)==y5).*interp1(Amat(:,5),cp0(:,5),at(:,t),'spline')...
              +(yt(:,t)==y6).*interp1(Amat(:,6),cp0(:,6),at(:,t),'spline')...
              +(yt(:,t)==y7).*interp1(Amat(:,7),cp0(:,7),at(:,t),'spline');
   %}
   %{
 ct(:,t) = (yt(:,t)==y1).*interp1(Amat(:,1),cp0(:,1),at(:,t),'spline')...
              +(yt(:,t)==y2).*interp1(Amat(:,2),cp0(:,2),at(:,t),'spline');
%
   % labor supply
   ht(:,t)   = H(ct(:,t),yt(:,t),w0);

   % future assets
   at(:,t+1) = (1+r0)*at(:,t)+ht(:,t).*yt(:,t).*w0-ct(:,t); 

end
%}

fprintf('simulation done... \n');

% compute aggregates from market clearing
K = mean(mean(at(:,T-100:T)));
L = mean(mean(yt(:,T-100:T).*ht(:,T-100:T)));
r = alpha*(K/L)^(alpha-1)-delta;

% compute the distance between the two
residual = (r-r0)/r0;

end

