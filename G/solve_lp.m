function X=solve_lp(s,d,N,params,price)

% number of 15-minute intervals in this month
T = size(s,2);

% Define problems variables
B       = sdpvar(T+1,1);
b_in   	= sdpvar(T,1);
b_out 	= sdpvar(T,1);
g      	= sdpvar(T,1);
gd      = sdpvar(T,1);
Xb      = sdpvar(T,1);
Xs      = sdpvar(T,1);

% contstraints .......................................

% Node 1
constr = s(:) + b_out(:) == b_in(:) + g(:);
        
% battery state equation
for t = 1:T
    constr = constr + ( B(t+1)==B(t)+params.gamma*b_in(t)-b_out(t) );
end

% Node 2
constr = [constr N*g(:) == gd(:) + Xs(:)];

% Node 3
constr = [constr d(:) == Xb(:) + gd(:)];


% Upper bounds
constr = [constr ...
    B(:)<=params.max_B ...
    b_in(:)<=params.max_bin ...
    b_out(:)<=params.max_bout ...
    gd(:) <= params.max_gd ...
];

% positivity
constr = [constr ...
    B(:)>=0 ...
    b_in(:)>=0 ...
    b_out(:)>=0 ...
    g(:)>=0 ...
    gd(:)>=0 ...
    Xb(:)>=0 ...
    Xs(:)>=0 ...
];

% Initial condition
constr = [constr B(1)==0];

% objective .......................................
revenues = sum( price.psell.*Xs(:) ) ...
         - sum( price.pbuy.*Xb(:) ) ...
         - norm(price.peak1.*Xb(:),Inf) ...
         - norm(price.peak2.*Xb(:),Inf) ...
         - norm(price.peak3.*Xb(:),Inf);

% solve .......................................
options = sdpsettings('solver','linprog');
optimize(constr,-revenues,options);

% package everything and return
X.revenues = value(revenues);
X.B     = value(B(1:end-1));
X.b_in  = value(b_in);
X.b_out = value(b_out);
X.g     = value(g);
X.gd    = value(gd);
X.Xb    = value(Xb);
X.Xs    = value(Xs);
X.s     = s';
X.d     = d';
X.N     = N;
X.params = params;
X.price = price;
