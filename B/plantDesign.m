% Initialization
clc
clear all

load dataSolar
Total_revenues=0;
Total_flow=0;
paybackrate=0;
idgt=[1:12]; % month index
top_idxrows=[35:45];  % how many solar rows you want to buy, each row 25kwh each row has 24 KwH battery

for N=top_idxrows
    for mnth=idgt, % mnth is index of month
        %% extracting PV generated power and demand form month i
        PVgen_monthi    =PVGen{mnth}; % in kW
        demand_monthi   =Demand{mnth}; % meter demand for month mnth

        numDataPoints = size(PVgen_monthi,2);
        %% read/generate energy and demand price
        EC_monthi =EC{mnth};
        PC1_monthi=PC1{mnth};
        PC2_monthi=PC2{mnth};
        PC3_monthi=PC3{mnth};

        %% Define problems Variables
        batt_state=sdpvar(numDataPoints+1,1);
        batt_flow_in=sdpvar(numDataPoints,1);
        batt_flow_out=sdpvar(numDataPoints,1);
        green_energy_lost=sdpvar(numDataPoints,1);
        green_energy=sdpvar(numDataPoints,1);
        flow_surplus=sdpvar(numDataPoints,1);
        flow_to_demand=sdpvar(numDataPoints,1);

        %paramteters
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
            
        % Energy balance for each row (NODE 1)
        PVgen_monthi(:)==(batt_flow_in(:)-batt_flow_out(:)+green_energy(:)) ...
        
        % Utility energy balance (grid + demand)
        green_energy(:) == 1/N*(flow_to_demand(:)+flow_surplus(:)) + green_energy_lost(:)];
        
    % Energy Balance at the demand
        energy_from_grid = demand_monthi(:)-flow_to_demand(:);

        % Constraints
        constr = constr +[
           % initial battery state
                 batt_state(1)==0 ...
                 %Output Ceiling per Row, AC (kW AC)
                 0<= green_energy(:) - green_energy_lost(:) <= OutputCeiling ...
                 %Row Battery Capacity (kWh)
                 %0<=batt_state(:)<=0 ...
                 0<=batt_state(:)<=24 ...
                 %BilledEnergy1(:)>=0 ...
                 demand_monthi(:)-flow_to_demand(:)>=0 ...
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
        revenues = revenues+ (EC_monthi/4)*flow_surplus(:); % 4 is to take into accoung the 15min
        %Montly Energy Bill savings
        revenues = revenues+ (EC_monthi/4)*flow_to_demand(:);
        %Montly Peak Demand  savings (Notice that energy_from_grid = demand_monthi(:)-flow_to_demand(:))
        revenues = revenues+ norm(PC1_monthi'.*demand_monthi(:),Inf)-norm(PC1_monthi'.*(energy_from_grid),Inf);
        revenues = revenues+ norm(PC2_monthi'.*demand_monthi(:),Inf)-norm(PC2_monthi'.*(energy_from_grid),Inf);
        revenues = revenues+ norm(PC3_monthi'.*demand_monthi(:),Inf)-norm(PC3_monthi'.*(energy_from_grid),Inf);

        %options = sdpsettings('solver','cdd');
        %options = sdpsettings('solver','ipopt');
        options = sdpsettings('solver','linprog');
        %options = sdpsettings('solver','gurobi');
        %options.ipopt=ipoptset('linear_solver','MUMPS');
        %optimize(constr,-revenues,options);
        optimize(constr,-revenues,options);
        
        %z_vec = double(z);
        %u_vec = double(u);
        Total_revenues=Total_revenues+value(revenues) % some over all months
        Total_flow=Total_flow+sum(value(green_energy(:)/4)*N);
        disp('Month solved:')
        mnth
        stored_flow_surplus{mnth}=value(flow_surplus);
        stored_green_energy{mnth}=value(green_energy);
        stored_flow_tocustomer1{mnth}=value(flow_to_demand);
        stored_d1{mnth}=demand_monthi(:);
        stored_batt_flow_in{mnth}=value(batt_flow_in);
        stored_batt_state{mnth}=value(batt_state);
        stored_batt_flow_out{mnth}=value(batt_flow_out);
        stored_PVgen_monthi{mnth}=PVgen_monthi;
        stored_Ec{mnth}=EC_monthi;    
        stored_Pc1{mnth}=PC1_monthi;    
        stored_Pc2{mnth}=PC2_monthi;    
        stored_Pc3{mnth}=PC3_monthi;    
    end

    %% Energy bill Fusion
    for j=idgt
        CostEn(N,j)=stored_Ec{j}*(stored_d1{j}-stored_flow_tocustomer1{j})/4;
        CostPeak(N,j,1)= norm(stored_Pc1{j}'.*(stored_d1{j}-stored_flow_tocustomer1{j}),Inf);
        CostPeak(N,j,2)= norm(stored_Pc2{j}'.*(stored_d1{j}-stored_flow_tocustomer1{j}),Inf);
        CostPeak(N,j,3)= norm(stored_Pc3{j}'.*(stored_d1{j}-stored_flow_tocustomer1{j}),Inf);
        TOP_Fusion_Total_Billmonthly(N,j)=CostEn(N,j)+CostPeak(N,j,1)+CostPeak(N,j,2)+CostPeak(N,j,3);
        GridRev(N,j)=stored_Ec{j}*stored_flow_surplus{j}/4;
        RevPeak(N,j,1)= norm(stored_Pc1{j}'.*stored_d1{j},Inf)-norm(stored_Pc1{j}'.*(stored_d1{j}-stored_flow_tocustomer1{j}),Inf);
        RevPeak(N,j,2)= norm(stored_Pc2{j}'.*stored_d1{j},Inf)-norm(stored_Pc2{j}'.*(stored_d1{j}-stored_flow_tocustomer1{j}),Inf);
        RevPeak(N,j,3)= norm(stored_Pc3{j}'.*stored_d1{j},Inf)-norm(stored_Pc3{j}'.*(stored_d1{j}-stored_flow_tocustomer1{j}),Inf);
        TOP_RevenuesEnergytoCustomer(N,j)=stored_Ec{j}*(stored_flow_tocustomer1{j})/4;
        TOP_RevenuesEnergytoGrid(N,j)=GridRev(N,j);
        TOP_RevenuesDemand(N,j)= RevPeak(N,j,1)+RevPeak(N,j,2)+RevPeak(N,j,3);
    end
    dd1=0;
    dd2=0;
    for j=idgt
        dd1=dd1+sum(stored_d1{j});
        dd2=dd2+sum(stored_flow_surplus{j});
    end
    energy_surplus_yearly(N)=max((dd2-dd1)/4,0);
    %TOP_Original_Bill(N)=sum(Original_Total_Bill);
    TOP_RevenuesDemandTotal(N)=sum(TOP_RevenuesDemand(N,:));
    TOP_RevenuesEnergytoCustomerTotal(N)=sum(TOP_RevenuesEnergytoCustomer(N,:));
    TOP_RevenuesEnergytoGridTotal(N)=min(sum(CostEn(N,:)),sum(TOP_RevenuesEnergytoGrid(N,:)));
    TOP_Fusion_Total_Bill(N)=max(sum(CostEn(N,:))+sum(CostPeak(N,:,1))+sum(CostPeak(N,:,2))+sum(CostPeak(N,:,3))-TOP_RevenuesEnergytoGridTotal(N)-energy_surplus_yearly(N)*paybackrate,0);
end

%save toptest_d2_55rows
save optimalDesign

%top_idxrows

%Compute simple IRR
Initial_investiment_solar=-5.50*1000*25*top_idxrows; %$ per W, * 1000(for kilo) * 25 kW per row * # rows
Initial_investiment_storage=-24*200*top_idxrows; %(200$ kWhr* 20 Kwh per row* # rows)
Initial_investiment=Initial_investiment_solar+Initial_investiment_storage;
