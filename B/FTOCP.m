function [ batt_flow_in_MPC, batt_flow_out_MPC, stored_flow_tocustomer1_MPC, stored_flow_surplus_MPC, stored_green_energy_MPC  ] = FTOCP( PVgen_horizon,  demand_horizon, EC_horizon, PC1_horizon, PC2_horizon, PC3_horizon, batt_IC, ol_inputs, opt_top_idxrows)
%FTOCP: Finite Time Optimal Control Problem
numDataPoints = size(PVgen_horizon,2);

%% Define problems Variables
batt_state=sdpvar(numDataPoints+1,1);
batt_flow_in=sdpvar(numDataPoints,1);
batt_flow_out=sdpvar(numDataPoints,1);
green_energy_lost=sdpvar(numDataPoints,1);
green_energy=sdpvar(numDataPoints,1);
flow_surplus=sdpvar(numDataPoints,1);
flow_to_demand=sdpvar(numDataPoints,1);

%parameters
N = opt_top_idxrows; % Need to put optimal
OutputCeiling=990/N;
batt_eff=0.66;

%Model Definition
constr = [];
for t = 1:numDataPoints
     % Start model definition
     constr = constr +[
     %battery state
     batt_state(t+1)==batt_state(t)+batt_eff*batt_flow_in(t)-batt_flow_out(t)];
end
constr = constr +[
% Energy balance for each row
PVgen_horizon(:)==(batt_flow_in(:)-batt_flow_out(:)+green_energy(:)) ...
% Utility energy balance (grid + demand)
green_energy(:) == 1/N*(flow_to_demand(:)+flow_surplus(:)) + green_energy_lost(:)];
% Energy Balance at the demand
energy_from_grid = demand_horizon(:)-flow_to_demand(:);

% Constraints
constr = constr +[
   % initial battery state
         batt_state(1)==batt_IC ...
         %Output Ceiling per Row, AC (kW AC)
         0<= green_energy(:) - green_energy_lost(:) <= OutputCeiling ...
         %Row Battery Capacity (kWh)
         %0<=batt_state(:)<=0 ...
         0<=batt_state(:)<=24 ...
         %BilledEnergy1(:)>=0 ...
         demand_horizon(:)-flow_to_demand(:)>=0 ...
         %Battery Charge Limit 12kW
         0<=batt_flow_in(:)<=10 ...
         %kW Battery Capacity 10kW
         0<=batt_flow_out(:)<=10 ...
         % positive flows
         flow_surplus(:)>=0 ...
         green_energy_lost>=0 ...
         flow_to_demand(:)>=0];

%Revenues 
revenues=0;
%Montly Energy Revenue from selling to grid
revenues = revenues+ (EC_horizon/4)*flow_surplus(:); % 4 is to take into accoung the 15min
%Montly Energy Bill savings
revenues = revenues+ (EC_horizon/4)*flow_to_demand(:);
%Montly Peak Demand  savings (Notice that energy_from_grid = demand_horizon(:)-flow_to_demand(:))
revenues = revenues+ norm(PC1_horizon'.*demand_horizon(:),Inf)-norm(PC1_horizon'.*(energy_from_grid),Inf);
revenues = revenues+ norm(PC2_horizon'.*demand_horizon(:),Inf)-norm(PC2_horizon'.*(energy_from_grid),Inf);
revenues = revenues+ norm(PC3_horizon'.*demand_horizon(:),Inf)-norm(PC3_horizon'.*(energy_from_grid),Inf);

%options = sdpsettings('solver','cdd');
%options = sdpsettings('solver','ipopt');
options = sdpsettings('solver','linprog');
%options = sdpsettings('solver','gurobi', 'verbose',0);

%options.ipopt=ipoptset('linear_solver','MUMPS');
%optimize(constr,-revenues,options);
res = optimize(constr,-revenues,options);
if res.problem == 0
    disp('Successfully solve optimization problem')
else
    disp('Problem not solved to optimality')
end

batt_flow_in_MPC            = double(batt_flow_in(1:ol_inputs));
batt_flow_out_MPC           = double(batt_flow_out(1:ol_inputs));
stored_flow_tocustomer1_MPC = double(flow_to_demand(1:ol_inputs));
stored_flow_surplus_MPC     = double(flow_surplus(1:ol_inputs));
stored_green_energy_MPC     = double(green_energy(1:ol_inputs));
end

