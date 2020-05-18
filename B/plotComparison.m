clc
clear
close all

load closedLoopSimulation
%% Plot PV, Green Energy and Battery Flow
cmpt_mnth = 6;
figure
hold on
%storedBattState = plot(stored_batt_state{mnth}, '-r');
greenEnergy = plot(TimePVgen{cmpt_mnth}, stored_green_energy, '-g', 'linewidth',2);
battFlow  = plot(TimePVgen{cmpt_mnth}, stored_batt_flow_in-stored_batt_flow_out, '-k', 'linewidth',2);
storedPVgen = plot(TimePVgen{cmpt_mnth}, PVGen{cmpt_mnth}, '-b', 'linewidth',2);

ylabel('kW')
xlabel('Time')

h = legend([storedPVgen, greenEnergy, battFlow], {'PV', 'Green Energy', 'Battery Flow'});
set(h, 'interpreter', 'latex', 'fontsize',22);

%% Bill comparison
MPC_total_revenue = RevenuesEnergytoCustomer + ...
                    RevenuesEnergytoGrid + ...
                    RevenuesDemand;
load optimalDesign
disp(strcat('Revenues for the MPC is: ',num2str(MPC_total_revenue)));
TOP_total_revenue = TOP_RevenuesEnergytoCustomer(opt_top_idxrows, cmpt_mnth) + ...
                    TOP_RevenuesEnergytoGrid(opt_top_idxrows, cmpt_mnth) + ...
                    TOP_RevenuesDemand(opt_top_idxrows, cmpt_mnth);
disp(strcat('Revenues for the optimal design is: ',num2str(TOP_total_revenue)));
