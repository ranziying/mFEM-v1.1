function u = elasticity2_variational(Th,pde,feSpace,quadOrder)
%Elasticity2_variational  
% Conforming Lagrange elements of order up to 3 for linear elasticity equation 
% Variational formulation based programming
%       u = [u1, u2]
%       -div (sigma) = f in \Omega
%       Dirichlet boundary condition u = [g1_D, g2_D] on \Gamma_D
%       Neumann boundary condition   \sigma*n = g  on \Gamma_N
%       \sigma = (sigma_{ij}): stress tensor, 1<=i,j<=2

% Quadrature orders for int1d and int2d
if nargin==2, feSpace = 'P1'; quadOrder = 3; end % default: P1
if nargin==3, quadOrder = 3; end

% ------------------------ Mesh Th --------------------------
 
mu = pde.mu; lambda = pde.lambda; 

% ------------------------ Mesh Th --------------------------
% elem1D associated with Gamma_R
bdStruct = Th.bdStruct;
Th.elem1D = bdStruct.elemN; Th.bdIndex1D = bdStruct.bdIndexN;
% auxstructure
auxT = auxstructure(Th.node,Th.elem);
Th.auxT = auxT;

% ---------------------- Stiffness matrix -----------------------
% (Eij(u):Eij(v))
Coef = { 1, 1, 0.5 }; 
Trial = {'u1.dx', 'u2.dy', 'u1.dy + u2.dx'};
Test  = {'v1.dx', 'v2.dy', 'v1.dy + v2.dx'};
A = int2dvec(Th,Coef,Trial,Test,feSpace,quadOrder);
A = 2*mu*A;

% (div u,div v) 
Coef = { 1 }; 
Trial = { 'u1.dx + u2.dy' };
Test  = { 'v1.dx + v2.dy' };
B = int2dvec(Th,Coef,Trial,Test,feSpace,quadOrder);
B = lambda*B;

% stiffness matrix
kk = A + B;

% -------------------------- Load vector -------------------------
Coef = pde.f;  Test = 'v.val';
ff = int2dvec(Th,Coef,[],Test,feSpace,quadOrder);

% ------------ Neumann boundary condition ----------------
if ~isempty(Th.elem1D)
    g_N = pde.g_N; trg = eye(3);
    
    g1 = @(p) g_N(p)*trg(:,[1,3]);   Cmat1 = getMat1d(g1,Th,quadOrder);
    g2 = @(p) g_N(p)*trg(:,[3,2]);   Cmat2 = getMat1d(g2,Th,quadOrder);
        
    Coef = {Cmat1, Cmat2};  Test = 'v.val';    
    ff = ff + int1dvec(Th,Coef,[],Test,feSpace,quadOrder);
end

% ------------ Dirichlet boundary condition ----------------
stru = 'u.val';
u = Applyboundary2Dvec(Th,kk,ff,pde,stru,feSpace);

