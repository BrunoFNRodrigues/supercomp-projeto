#include <iostream>
#include <vector>
#include <algorithm>
#include <random>
#include <chrono>
#include <fstream>
#include <time.h>
#include <omp.h>

using namespace std;

//declaracao a struct para os filmes
struct filme{
    int id;
    int inicio;
    int fim;
    int categoria;
};

int melhorMaratona(int t, vector<filme> filmes, vector<int> dia, vector<int> categorias, vector<filme>& usado, vector<filme>& melhor){
    int tempo = 0;
    int sem_i = 0, com_i = 0;
    vector<filme> filmes2 = filmes;
    if(filmes.empty() || t == 0){
        return 0;
    }

    if(filmes[0].fim > filmes[0].inicio){
        if(categorias[filmes[0].categoria-1] != 0){
            if(t - abs(filmes[0].fim - filmes[0].inicio) >= 0){
                if(count(dia.begin()+filmes[0].inicio, dia.end()-(24-filmes[0].fim), 0) == (filmes[0].fim - filmes[0].inicio)){
                    usado.push_back(filmes[0]);
                    for (int i = filmes[0].inicio; i < filmes[0].fim; i++)
                    {
                        dia[i] = filmes[0].id;
                    }
                    // diminui a quantidade de filmes que ainda podem ser colocadas naquela categoria
                    categorias[filmes[0].categoria-1]--;
                    tempo = filmes[0].fim - filmes[0].inicio;
                    filmes.erase(filmes.begin());
                    com_i = melhorMaratona(t-tempo, filmes, dia, categorias, usado, melhor);
                }
            }
        }
    }


    filmes2.erase(filmes2.begin());
    sem_i = melhorMaratona(t, filmes2, dia, categorias, usado, melhor);

    int valor_atual = usado.size();
    int valor_melhor = melhor.size();


    if (valor_atual > valor_melhor){
        melhor = usado;
    }

    usado.clear();
    return max(sem_i, com_i+tempo);
}

int main(int argc, char *argv[]){


    // vetor de categorias
    vector<int> categorias;
    // vetor com todos os filmes
    vector<filme> lista, maratona, usado, melhor;

    // quantidade de filmes e categorias 
    int n = 0;
    int c = 0;
    // varicavel para a leitura dos limetes por categorias
    int catn;

    // le a primeira linha do arquivo e atribui os valores de quantidade de filmes e categorias
    cin >> n >> c;

    // loop que le o limite de cada categoria e salva do vetor categorias
    for (int i = 0; i < c; i++){
        cin >> catn;
        categorias.push_back(catn); 
    }

    // horario de inicio, fim e a categoria do filme
    int inicio, fim, categoria;

    // le uma linha correspondente a um filme até chegar no valor que foi passado na primeira linha do arquivo
    for (int i = 0; i < n; i++){
        cin >> inicio >> fim >> categoria;
        // realiza o ajuste horario caso um filme acaba em horario menor que o de inicio para ele acabar as 24
        if (fim < inicio){
            lista.push_back({i+1, inicio, 24, categoria});
        } else {
            lista.push_back({i+1, inicio, fim, categoria});
        }
    }

    // ordena a lista com base no horario de fim dos filmes sendo do menor para o maior
    sort(lista.begin(), lista.end(), [](auto& i, auto& j){return i.fim < j.fim;});

    // vetor que serve para alocar os filmes em um espaço de 24 horas
    vector<int> dia(24, 0);
    int t = 24;
    // inicia a contagem do tempo de execução
    double exec_t = omp_get_wtime();

    int num_threads = 8; // número desejado de threads paralelas

    vector<vector<filme>> resultados(num_threads); // vetor de vetores para armazenar os resultados de cada thread

    // Paralelize a chamada da função melhorMaratona usando OpenMP
    #pragma omp parallel num_threads(num_threads)
    {
        // Divida o número total de elementos entre as threads
        int chunk_size = lista.size() / num_threads;
        int chunk_remainder = lista.size() % num_threads;
        int thread_id = omp_get_thread_num();

        // Calcule os índices de início e fim para a thread atual
        int thread_start = thread_id * chunk_size;
        int thread_end = thread_start + chunk_size;

        // A última thread lida com qualquer resto de elementos
        if (thread_id == num_threads - 1)
            thread_end += chunk_remainder;

        // Vetores locais para cada thread
        vector<int> thread_dia(24, 0);
        vector<filme> thread_usado, thread_melhor;

        // Chamada paralela da função melhorMaratona para cada thread
        melhorMaratona(t, vector<filme>(lista.begin() + thread_start, lista.begin() + thread_end),
                                              thread_dia, categorias, thread_usado, thread_melhor);

        // Armazena o resultado parcial da thread no vetor de resultados
        resultados[thread_id] = thread_melhor;
    }

    // termina de contar o tempo de execucao
    exec_t = omp_get_wtime() - exec_t;
 
    // realiza o output grafico de como ficaram alocados os filmes
    cout << "[ ";
        for(auto& el:dia){
    cout << el  <<" ";
    }
    cout << "]" << endl;

    //Une todos os filmes selecionados em um unico vetor
    vector<filme> resultado;
    for (auto& el:resultados){
        resultado.insert(resultado.end(), el.begin(), el.end());
    }
    // melhor alocação entre os filemes selecionados nas threads
    melhorMaratona(t, resultado, dia, categorias, usado, melhor);

    // realiza o output dos filmes que foram selecionados
    for (auto& el:melhor){
        cout << el.id << " ";
    }
 
    cout << endl << "Tempo de execução: " << exec_t << " segundos" << endl;
    cout << endl;

    // salvo os valoresde quantidade de filmes, quantidade de categorias, tempo nao alocado, tempo de execucao e quantidade de filmes alocados 
    // em um arquivo csv
    string arquivo = argv[1];
    ofstream file;
    file.open ("./../resultados/"+arquivo+".csv", ios_base::app);
    file << to_string(n)+","+to_string(c)+","+to_string(t)+","+to_string(exec_t)+","+to_string(melhor.size()) << endl;
    file.close();

}