function [data] = data_solver(reynolds_info,airfoil_info,airfoil_data,b,nperfil,aoa,i,tipo)
% V1.2
aoa = aoa*180/pi;
N = size(airfoil_info,1);
b_total = sum(b);
particoes = (size(b,2));
part = zeros(1, particoes);
if particoes > 1
    for i=1:(particoes-1)
        %Distribui��o do n�mero de paineis por parti��o de asa.
        num_part = (b(i)/b_total)*N;                                   %N�mero de paineis em fun��o do comprimento relativo da parti��o
        part(i) = floor(num_part);
    end
    part(end) = N - sum(part);                                             %A �ltima parti��o recebe o n�mero de pain�is restantes
else
    part(end) = N;                                                         %Caso onde existe somente uma parti��o
end

% Encontrar a coluna do perfil em quest�o
if airfoil_info(i) < 1
    aux = 0;
    cont = 1;
    if particoes == 1
        airfoil1 = nperfil(1);
        airfoil2 = nperfil(end);
    else
        achei = 0;
        while achei == 0
            aux = part(cont) + aux;
            if cont > 1
                if aux == i
                    airfoil1 = nperfil(cont);
                    airfoil2 = nperfil(cont+1);
                    achei = 1;
                elseif i < aux && i > aux-part(cont-1)
                    airfoil1 = nperfil(cont);
                    airfoil2 = nperfil(cont+1);
                    achei = 1;
                else
                    cont = cont + 1;
                end
            else
                airfoil1 = nperfil(1);
                airfoil2 = nperfil(2);
                achei = 1;
            end
            
        end
    end
    for k=1:size(airfoil_data,2)
  
        if airfoil1 == airfoil_data{1,k}
            aux1 = k;
        end
        if airfoil2 == airfoil_data{1,k}
            aux2 = k;
        end
    end
    v_coletor1 = airfoil_data{2,aux1};
    data1 = re_solver(reynolds_info(i),v_coletor1,aoa,tipo);
    v_coletor2 = airfoil_data{2,aux2};
    data2 = re_solver(reynolds_info(i),v_coletor2,aoa,tipo);
    data = (data2-data1)*(airfoil_info(i))+data1;
else
    for j=1:size(airfoil_data,2)
        if airfoil_info(i) == airfoil_data{1,j}
            aux = j;
        end
    end
    % Uma vez achado a coluna, � preciso extra�-la para manipular os dados
    v_coletor = airfoil_data{2,aux};
    data = re_solver(reynolds_info(i),v_coletor,aoa,tipo);
end

end