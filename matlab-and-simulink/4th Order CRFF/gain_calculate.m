

%% Input params
fs_mod = 128e3;
order = 4;  % Fourth order
OSR = 64;   % OSR
nLev = 15;  % Number of quantizer levels
f0 = 0;     % Center frequency
OBG = 5;    % OBG

%% Synthesize the initial design
H = synthNTF(order, OSR, OBG, 0); 

%% Find the coefficients a,g,b,c. 
[a,g,b,c] = realize_NTF(H);
% Use only single feed-in
b(2:end) = 0;

%% Find ABCD Matrix
ABCD = stuff_ABCD(a,g,b,c);

fprintf(1,'\n Modulator NTF mapped to CRFF architecture \n');
fprintf(1,'   DAC feedback coefficients (a) = ');
for l=1:order
    fprintf(1,' %.6f',a(l));
end
fprintf(1,'\n   feed-in coefficients (b) = ');
for l=1:order+1
    fprintf(1,' %.6f',b(l));
end
fprintf(1,'\n   resonator feedback coefficients (g) = ');
for l=1:order/2
    fprintf(1,' %.6f',g(l));
end
fprintf(1,'\n   interstage coefficients (c) = ');
for l=1:order
    fprintf(1,' %.6f',c(l));
end
fprintf(1,'\n');



% Calculate NTF and STF with quantizer gain of 1
% ABCD Matrix in not range scaled
[NTF, STF] = calculate_TF(ABCD, 1);

% Find L0 and L1
L0 = STF/NTF;
L1 = (1/NTF)-1;

function ntf = synthNTF(order,osr,H_inf,f0)


    if f0~=0        % Bandpass design-- halve the order temporarily.
        order = order/2;
        dw = pi/(2*osr);
    else
        dw = pi/osr;
    end

    % Use optzeros 
    z = dw * optzeros(order);
    
    if isempty(z)
        ntf = [];
        return;
    end

    if f0~=0        % Bandpass design-- shift and replicate the zeros.
        order = order*2;
        z = sort(z) + 2*pi*f0;
        ztmp = [ z'; -z' ];
        z = ztmp(:);
    end
    z = exp(1i*z);

    zp = z(angle(z)>0);
    x0 = (angle(zp)-2*pi*f0) * osr / pi;

    ntf = zpk(z,zeros(1,order),1,1);
    Hinf_itn_limit = 100;

    % Loop for pole optimization (H_inf)
    opt_iteration = 1; 
    
    while opt_iteration > 0
        % Iteratively determine the poles by finding the value of the x-parameter
        % which results in the desired H_inf.
        ftol = 1e-10;
        if f0>0.25
            z_inf=1;
        else
            z_inf=-1;
        end
        if f0 == 0          % Lowpass design
            HinfLimit = 2^order; 
            if H_inf >= HinfLimit
                fprintf(2,'%s warning: Unable to achieve specified Hinf.\n', mfilename);
                fprintf(2,'Setting all NTF poles to zero.\n');
                ntf.p = zeros(order,1);
            else
                x=0.3^(order-1);    % starting guess
                for itn=1:Hinf_itn_limit
                    me2 = -0.5*(x^(2./order));
                    w = (2*(1:order)'-1)*pi/order;
                    mb2 = 1+me2*exp(1i*w);
                    p = mb2 - sqrt(mb2.^2-1);
                    out = find(abs(p)>1);
                    p(out) = 1./p(out); % reflect poles to be inside the unit circle.
                    p = cplxpair(p);
                    ntf.z = z;  ntf.p = p;
                    f = real(evalTFxn(ntf,z_inf))-H_inf;
                    
                    if itn==1
                        delta_x = -f/100;
                    else
                        delta_x = -f*delta_x/(f-fprev);
                    end
                    
                    xplus = x+delta_x;
                    if xplus>0
                        x = xplus;
                    else
                        x = x*0.1;
                    end
                    fprev = f;
                    if abs(f)<ftol || abs(delta_x)<1e-10
                        break;
                    end
                    if x>1e6
                        fprintf(2,'%s warning: Unable to achieve specified Hinf.\n', mfilename);
                        fprintf(2,'Setting all NTF poles to zero.\n');
                        ntf.z = z;  ntf.p = zeros(order,1);
                        break;
                    end
                    if itn == Hinf_itn_limit
                        fprintf(2,'%s warning: Danger! Iteration limit exceeded.\n',...
                            mfilename);
                    end
                end
            end
        else                % Bandpass design.
            x = 0.3^(order/2-1);    % starting guess (not very good for f0~0)
            c2pif0 = cos(2*pi*f0);
            for itn=1:Hinf_itn_limit
                e2 = 0.5*x^(2./order);
                w = (2*(1:order)'-1)*pi/order;
                mb2 = c2pif0 + e2*exp(1i*w);
                p = mb2 - sqrt(mb2.^2-1);
                % reflect poles to be inside the unit circle.
                out = find(abs(p)>1);
                p(out) = 1./p(out);
                p = cplxpair(p);
                ntf.z = z;  ntf.p = p;
                f = real(evalTFxn(ntf,z_inf))-H_inf;
                
                if itn==1
                    delta_x = -f/100;
                else
                    delta_x = -f*delta_x/(f-fprev);
                end
                
                xplus = x+delta_x;
                if xplus > 0
                    x = xplus;
                else
                    x = x*0.1;
                end
                fprev = f;
                if abs(f)<ftol || abs(delta_x)<1e-10
                    break;
                end
                if x>1e6
                    fprintf(2,'%s warning: Unable to achieve specified Hinf.\n', mfilename);
                    fprintf(2,'Setting all NTF poles to zero.\n');
                    p = zeros(order,1);
                    ntf.p = p;
                    break;
                end
                if itn == Hinf_itn_limit
                    fprintf(2,'%s warning: Danger! Hinf iteration limit exceeded.\n',...
                        mfilename);
                end
            end
        end
        
        % End of loop logic.
        opt_iteration = 0;
    end
end


% NTF -> State-Space (CRFF Realization)
function [a,g,b,c] = realize_NTF(ntf)

ntf_p = ntf.p{1};
ntf_z = ntf.z{1};
order = length(ntf_p);
order2 = floor(order/2);
odd = order - 2*order2;

a = zeros(1,order);
g = zeros(1,order2);
b = [1 zeros(1,order-1) 1]; % CRFF feed-ins
c = ones(1,order);

% Ensure zeros are correctly located
if any(abs(real(ntf_z)-1) > 1e-3)
    ntf_z = 1 + 1i*imag(ntf_z);
end

for i=1:order2
    g(i) = imag(ntf_z(2*i-1+odd))^2;
end

% Select points in z-plane
N = 200;
minDist = 0.09;
zSet = [];
for i=1:N
    z = 1.1*exp(2j*pi*i/N);
    if all(abs(ntf_z - z) > minDist)
        zSet = [zSet; z];
    end
end

% Solve a*T = -L1
L1 = zeros(1,2*order);
T  = zeros(order, 2*order);

for i = 1:2*order
    z = zSet(i);
    L1(i) = 1 - evalRP(ntf_p,z)/evalRP(ntf_z,z);
    Dfactor = (z-1);

    if odd
        product = 1/(z-1);
        T(1,i) = product;
    else
        product = 1;
    end

    for j = odd+1 : 2 : order-1
        product = product / evalRP(ntf_z(j:j+1),z);
        T(j,i)   = product*Dfactor;
        T(j+1,i) = product;
    end
end

a = -real(L1/T);

end



% Build ABCD Matrix (CRFF Structure)
function ABCD = stuff_ABCD(a,g,b,c)

order = length(a);
odd = rem(order,2);
ABCD = zeros(order+1, order+2);

if length(b)==1
    b = [b zeros(1,order)];
end

ABCD(:,order+1) = b';
ABCD(1,order+2) = -c(1);

diagIdx = 1:(order+2):order*(order+1);
ABCD(diagIdx) = 1;

subdiag = diagIdx(1:order-1) + 1;
ABCD(subdiag) = c(2:end);

supdiag = diagIdx((2+odd):2:order) - 1;
ABCD(supdiag) = -g;

ABCD(order+1,1:order) = a;

end



% Compute STF + NTF from ABCD matrix
function [ntf,stf] = calculate_TF(ABCD,k)

if nargin < 2 || isnan(k), k = 1; end

[A,B,C,D] = partABCD(ABCD);

if size(B,2) > 1
    B1 = B(:,1); B2 = B(:,2);
else
    B1 = B;     B2 = B;
end

Acl = A + k*B2*C;
Bcl = [B1 + k*B2*D(1), B2];
Ccl = k*C;
Dcl = [k*D(1) 1];

sys_cl = ss(Acl,Bcl,Ccl,Dcl,1);
tol = min(1e-3,max(1e-6,eps^(1/(size(ABCD,1)))));
tfs = zpk(sys_cl);
mtfs = minreal(tfs,tol);

stf = mtfs(1);
ntf = mtfs(2);

end 

function optZeros = optzeros(n)
% Returns the zeros which minimize in-band noise power.

switch n
    case 1
        optZeros = 0;
    case 2
        % 2nd Order Optimized
        optZeros = sqrt(1/3);
    case 3
        optZeros = [sqrt(3/5) 0];
    case 4
        % 4th Order Optimized
        discr = sqrt(9./49 - 3./35);
        tmp = 3./7;
        optZeros = sqrt([tmp+discr tmp-discr]);
    case 5
        % 5th Order Optimized
        discr = sqrt(25./81 - 5./21);
        tmp = 5./9;
        optZeros = sqrt([tmp+discr tmp-discr 0]);
    otherwise
        fprintf(1,'Error: ds_optzeros_custom only supports orders 1 through 5.\n');
        optZeros = [];
        return;
end

% Sort the zeros and replicate them (create +/- pairs)
z = sort(optZeros);
optZeros = zeros(n,1);
m = 1;

% Handle odd order (one zero at DC)
if(rem(n,2)==1)
    optZeros(1) = z(1);
    z = z(2:length(z));
    m = m+1;
end

% Handle pairs
for i = 1:length(z)
    optZeros(m)   =  z(i);
    optZeros(m+1) = -z(i);
    m = m+2;
end

end


function h = evalTFxn(tf,z)

if isobject(tf)		% zpk object
    if strcmp(class(tf),'zpk')
	h = tf.k * evalRP(tf.z{1},z) ./ evalRP(tf.p{1},z);
    else
	fprintf(1,'%s: Only zpk objects supported.\n', mfilename);
    end
elseif any(strcmp(fieldnames(tf),'form'))
    if strcmp(tf.form,'zp')
	h = tf.k * evalRP(tf.zeros,z) ./ evalRP(tf.poles,z);
    elseif strcmp(tf.form,'coeff')
	h = polyval(tf.num,z) ./ polyval(tf.den,z);
    else
	fprintf(1,'%s: Unknown form: %s\n', mfilename, tf.form);
    end
else	% Assume zp form
    h = tf.k * evalRP(tf.zeros,z) ./ evalRP(tf.poles,z);
end
end

function y = evalRP(roots,x,k)
%Compute the value of a polynomial which is given in terms of its roots.
if(nargin<3)
    k=1;
end

y = k(ones(size(x)));
roots = roots(~isinf(roots));        % remove roots at infinity
for(i=1:length(roots))
    y = y.*(x-roots(i));
end
end
function [A, B, C, D] = partABCD(ABCD, m)
% function [A B C D] = partABCD(ABCD, m); Partition ABCD into
% A, B, C, D for an m-input state-space system.
if nargin<2
    n = min(size(ABCD))-1;
    m = size(ABCD,2)-n;
else
    n = size(ABCD,2)-m;
end
r = size(ABCD,1)-n;

A = ABCD(1:n, 1:n);
B = ABCD(1:n, n+1:n+m);
C = ABCD(n+1:n+r, 1:n);
D = ABCD(n+1:n+r, n+1:n+m);
end