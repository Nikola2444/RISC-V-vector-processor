#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define KERNEL_NUM 8
#define KERNEL_DEPTH 16
#define KERNEL_WIDTH 3
#define KERNEL_HEIGHT 3
#define IFM_WIDTH 100
#define IFM_HEIGHT 100
#define W_WIDTH 10
#define W_HEIGHT 6

double**** allocate4DSpace(int, int, int, int);
double*** allocate3DSpace(int, int, int);
double** alocate2D(int, int);
void convLayer(double***, double***, double****, double*);
void ReLu(double***);
void fullyConnectedLayer(double*, double*, double**, double*);

int main()
{
    srand(time(NULL));

    // Convolutional layer
    double**** F = allocate4DSpace(KERNEL_NUM, KERNEL_WIDTH, KERNEL_HEIGHT, KERNEL_DEPTH);
    double*** IFM = allocate3DSpace(IFM_WIDTH, IFM_HEIGHT, KERNEL_DEPTH);
    double*** OFM = allocate3DSpace(IFM_WIDTH - 2, IFM_HEIGHT - 2, KERNEL_NUM);
    double* b = (double*)malloc(KERNEL_NUM * sizeof(double));
    for(int i = 0; i < KERNEL_NUM; i++)
    {
        b[i] = (float)rand()/RAND_MAX;
        int sign = rand();
        if((sign % 2) == 0)
            b[i] *= -1;
    }
    convLayer(IFM, OFM, F, b);
    ReLu(OFM);

    for(int n = 0; n < KERNEL_NUM; n++)
        for(int w = 0; w < IFM_WIDTH; w++)
            for(int h = 0; h < IFM_HEIGHT; h++)
                    printf("%lf\n", OFM[w][h][n]);

    // Fully connected layer
    double** W = alocate2D(W_WIDTH, W_HEIGHT);
    double* I = (double*)malloc(W_HEIGHT * sizeof(double));
    double* O = (double*)malloc(W_WIDTH * sizeof(double));

    for(int i = 0; i < W_HEIGHT; i++)
    {
        I[i] = (float)rand()/RAND_MAX;
        int sign = rand();
        if((sign % 2) == 0)
            I[i] *= -1;
    }

    double* B = (double*)malloc(W_WIDTH * sizeof(double));
    for(int i = 0; i < W_WIDTH; i++)
    {
        B[i] = (float)rand()/RAND_MAX;
        int sign = rand();
        if((sign % 2) == 0)
            B[i] *= -1;
    }

    fullyConnectedLayer(I, O, W, B);
    return 0;
}

void fullyConnectedLayer(double* I, double* O, double** W, double* B)
{
    for(int x = 0; x < W_WIDTH; x++)
    {
        double sum = 0;
        for(int y = 0; y < W_HEIGHT; y++)
        {
            sum += W[x][y] * I[y];
        }
        O[x] = sum + B[x];
    }
}

double** alocate2D(int W, int H)
{
    double** F = (double**)malloc(W * sizeof(double*));

    if (F == NULL)
    {
        fprintf(stderr, "Out of memory");
        exit(0);
    }

    for (int i = 0; i < W; i++)
    {
        F[i] = (double*)malloc(H * sizeof(double));

        if (F[i] == NULL)
        {
            fprintf(stderr, "Out of memory");
            exit(0);
        }
    }

    for(int w = 0; w < W; w++)
    {
        for(int h = 0; h < H; h++)
        {
            F[w][h] = (float)rand()/RAND_MAX;
            int sign = rand();
            if((sign % 2) == 0)
                F[w][h] *= -1;
        }
    }

    return F;
}

void ReLu(double*** IFM)
{
    for(int n = 0; n < KERNEL_NUM; n++)
        for(int w = 0; w < IFM_WIDTH - 2; w++)
            for(int h = 0; h < IFM_HEIGHT - 2; h++)
                    if(IFM[w][h][n] < 0)
                        IFM[w][h][n] = 0;
}

void convLayer(double*** IFM, double*** OFM, double**** F, double* b)
{
    for(int n = 0; n < KERNEL_NUM; n++)
    {
        for(int x = 0; x < IFM_WIDTH - (KERNEL_WIDTH / 2 + 1); x++)
        {
            for(int y = 0; y < IFM_HEIGHT - (KERNEL_HEIGHT / 2 + 1); y++)
            {
                double sum = 0;

                for(int c = 0; c < KERNEL_DEPTH; c++)
                {
                    for(int kw = 0; kw < KERNEL_WIDTH; kw++)
                    {
                        for(int kh = 0; kh < KERNEL_HEIGHT; kh++)
                        {
                            sum += IFM[x + kw][y + kh][c] * F[n][kw][kh][c];
                        }
                    }
                }
                OFM[x][y][n] = sum + b[n];
            }
        }
    }
}

double**** allocate4DSpace(int N, int W, int H, int D)
{
    double**** F = (double****)malloc(N * sizeof(double***));

    if (F == NULL)
    {
        fprintf(stderr, "Out of memory");
        exit(0);
    }

    for (int i = 0; i < N; i++)
    {
        F[i] = (double***)malloc(W * sizeof(double**));

        if (F[i] == NULL)
        {
            fprintf(stderr, "Out of memory");
            exit(0);
        }

        for (int j = 0; j < W; j++)
        {
            F[i][j] = (double**)malloc(H * sizeof(double*));

            if (F[i][j] == NULL)
            {
                fprintf(stderr, "Out of memory");
                exit(0);
            }

            for(int k = 0; k < H; k++)
            {
                F[i][j][k] = (double*)malloc(D * sizeof(double));

                if (F[i][j][k] == NULL)
                {
                    fprintf(stderr, "Out of memory");
                    exit(0);
                }
            }
        }
    }

    for(int n = 0; n < N; n++)
    {
        for(int w = 0; w < W; w++)
        {
            for(int h = 0; h < H; h++)
            {
                for(int d = 0; d < D; d++)
                {
                    F[n][w][h][d] = (float)rand()/RAND_MAX;
                    int sign = rand();
                    if((sign % 2) == 0)
                        F[n][w][h][d] *= -1;
                }
            }
        }
    }

    return F;
}

double*** allocate3DSpace(int W, int H, int D)
{
    double*** F = (double***)malloc(W * sizeof(double**));

    if (F == NULL)
    {
        fprintf(stderr, "Out of memory");
        exit(0);
    }

    for (int i = 0; i < W; i++)
    {
        F[i] = (double**)malloc(H * sizeof(double*));

        if (F[i] == NULL)
        {
            fprintf(stderr, "Out of memory");
            exit(0);
        }

        for (int j = 0; j < H; j++)
        {
            F[i][j] = (double*)malloc(D * sizeof(double));

            if (F[i][j] == NULL)
            {
                fprintf(stderr, "Out of memory");
                exit(0);
            }
        }
    }

    for(int w = 0; w < W; w++)
    {
        for(int h = 0; h < H; h++)
        {
            for(int d = 0; d < D; d++)
            {
                F[w][h][d] = (float)rand()/RAND_MAX;
                int sign = rand();
                if((sign % 2) == 0)
                    F[w][h][d] *= -1;
            }
        }
    }

    return F;
}
