#include <iostream>
#include <vector>
#include <algorithm>
#include <chrono>
#include <fstream>
#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/sequence.h>
#include <thrust/execution_policy.h>

 using namespace std::chrono;

void reportTime(const char* msg, steady_clock::duration span);

int main(int argc, char *argv[]){
     steady_clock::time_point ts, te;

    // quantidade de filmes e categorias 
    int N = 0;
    int M = 0;

    // le a primeira linha do arquivo e atribui os valores de quantidade de filmes e categorias
    std::cin >> N >> M;

    // Carregar os dados do arquivo de entrada na memória da GPU
    thrust::device_vector<int> start_times(N);
    thrust::device_vector<int> end_times(N);
    thrust::device_vector<int> categories(N);
    thrust::device_vector<int> L(M);   
    
    // varicavel para a leitura dos limetes por categorias
    int catn;

    // loop que le o limite de cada categoria e salva do vetor categorias
    for (int i = 0; i < M; i++){
        std::cin >> catn;
        L[i] = catn; 
    }

    // horario de inicio, fim e a categoria do filme
    int inicio, fim, categoria;

    // le uma linha correspondente a um filme até chegar no valor que foi passado na primeira linha do arquivo
    for (int i = 0; i < N; i++){
        std::cin >> inicio >> fim >> categoria;
        // realiza o ajuste horario caso um filme acaba em horario menor que o de inicio para ele acabar as 24
        start_times[i] = inicio;
        end_times[i] = fim;
        categories[i] = categoria;
    }

    // Criar a matriz de programação dinâmica
    thrust::device_vector<int> dp((N+1) * (M+1), 0);

    // Inicializar a primeira linha da matriz com zeros
    thrust::fill(dp.begin(), dp.begin() + M + 1, 0);
    
    ts = steady_clock::now();
    // Preencher a matriz com as soluções para subproblemas menores
    for (int i = 1; i <= N; i++) {
        for (int j = 1; j <= M; j++) {
            // Encontrar o número máximo de filmes que podem ser assistidos até o filme i e categoria j
            int max_count = 0;
            for (int k = 0; k < i; k++) {
                if (categories[k] == j && end_times[k] <= start_times[i] && dp[(k*(M+1)) + j-1] + 1 <= L[j-1]) {
                    max_count = max(max_count, dp[(k*(M+1)) + j-1] + 1);
                } else {
                    max_count = max(max_count, dp[(k*(M+1)) + j]);
                }
            }
            dp[(i*(M+1)) + j] = max_count;
        }
    }

    // Encontrar o número máximo de filmes que podem ser assistidos
    int max_count = 0;
    for (int j = 1; j <= M; j++) {
        max_count = max(max_count, dp[(N*(M+1)) + j]);
    }

    te = steady_clock::now();
    std::cout << "," << N << "," << M << "," << 0 << "," << reportTime("Tempo para calculo", te - ts) << "," << max_count << std::endl;

    // salvo os valoresde quantidade de filmes, quantidade de categorias, tempo nao alocado, tempo de execucao e quantidade de filmes alocados 
    // em um arquivo csv
    string arquivo = argv[1];
    ofstream file;
    file.open ("./../resultados/"+arquivo+".csv", ios_base::app);
    file << "," << std::to_string(N) << "," << std::to_string(M) << "," << "0" << "," << std::to_string(reportTime("Tempo para calculo", te - ts)) << "," << std::to_string(max_count) << std::endl;
    file.close();
}

void reportTime(const char* msg, steady_clock::duration span) {
    auto ms = duration_cast<milliseconds>(span);
    std::cout << msg << " - levou - " <<
    ms.count() << " milisegundos" << std::endl;
}