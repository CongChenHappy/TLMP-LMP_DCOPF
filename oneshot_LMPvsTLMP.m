%% Oneshot TLMP and LMP, toy example
%Intro:This code is for the toy example in Table II of our paper: Y. Guo, C. Chen and L. Tong, "Pricing Multi-Interval Dispatch Under Uncertainty Part I: Dispatch-Following Incentives," in IEEE Transactions on Power Systems, vol. 36, no. 5, pp. 3865-3877, Sept. 2021, doi: 10.1109/TPWRS.2021.3055730.
%Paper online:
%1. https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=9340582
%2. https://arxiv.org/abs/1912.13469
%Author: Cong Chen

%Requires package:
%1. Yalmip
%2. gurobi or cplex
%% initialization
clear;
clc;
%% data imput
Cost=[25 30]';%energy marginai cost
Capacity=[500 500]';%gene capacity
Ramp_lim=[500 50]';%ramp limit NEW large ramp
Load=[0 420 590 590];
T0=1;%time horizon
T=3;%time horizon
%% set variable
P=sdpvar(2,T+1,'full');%P_i_t output_gene_time T0-T
%% model objectives  minimize cost
obj=Cost(1)*(sum(P(1,(T0+1):(T+1))))+Cost(2)*(sum(P(2,(T0+1):(T+1))));%energy cost  % 0.25*obj has unit MWh
%% cons
cons1=[0<=P(1,:)<=Capacity(1);0<=P(2,:)<=Capacity(2)];%capacity limit

cons2=[];
for t=(T0+1):(T+1) 
    cons2=cons2+[P(1,t)+P(2,t)==Load(t)];%power balance
end

%regular ramping
cons3down=[];
cons3up=[];
for t=(T0+2):(T+1)
    cons3down=cons3down+[-Ramp_lim(1)<=P(1,t)-P(1,t-1)];%ramp limit gene1  
    cons3up=cons3up+[P(1,t)-P(1,t-1)<=Ramp_lim(1)];
end

cons4down=[];
cons4up=[];
for t=(T0+2):(T+1)
    cons4down=cons4down+[-Ramp_lim(2)<=P(2,t)-P(2,t-1)];%ramp limit gene2 
    cons4up=cons4up+[P(2,t)-P(2,t-1)<=Ramp_lim(2)];
end


consall=cons1+cons2+cons3down+cons3up+cons4down+cons4up;
%% solve
%       op=sdpsettings('solver','cplex');%cplex
op=sdpsettings('solver','gurobi');%gurobi
sol=solvesdp(consall,obj,op)%minimize objective
%% Cplex生成结果
obj=value(obj); %energy cost
P=value(P);%P_i_t output_gene_time
%% dual
inter=T-T0+1;
for s=1:inter %interval of time horizon
    la(s)=dual(cons2(s));%power balance T0-T dual
    %LMP la_1 la_2
    LMP(T0+s-1)=-la(s);%time
end


for s=1:(inter-1)
    mu1down(s)=dual(cons3down(s));%ramp limit gene1 down
    mu1up(s)=dual(cons3up(s));%ramp limit gene1 up
    mu2down(s)=dual(cons4down(s));%ramp limit gene2 down
    mu2up(s)=dual(cons4up(s));%ramp limit gene2 up
end

%TLMP
deta(1,1)=mu1up(1)-mu1down(1);
deta(2,1)=mu2up(1)-mu2down(1);
deta(1,T0+inter-1)=-mu1up(inter-1)+mu1down(inter-1);%pricing of the last point don't have up ramping
deta(2,T0+inter-1)=-mu2up(inter-1)+mu2down(inter-1);
TLMP_T(:,1)=[-(la(1)-deta(1,T0)) -(la(1)-deta(2,T0))]';% TLMP only the first point is settled price
TLMP_T(:,inter)=[-(la(inter)-deta(1,T0+inter-1)) -(la(inter)-deta(2,T0+inter-1))]';% TLMP last point
for s=2:(inter-1)
    %TLMP
    deta(1,T0+s-1)=mu1up(s)-mu1up(s-1)-mu1down(s)+mu1down(s-1);
    deta(2,T0+s-1)=mu2up(s)-mu2up(s-1)-mu2down(s)+mu2down(s-1);
    TLMP_T(:,s)=[-(la(s)-deta(1,T0+s-1)) -(la(s)-deta(2,T0+s-1))]';% TLMP only the first point is settled price
end
%% output

% save('LMP.mat','LMP');%LMP
% save('TLMP.mat','TLMP_T');%TLMP
fprintf('*******************-----------------------------*******************\n');
fprintf('******-------Part 1  optimal dispatch of G1------------------******\n');
fprintf('Optimal dispatch for G1 at t=1 is %10.2fMW\n',P(1,2))
fprintf('Optimal dispatch for G1 at t=2 is %10.2fMW\n',P(1,3))
fprintf('Optimal dispatch for G1 at t=3 is %10.2fMW\n',P(1,4))
fprintf('******-------Part 1  optimal dispatch of G2------------------******\n');
fprintf('Optimal dispatch for G2 at t=1 is %10.2fMW\n',P(2,2))
fprintf('Optimal dispatch for G2 at t=2 is %10.2fMW\n',P(2,3))
fprintf('Optimal dispatch for G2 at t=3 is %10.2fMW\n',P(2,4))
fprintf('******-------Part 2  LMP of G1 and G2  ----------------------******\n');
fprintf('LMP at t=1 is %10.2f$/MWh\n',LMP(1))
fprintf('LMP at t=2 is %10.2f$/MWh\n',LMP(2))
fprintf('LMP at t=3 is %10.2f$/MWh\n',LMP(3))
fprintf('******-------Part 2  TLMP of G1------------------------------******\n');
fprintf('TLMP of G1 at t=1 is %10.2f$/MWh\n',TLMP_T(1,1))
fprintf('TLMP of G1 at t=2 is %10.2f$/MWh\n',TLMP_T(1,2))
fprintf('TLMP of G1 at t=3 is %10.2f$/MWh\n',TLMP_T(1,3))
fprintf('******-------Part 2  TLMP of G2------------------------------******\n');
fprintf('TLMP of G2 at t=1 is %10.2f$/MWh\n',TLMP_T(2,1))
fprintf('TLMP of G2 at t=2 is %10.2f$/MWh\n',TLMP_T(2,2))
fprintf('TLMP of G2 at t=3 is %10.2f$/MWh\n',TLMP_T(2,3))
fprintf('*******************--------------end------------------*************\n');