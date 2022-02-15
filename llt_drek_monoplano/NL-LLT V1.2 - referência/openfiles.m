function [airfoildata] = openfiles(airfoil)
% openfiles - V1.2

% INPUT: nome do perfil (string) - lembrar de colocar aspas simples ('optfoilB2')
% OUTPUT: C�lula cuja primeira linha s�o os n�meros de Reynolds e a segunda linha s�o os dados (Cl x alpha)
% Lembrando que o comando cell2mat converte a c�lula para matriz (�til para manipular dados)

% Convers�o de tipo de vari�vel - char (int) (tabela ASCII) (obs: os valores variam com o caps lock)
% R (82) E (69)
% f (102) i (105) m (109)

% strcat � uma fun��o que concatena horizontalmente strings ('perfil' + '.txt')
% fopen vai abrir o .txt do perfil solicitado
airfoilfile = fopen(strcat(airfoil,'.txt'));

cont_reynolds = 0;  % Vari�vel auxiliar que serve pra terminar o la�o de repeti��o mestre
cont = 0;           % Contador que serve para separar as informa��es entre Reynolds
airfoildata = {};   % C�lula de output (pr� alocar ela no futuro!)

while cont_reynolds == 0
    % fscanf l� a linha do arquivo aberto; Aqui, a fun��o est� tentando
    % achar 'RE', onde a vari�vel %f ser� o numero de reynolds
    string_reynolds = fscanf(airfoilfile,'%s %f',[1 2]);
    
    if isempty(string_reynolds) == 0
        if string_reynolds(1) == 82
            % �ngulo final do Cl x alpha. Assim, � poss�vel saber quando os dados chegam no final
            angulo_aux = fscanf(airfoilfile,'%s %f',[1 2]);
            angulo_maximo = angulo_aux(end);
            Cm0_aux = fscanf(airfoilfile,'%s %f',[1 2]);
            Cm0 = Cm0_aux(end);
            cont = cont + 1;
            % N�mero de Reynolds dos dados
            airfoildata{1,cont} = string_reynolds(end);
            cont_data = 0;
            data_vetor = [];
            while cont_data == 0
                data_aux = fscanf(airfoilfile,'%f %f',[1 2]);
                % Aloca��o dos dados Cl x alpha em um vetor auxiliar (pr� aloc�-lo no futuro!)
                data_vetor(end+1,:) = [data_aux(1),data_aux(2)]; 
                if data_aux(1) == angulo_maximo
                    airfoildata{2,cont} = data_vetor;
                    airfoildata{3,cont} = Cm0;
                    cont_data = 1;
                end
            end
        end
    else
        cont_reynolds = 1;
    end
end
% Fechar a vari�vel que representa o arquivo do perfil
fclose(airfoilfile);
end