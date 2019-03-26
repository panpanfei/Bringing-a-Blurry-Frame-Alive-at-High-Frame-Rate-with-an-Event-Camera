function Ltv = TVnorm(L,edgemp)
lambda = 0.2;
[~,~,dim] = size(L);
if dim ==3
    L = rgb2gray(L);
end
    

L_x = dxp(L);
L_y = dyp(L);


Ltv = sum(sum(sqrt(L_x.^2 + L_y.^2)));


p_cross = im_edge_crossc(L,edgemp); 
Ltv =  lambda*Ltv - sum(p_cross(:)); % 
end

function [dx] = dxp(u)

dx = [u(:,2:end) u(:,end)] - u;
end
function [dy] = dyp(u)

dy = [u(2:end,:); u(end,:)] - u;
end
