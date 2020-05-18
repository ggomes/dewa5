clear
% close all

load dataSolar
T  = cell2table(cell(0,4), 'VariableNames', {'N','Xs','Xb','irr'});

c=0;
files = dir('resultsB');
for i=1:numel(files)
    
    file = files(i);
    
    if file.isdir
        continue
    end
    
    c = c+1;
    
    if c>10
        break
    end
    
    % load from file
    load(fullfile(file.folder,file.name))
    N = str2double(file.name(2:end-4))
    Ns(c) = N;
    
    % Compute yearly roi ............................
    % The returns on investments are the differences between the net income with the panels
    % and the net income without the panels. 
    % With panels, the net income is revenues - expenditures. These are the cost function of the optimization problem. 
    % Wtihout panels, we assume zero revenues, and that we must buy all electricity from the grid.    

    % Compute net income with panels
    net_with_panels = sum( cellfun( @(x) x.revenues , sol) );
   
    % Compute the net income without panels
    net_without_panels = 0;
    for mnth=1:12
        
        psell = sol{mnth}.price.psell;
        pbuy  = sol{mnth}.price.pbuy;
        peak1 = sol{mnth}.price.peak1;
        peak2 = sol{mnth}.price.peak2;
        peak3 = sol{mnth}.price.peak3;
        d = sol{mnth}.d;
        
        net_without_panels = net_without_panels ...
                - sum(pbuy.*d) ...
                - norm(peak1.*d,Inf) ...
                - norm(peak2.*d,Inf) ...
                - norm(peak3.*d,Inf);
    end
    
    yearly_roi = net_with_panels - net_without_panels;

% This is essentially the code that was provided. 
% It is simplified by removing superfluous code and shortening the variable names. 
% if false  
%     rev_demand=0;
%     rev_customer=0;
%     for mnth=1:12
%         
%         alpha = EC{mnth};
%         beta1 = PC1{mnth};
%         beta2 = PC2{mnth};
%         beta3 = PC3{mnth};
%         
%         d = sol{mnth}.d;
%         gd = sol{mnth}.gd;
%         Xs = sol{mnth}.Xs;
%         Xb = sol{mnth}.Xb;
%         
%         % money spent on buying energy from the grid
%         grid_expense(mnth)  = 1.05*(alpha/4)*Xb;
% 
%         % money made from selling energy to the grid
%         grid_revenue(mnth) = (alpha/4)*Xs;
% 
%         % This is the difference between our peak charges without solar and with solar.
%         rev_demand = rev_demand ...
% 		+ norm(beta1'.*d,Inf)-norm(beta1'.*Xb,Inf) ...
% 		+ norm(beta2'.*d,Inf)-norm(beta2'.*Xb,Inf) ...
% 		+ norm(beta3'.*d,Inf)-norm(beta3'.*Xb,Inf);
% 
%         % WHAT DOES THIS REPRESENT?
%         rev_customer = rev_customer + (alpha/4)*gd;
%        
%     end
% 
%     % WHY ARE WE SUMMING grid_expense and grid_revenue?
%     rev_grid = min( sum(grid_expense) , sum(grid_revenue) );
%     yearly_roi = rev_demand + rev_customer + rev_grid;
% end
    
    
    % compute IRR
    cashFlow = [-5.50*1000*25*sqrt(N) - 24*200*sqrt(N) ... % initial investment
		repmat(yearly_roi,1,10)];
    IRR = irr_dewa(cashFlow);

    % save to table
    tots =  N*sum(cellfun(@(x) sum(x.s),sol));
    totXs = sum(cellfun(@(x) sum(x.Xs),sol));
    totXb = sum(cellfun(@(x) sum(x.Xb),sol));
    totd = sum(cellfun(@(x) sum(x.d),sol));
    T = [T;{N,totXs/tots,totXb/totd,IRR}];
end
    
T = sortrows(T)

figure
subplot(211)
plot(T.N,[T.Xs T.Xb],'LineWidth',2)
legend('% sold','% bought')
grid
subplot(212)
plot(T.N,T.irr,'LineWidth',2)
legend('irr')
grid
xlabel('N')
