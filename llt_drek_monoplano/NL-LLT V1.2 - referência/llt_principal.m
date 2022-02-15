function [Sw,ARw,CLalphaw,CL0w,MACw,bw,CDi_coeff,Cmacw,xACw,Cl,asa_geometria,airfoil_data] = llt_principal(particoes,b,c,diedro,offset,nperfil,twist,h,Vinf)
% Non-linear lifting line theory - V1.2

%DADOS GERAIS
%particoes: n�mero de parti��es da asa
N = 12; %n�mero de paineis por se��o de uma meia-envergadura

CLalphaw = 0;
CL0w = 0;
CDi_coeff = 0;
Cmacw = 0;
xACw = 0;

enable_autogap = 1;
enable_sweep = 0;

if enable_autogap == 1
    gap = 0.10;
    [particoes_novo,b_novo,c_novo,diedro_novo,offset_novo,nperfil_novo]=llt_autogap(particoes,b,c,diedro,offset,nperfil,gap);
    particoes = particoes_novo;
    b = b_novo;
    c = c_novo;
    diedro = diedro_novo;
    offset = offset_novo;
    nperfil = nperfil_novo;
end

%Dados da corrente livre
nu = 1.5e-5;

aoa = 1:5;
G_vetor = zeros(N,size(aoa,2));
aoa_eff_vetor = zeros(N,size(aoa,2));
coef_forcas = zeros(size(aoa, 2),3);
coef_momentos = zeros(size(aoa,2),3);
Cl = zeros(N,size(aoa,2));


%GEOMETRIA
b_particoes = b;                                                           %Vetor que cont�m as meias-envergaduras das parti��es [m]
bw = sum(b_particoes)*2;                                                   %Envergadura [m]
sweep = zeros(1, particoes);
if enable_sweep == 1
    for i=1:particoes
        sweep(i) = atand( (c(i+1)-c(i)+4*offset(i))/(4*b_particoes(i)) );
    end
end
tw = twist;                                                                %�ngulo de twist geom�trico da �ltima parti��o (0� no in�cio, tw� no final) [�]

[vertices, collocation_points, csi, area, MACw, mac, AR, u_n, u_a, reynolds_info, airfoil_info, cordas] = ...
    llt_geometria(b_particoes,c,offset,tw,diedro,sweep,nperfil,Vinf,nu,particoes,N);


asa_geometria = cell(10,2);
asa_geometria{1,1} = b;
asa_geometria{2,1} = c;
asa_geometria{3,1} = offset;
asa_geometria{4,1} = diedro;
asa_geometria{5,1} = tw;
asa_geometria{6,1} = nperfil;
asa_geometria{7,1} = particoes;
asa_geometria{8,1} = h;
asa_geometria{9,1} = N;

asa_geometria{1,2} = collocation_points;
asa_geometria{2,2} = vertices;
asa_geometria{3,2} = csi;
asa_geometria{4,2} = area;
asa_geometria{5,2} = mac;
asa_geometria{6,2} = u_n;
asa_geometria{7,2} = u_a;
asa_geometria{8,2} = reynolds_info;
asa_geometria{9,2} = airfoil_info;
asa_geometria{10,2} = MACw;

plot_llt(collocation_points,vertices,b,c,offset,particoes)
% Rotina que puxa os perfis a serem utilizados do banco de dados
perfil_aux = nperfil;
for i=1:size(nperfil,2)
    aux1 = nperfil(i);
    for j=i:size(nperfil,2)
        aux2 = nperfil(j);
        if aux1 == aux2 && i~=j
            perfil_aux(j) = 0;
        end
    end
end
airfoil_aux = 0;
for i=1:size(perfil_aux,2)
    if perfil_aux(i) ~= 0
        airfoil_aux(i) = perfil_aux(i);
    end
end
airfoil_data = cell(2,size(airfoil_aux,2));
for i=1:size(airfoil_aux,2)
    if airfoil_aux(i) == 3
        airfoil = 's5020';
    elseif airfoil_aux(i) == 1
        airfoil = 'nacaexp';
    elseif airfoil_aux(i) == 2
        airfoil = 'R24';
    end
    [airfoildata_aux] = openfiles(airfoil);
    airfoil_data{1,i} = airfoil_aux(i);
    airfoil_data{2,i} = airfoildata_aux;
end

referencial = zeros(N, 3);
ca = 0.25*MACw;                                                               %Chute inicial para encontrar posi��o do ca
referencial(:,1) = 0;
ARw = AR;
Sw = 2*sum(area);
%FIM DA DISCRETIZA��O
for i=1:size(aoa, 2)
    aoa_rad = aoa(i)*pi/180;           %Transforma��o para radianos
    Vinf_vetor = Vinf*[cos(aoa_rad) 0 sin(aoa_rad)];
    vinf = Vinf_vetor/Vinf;           %Vetor unit�rio da corrente livre
    
    %Solu��o linear (primeiro vetor de itera��o do sistema n�o linear)
    if i>1
        G = G_vetor(:,i-1);
    else
        if aoa(i) < 10
            G_lin = llt_simplificado(vertices,collocation_points,b,nperfil,csi,vinf,u_n,mac,reynolds_info,airfoil_info,airfoil_data,h,N);
            G = G_lin;                          %Primeira itera��o
        else
            G = ones(N,1);
        end
    end
    %In�cio da solu��o n�o linear
    
    
    damping = 0.1;
    
    convergencia = 1;                      %Vari�vel l�gica de converg�ncia
    cont = 1;                        %Contador pra verificar limite m�ximo de tentativas
    while convergencia == 1
        [R,aoa_eff] = llt_solver1(vertices,collocation_points,csi,b,nperfil,vinf,u_n,u_a,mac,reynolds_info,airfoil_info,airfoil_data,G,h,N);
        deltaG = llt_solver2(vertices,collocation_points,b,nperfil,csi,vinf,u_n,u_a,mac,reynolds_info,airfoil_info,airfoil_data,aoa_eff,G,-R,h,N);
        if cont > 500
            convergencia = 2;
            fprintf('resultado n�o convergiu\n');
        end
        
        if abs(max(R)) < 0.001
            fprintf("aoa: %g\niteracao: %g\n", aoa(i),cont)
            aoa_eff_vetor(:,i) = aoa_eff*180/pi;
            convergencia = 2;
        else
            cont = cont + 1;
            G = G + damping*deltaG;
            G_vetor(:,i) = G;
        end
    end
    [coef_forcas(i, :),coef_momentos(i, :),Cl(:,i)] = llt_coeficientes(vertices,collocation_points,csi,b,nperfil,vinf,area,mac,reynolds_info,airfoil_info,airfoil_data,MACw,u_n,u_a,referencial,G,h,N,aoa(i));
end
coef_forcas;
vetor_q_eu_quero = [aoa' coef_forcas(:,3) coef_forcas(:,1) coef_momentos(:,2)];
a=1;
% aoa_eff_vetor
% % collocation_points
% Cl_aux = Cl;
% for i=1:size(Cl,2)
%     Cl(:,i) = Cl(:,i).*cordas(:)/MACw;
% end
% Cl(:,end+1) = collocation_points(:,2);
% Cl_inverso = zeros(size(Cl,1),size(Cl,2));
% aoa_eff_inverso = zeros(size(aoa_eff_vetor,1),size(aoa_eff_vetor,2));
% for i=1:size(Cl,1)
%     for j=1:size(Cl,2)
%         Cl_inverso(i,j) = Cl(size(Cl,1)+1-i,j);
%     end
% end
%
% for i=1:size(aoa_eff_vetor,1)
%     for j=1:size(aoa_eff_vetor,2)
%         aoa_eff_inverso(i,j) = aoa_eff_vetor(size(aoa_eff_vetor,1)+1-i,j);
%     end
% end


% yo=1
% fugao = 0;
% cont = 0;
% camin = 0.1*MACw;
% camax = 1.5*MACw;
% %Rotina para achar o ca/cmacw (m�todo da bissec��o)
%
% while fugao == 0
%     cont = cont+1;
%     aoa1 = 0;
%     aoa2 = 10;
%     [~,cm1,~] = llt_coeficientes(vertices, collocation_points, csi, vinf, area, mac, MACw, u_n, u_a, referencial, cm, G1, h, N, aoa1);
%     [~,cm2,~] = llt_coeficientes(vertices, collocation_points, csi, vinf, area, mac, MACw, u_n, u_a, referencial, cm, G2, h, N, aoa2);
%     Cmalpha = (cm2(2)-cm1(2))/(aoa2-aoa1);
%     if abs(Cmalpha) <= 0.0001 || cont == 100
%         Cmacw = cm1(2);
%         break
%     end
%     if Cmalpha < 0
%         camin = ca;
%         ca = (ca+camax)/2;
%         referencial(:,1) = ca;
%
%     else
%         camax = ca;
%         ca = (camin+camax)/2;
%         referencial(:,1) = ca;
%     end
%
% end
% Cmacw = 0;
% A = [aoa(1, 1)^2 aoa(1, 1) 1; aoa(1, 2)^2 aoa(1, 2) 1; aoa(1, 3)^2 aoa(1, 3) 1];
% B = [coef_forcas(1, 1); coef_forcas(2, 1); coef_forcas(3, 1)];
% CDi_coeff = linsolve(A, B);
% CL0w = coef_forcas(1, 3);
% CLalphaw = (coef_forcas(2, 3) - coef_forcas(1, 3) )/(aoa(2) - aoa(1) );
% xACw = referencial(1,1)/c(1);   %Em % da corda da ra�z

end