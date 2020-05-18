function [ PV, demand, EC, PC1, PC2, PC3 ] = readMeasurementsAndForecast( time, horizon,  PVgen_monthi, demand_monthi, EC_monthi, PC1_monthi, PC2_monthi, PC3_monthi)
%readMeasurementsAndForecast: Function reads measurement and forecast (corrupted by noise)
noisePV = randn(1,horizon+1); 
noisePV(1) = 0;
PV_exact = PVgen_monthi(time:time+horizon); % GG Read PVgen_monthi from time to  time+horizon...
PV = max(PV_exact + sign(PV_exact).*noisePV,0); % If the energy flow is positive add noise

noisedemand = randn(1,horizon+1); 
noisedemand(1) = 0;
demand = max(demand_monthi(time:time+horizon) + noisedemand , 0); % GG Read demand_monthi from time to  time+horizon... + noisedemand;

%% read/generate energy and demand price (Assumed known)
EC = EC_monthi(time:(time+horizon));
PC1 = PC1_monthi(time:(time+horizon));
PC2 = PC2_monthi(time:(time+horizon));
PC3 = PC3_monthi(time:(time+horizon));
        
end

