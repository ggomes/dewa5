clc
clear
close all

load dataSolar

% Parameter Initilization
mnth = 6; % June
day_mnth = 30; % # days in mnth
totSampledPoint = day_mnth*24*4; % total number of data points in a month: # days * hr in a day * sample per hr
paybackrate=0;

%% extracting PV generated power and demand form month i
PVgen_monthi    = [PVGen{mnth}, PVGen{mnth+1}]; % in kW
demand_monthi   = [Demand{mnth}, Demand{mnth+1}]; % meter demand for month mnth

%% read/generate energy and demand price
EC_monthi  = [EC{mnth}, EC{mnth+1}];
PC1_monthi = [PC1{mnth}, PC1{mnth}];
PC2_monthi = [PC2{mnth}, PC2{mnth}];
PC3_monthi = [PC3{mnth}, PC3{mnth}];
%%

% Initialization
batt_state(1) = 0; % GG Battery state at the start of the month
horizon = 3*24*4; % GG  # days * 24hr * 4 data points per hour
batt_eff=0.66;
opt_top_idxrows = 39; % GG optimal solar rows to buy

stored_Ec = [];
stored_Pc1= [];
stored_Pc2= [];
stored_Pc3= [];
stored_d1 = [];
stored_flow_tocustomer1 =[];
stored_flow_surplus = [];
stored_batt_flow_in  = [];
stored_batt_flow_out = [];
stored_green_energy  = [];
stored_PV = [];
    
% Open-loop sequence of action to execute
ol_inputs = 12*4; % Solve the MPC every 12 hr: (# hr * sample per hr)

% Run time loop
for time = 1:ol_inputs:(totSampledPoint)
    
    time
    
    disp(strcat('Percentage:~',num2str(time/totSampledPoint*100)))
    
    % Read measurement and noisy forecasts
    [ PV_horizon, demand_horizon, EC_horizon, PC1_horizon, PC2_horizon, PC3_horizon ] = readMeasurementsAndForecast( time, horizon,  PVgen_monthi, demand_monthi, EC_monthi, PC1_monthi, PC2_monthi, PC3_monthi);
    
    % Solve MPC problem
    [batt_flow_in_MPC, batt_flow_out_MPC, stored_flow_tocustomer1_MPC, stored_flow_surplus_MPC, stored_green_energy_MPC] = FTOCP(  PV_horizon, demand_horizon, EC_horizon, PC1_horizon, PC2_horizon, PC3_horizon, batt_state(time), ol_inputs, opt_top_idxrows);    
    
    % Store cost and evaluate model
    for j = 1:ol_inputs
        batt_state(time + j) = batt_state(time+j-1)+batt_eff*batt_flow_in_MPC(j)-batt_flow_out_MPC(j);
    end
    stored_PV = [stored_PV  PV_horizon(1:ol_inputs)];
    stored_Ec               = [stored_Ec, EC_horizon(1:ol_inputs)];
    stored_Pc1              = [stored_Pc1, PC1_horizon(1:ol_inputs)];   
    stored_Pc2              = [stored_Pc2, PC2_horizon(1:ol_inputs)]; 
    stored_Pc3              = [stored_Pc3, PC3_horizon(1:ol_inputs)];   
    stored_d1               = [stored_d1; demand_horizon(1:ol_inputs)'];
    stored_flow_tocustomer1 = [stored_flow_tocustomer1,; stored_flow_tocustomer1_MPC];
    stored_flow_surplus     = [stored_flow_surplus; stored_flow_surplus_MPC];
    stored_batt_flow_in     = [stored_batt_flow_in; batt_flow_in_MPC];
    stored_batt_flow_out    = [stored_batt_flow_out; batt_flow_out_MPC];
    stored_green_energy     = [stored_green_energy; stored_green_energy_MPC];

end

%% Now Compute Cost of Operation
CostEn      = stored_Ec*(stored_d1-stored_flow_tocustomer1)/4;
CostPeak(1) = norm(stored_Pc1'.*(stored_d1-stored_flow_tocustomer1),Inf);
CostPeak(2) = norm(stored_Pc2'.*(stored_d1-stored_flow_tocustomer1),Inf);
CostPeak(3) = norm(stored_Pc3'.*(stored_d1-stored_flow_tocustomer1),Inf);

RevPeak(1)= norm(stored_Pc1'.*stored_d1,Inf)-norm(stored_Pc1'.*(stored_d1-stored_flow_tocustomer1),Inf);
RevPeak(2)= norm(stored_Pc2'.*stored_d1,Inf)-norm(stored_Pc2'.*(stored_d1-stored_flow_tocustomer1),Inf);
RevPeak(3)= norm(stored_Pc3'.*stored_d1,Inf)-norm(stored_Pc3'.*(stored_d1-stored_flow_tocustomer1),Inf);

RevenuesEnergytoGrid = stored_Ec * stored_flow_surplus/4;
RevenuesEnergytoCustomer = stored_Ec*(stored_flow_tocustomer1)/4;
        
RevenuesDemand           = RevPeak(1)+RevPeak(2)+RevPeak(3);
        
RevenuesEnergytoGridTotal=min(sum(CostEn),sum(RevenuesEnergytoGrid));
Fusion_Total_Billmonthly = CostEn + CostPeak(1) + CostPeak(2) + CostPeak(3);
     
save closedLoopSimulation