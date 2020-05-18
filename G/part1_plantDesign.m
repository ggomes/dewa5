clear
close all

% load data
load dataSolar

% parameters
params.gamma    = 0.66;       % battery efficiency
params.max_bin  = 10;
params.max_bout = 10;
params.max_B    = 24;
params.max_g    = 990;

Ns = 1:10:80;  % how many solar rows you want to buy, each row 25kwh each row has 24 KwH battery

for N=Ns  % iterate through candidate number of solar rows
    
    fprintf('%d rows ..............',N)
    
    sol = cell(1,12);
    
    for mnth=1:12     % iterate through months
        
        % load solar supply and meter demands for month i
        s = PVGen{mnth};    % in kW
        d = Demand{mnth};   % meter demand for month mnth
        
        % buy and sell price for this month
        price.psell = EC{mnth}'/4;
        price.pbuy  = 1.05*EC{mnth}'/4;
        price.peak1 = PC1{mnth}';
        price.peak2 = PC2{mnth}';
        price.peak3 = PC3{mnth}';
    
        sol{mnth} = solve_lpB(s,d,N,params,price);
       
    end
    
    % save to file
    save(fullfile('resultsB',sprintf('N%d',N)),'sol')

end
