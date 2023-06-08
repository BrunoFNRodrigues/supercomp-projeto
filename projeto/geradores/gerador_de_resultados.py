import sys
import subprocess

# Define o caminho para o arquivo executável das heurísticas
heuristica = "./../heuristicas/maratona_"+sys.argv[1]

# Define o caminho para o arquivo CSV de respostas
resultados = "./../resultados/"+sys.argv[1]+"_"+sys.argv[2]+".csv"

# Adiciona o nome das colunas ao arquivo de resposta
with open(resultados, "w") as f:
    f.write("n_filmes,n_categorias,t_restante,t_execucao,v_filmes\n")
    
# Executa o arquivo várias vezes uma vez para cada quantidade de filmes    
for j in range(1, 31, 1):
    # Executa o arquivo várias vezes uma vez para cada quantidade de categorias
    for i in range(1, int(sys.argv[3])+1):
        # Define os inputs que você deseja passar para o arquivo
        inputs = open("./../inputs_"+sys.argv[2]+"/input_"+str(j)+"_"+str(i)+".txt")
        
        r = subprocess.Popen([heuristica, sys.argv[1]+"_"+sys.argv[2]], stdin = inputs)
        r.wait()