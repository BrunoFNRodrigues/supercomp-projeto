#include <iostream>
#include <vector>
#include <cmath>
#include <algorithm> 
#include <random>
#include <chrono>
#include <stdlib.h> 
#include <stdio.h>
#include <iterator>
#include <random>
#include <chrono>
#include <fstream>
#include <cstdint>
#include <stack>
#include <utility>
#include <map>
#include <ctime>
#include <thrust/host_vector.h>
#include <thrust/sequence.h>
#include <thrust/device_vector.h>
#include <thrust/generate.h>
#include <thrust/functional.h>
#include <thrust/copy.h>


using namespace std;

struct bestMaraton
{  
    int N;
    int M;
    int* L;
    int* start_times;
    int* end_times;
    int* categories;
    bestMaraton(int N_, int M_, int* L_, int* start_times_, int* end_times_, int* categories_) : 
    N(N_), M(M_), L(L_), start_times(start_times_), end_times(end_times_), categories(categories_) {}
    __host__ __device__
    int operator()(const int& com) {
        int L_copy[50];
        for (int i = 0; i < M; i++){
            L_copy[i] = *(L+i);
        }
        int max_count = 0;
        int time = 24;
        for (int i = 1; i < N; i++){
            if (com & (1 << i)){
                if (L_copy[i-1] > 0){
                    if(end_times[i-1] <= start_times[i]){
                        // diminui a quantidade de filmes que ainda podem ser colocadas naquela categoria
                        L_copy[categories[i-1]-1]--;
                        time -= end_times[i-1] - start_times[i-1];
                        max_count++;
                    }
                }
            }
        
        }

        return max_count;
    }
};



int main(int argc, char *argv[]){
    int N, M;
    std::cin >> N >> M;

    thrust::host_vector<int> host_categories(N);
    thrust::host_vector<int> host_start_times(N);
    thrust::host_vector<int> host_end_times(N);
    thrust::host_vector<int> host_L(M);

    for (int i = 0; i < M; i++) {
        std::cin >> host_L[i];
    }

    // horario de inicio, fim e a categoria do filme
    int start, end, categorie;

    for (int i = 0; i < N; i++) {
        std::cin >> start >> end >> categorie;
        host_start_times[i]
        host_end_times[i]
        host_categories[i]
        // realiza o ajuste horario caso um filme acaba em horario menor que o de inicio para ele acabar as 24
        if (end < start){
            end = 24;
        } 
        host_start_times[i] = start;
        host_end_times[i] = end;
        host_categories[i] = categorie;
    }

    thrust::device_vector<int> device_com(pow(2, N));
    thrust::device_vector<int> categories(host_categories);
    thrust::device_vector<int> start_times(host_start_times);
    thrust::device_vector<int> end_times(host_end_times);
    thrust::device_vector<int> L(host_L);

    thrust::sequence(device_com.begin(), device_com.end());

    // inicia a contagem do tempo de execução
    clock_t t = clock();


    thrust::transform(device_com.begin(), device_com.end(), device_com.begin(), bestMaraton(N, M, raw_pointer_cast(L.data()),
    raw_pointer_cast(start_times.data()), raw_pointer_cast(end_times.data()), raw_pointer_cast(categories.data())));
    

    
    thrust::host_vector<int> host_com = device_com;
    
    int max_count = 0;
    int iters = pow(2, N);
    for (int i = 0; i < iters; i++){
        if (host_com[i] > max_count){
            max_count = host_com[i];
        }
    }

    // termina de contar o tempo de execucao
    t = clock() - t;   
    // salvo os valoresde quantidade de filmes, quantidade de categorias, tempo nao alocado, tempo de execucao e quantidade de filmes alocados 
    // em um arquivo csv
    string arquivo = argv[1];
    ofstream file;
    file.open ("./../resultados/"+arquivo+".csv", ios_base::app);
    file << to_string(N)+","+to_string(M)+","+to_string(0)+","+to_string(((float)t)/CLOCKS_PER_SEC)+","+to_string(max_count) << endl;
    file.close();
}