clc
clear
close all

load optimalDesign


%% Plot Load and Demand
mnth = [6];
figure
hold on
for i= mnth
    plotPV = plot(TimePVgen{i}, PVGen{i}, '-k', 'linewidth',2);
    plotDemand = plot(TimePVgen{i}, Demand{i}, '-b', 'linewidth',2);
end
ylabel('kW')
xlabel('Time')

h = legend([plotPV, plotDemand], {'Photovoltaic Energy ', 'Demand'})
set(h, 'interpreter', 'latex', 'fontsize',22)

%% Plot PV, Green Energy and Battery Flow
mnth = 6;
figure
hold on
%storedBattState = plot(stored_batt_state{mnth}, '-r');
greenEnergy = plot(TimePVgen{mnth}, stored_green_energy{mnth}, '-g', 'linewidth',2);
battFlow  = plot(TimePVgen{mnth}, stored_batt_flow_in{mnth}-stored_batt_flow_out{mnth}, '-k', 'linewidth',2);
storedPVgen = plot(TimePVgen{mnth}, stored_PVgen_monthi{mnth}, '-b', 'linewidth',2);

ylabel('kW')
xlabel('Time')

h = legend([storedPVgen, greenEnergy, battFlow], {'PV', 'Green Energy', 'Battery Flow'})
set(h, 'interpreter', 'latex', 'fontsize',22)

%% Plot Profitability

figure 
hold on
for idx = top_idxrows
    % Compute the initial investment: the cost per unit decreases with the
    % square root of rows bought
    Initial_investiment_solar=-5.50*1000*25*sqrt(idx); %$ per W, * 1000(for kilo) * 25 kW per row * (# rows)^0.5
    Initial_investiment_storage=-24*200*sqrt(idx); %(200$ kWhr* 20 Kwh per row* (# rows)^0.5 )
    Initial_investiment=Initial_investiment_solar+Initial_investiment_storage;
    
    % Compute total revenues
    totRevenues = TOP_RevenuesDemandTotal(idx) + TOP_RevenuesEnergytoCustomerTotal(idx) + TOP_RevenuesEnergytoGridTotal(idx);
    
    % Compute IRR over the next 10 years
    cashFlow = [Initial_investiment];
    for years = 1:10
        cashFlow = [cashFlow, totRevenues]; % Assume that each year the revenues are constant
    end
    
    % Compute IRR
    IRR_value = irr_dewa([cashFlow]);

    % Plot IRR as a function of the # rows
    plot(idx, IRR_value, 'ob')
end
ylabel('IRR')
xlabel('Number of Rows')