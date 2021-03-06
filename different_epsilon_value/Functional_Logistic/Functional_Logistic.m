function [w, b] = Functional_Logistic(Train, ep, ep2)

% function [w, b] = Functional_Logistic(Train, ep)
%
% Differentially private logistic regression using Funcational Mechanism.
%
% Input parameters:
% Training data (Train) with last column attribute to be predicted. Last
% column should be binary {0,1}.
% Train = [x1, x2, ..., xd, y]
%
% NOTICE: The values of EACH attribute (column) should be converted from [min,
% max] to [-1,1] in order to match the privacy design of Functional
% Mechanism. Please make sure that ALL values in Train are located in
% [-1,1]. If Train is rescaled to meet this requirement, Test should be
% converted IN THE SAME WAY to get the correct answer.
%
% Privacy budget (ep) is a parameter in differential privacy, which
% indicates the strength of privacy protection.
%
% Model is
%
%   (w, b) = argmin sum(log(1+exp(x*w+b))-y(x*w+b))
%
% Outputs are regression coefficients w and b.
%
% Copyright 2012 Jun Zhang


rangeChecker = sum(sum(Train>1)) + sum(sum(Train<-1));
if (rangeChecker>0)
    disp('NOTICE: The values in EACH attribute (column) should be converted from [min, max] to [-1,1]');
    return;
end



[TrainRow, TrainCol] = size(Train);

TrainX = Train(:,1:end-1);
TrainX = [TrainX, ones(TrainRow,1)];             % x*w + b, add bias b

TrainY = Train(:,end);

d = TrainCol;

R0 = (1/8) .* (TrainX' * TrainX);
R1 = TrainX' * (0.5-TrainY);

Sensitivity = (1/4)*d*d + 3*d;


global Coe2;
global Coe1;
%martial status
%Edit by chengsi 2015    
R0(5:end,5) = R0(5:end,5) + laprnd(10, 1, 0, Sensitivity * (1/ep));
R0(5,6:end) = R0(5,6:end) +  laprnd(1, 9, 0, Sensitivity * (1/ep)); 
R0(1:4,1:end) = R0(1:4,1:end) + laprnd(4, 14, 0, Sensitivity * (1/ep2));
R0(5:end,1:4) = R0(5:end,1:4) + laprnd(10, 4, 0, Sensitivity * (1/ep2));
R0(6:end, 6:end) = R0(6:end, 6:end) + laprnd(9, 9, 0, Sensitivity * (1/ep2));

Coe2 = R0;


Coe2 = 0.5 * (Coe2'+Coe2);
Coe2 = Coe2 + 5 * sqrt(2) * Sensitivity * (1/ep) * eye(d);   %Regularization


 R1(5,1)= R1(5,1) + laprnd(1, 1, 0, Sensitivity * (1/ep));
 R1(1:4,1)= R1(1:4,1) + laprnd(4, 1, 0, Sensitivity * (1/ep2));
 R1(6:end,1) = R1(6:end,1) + laprnd(9, 1, 0, Sensitivity * (1/ep2));

 
Coe1 = R1;
%   Consistency: Coe2 positive-define
[vec,val]=eig(Coe2);

del = diag(val)<1e-8;

val(del,:) = [];
val(:,del) = [];

vec(:,del) = [];


Coe2 = val;
Coe1 = vec'*Coe1;
%   End of Consistency

g0 = rand(d-sum(del), 1);
options = optimset('LargeScale','off');
options.MaxFunEvals = 100000;
[g,~,~,~] = fminunc(@noised, g0, options);

bestw = vec * g;

w = bestw(1:end-1);
b = bestw(end);

