#include <stdio.h>

#define MAXIMO_NAVES 40
#define MAXIMA_CANTIDAD_CELDAS 100

typedef struct
{
    int celdas_base;
    int celdas_emergencia;
    int operativa;
} RegistroNave;

typedef struct
{
    int base;
    int emergencia;
    int total;
} CeldasNave;

typedef struct
{
    int registrados;
    int operativas;
    int celdas_totales;
    int celdas_operativas;
} ResumenEscuadron;

typedef struct
{
    ResumenEscuadron resumen;
    int promedio_operativas;
} InformeEscuadron;

int debug_enabled = 0;

void myprint(const char *etiqueta, int valor, int condicion)
{
    if (debug_enabled && condicion)
    {
        fprintf(stderr, "DEBUG: %s=%d\n", etiqueta, valor);
    }
}

static int leer_cantidad(int *cantidad)
{
    if (scanf("%d", cantidad) != 1)
    {
        return 0;
    }

    return *cantidad > 0 && *cantidad <= MAXIMO_NAVES;
}

static int leer_registro(RegistroNave *registro)
{
    return scanf("%d%d%d",
                 &registro->celdas_base,
                 &registro->celdas_emergencia,
                 &registro->operativa) == 3;
}

static int registro_valido(const RegistroNave *registro)
{
    if (registro->celdas_base < 0
        || registro->celdas_base > MAXIMA_CANTIDAD_CELDAS)
    {
        return 0;
    }

    if (registro->celdas_emergencia < 0
        || registro->celdas_emergencia > MAXIMA_CANTIDAD_CELDAS)
    {
        return 0;
    }

    return registro->operativa == 0 || registro->operativa == 1;
}

static CeldasNave preparar_celdas(const RegistroNave *registro)
{
    CeldasNave celdas = {0};

    celdas.base = registro->celdas_base;
    celdas.emergencia = registro->celdas_emergencia;
    celdas.total = celdas.base + celdas.emergencia;

    return celdas;
}

static int calcular_aporte(const RegistroNave *registro,
                           const CeldasNave *celdas)
{
    int aporte = celdas->total;

    if (!registro->operativa)
    {
        aporte -= celdas->emergencia;
    }

    return aporte;
}

static void registrar_celdas(ResumenEscuadron *resumen,
                             const RegistroNave *registro,
                             const CeldasNave *celdas)
{
    int aporte = calcular_aporte(registro, celdas);

    resumen->registrados++;
    resumen->celdas_totales += aporte;

    if (registro->operativa)
    {
        resumen->operativas++;
        resumen->celdas_operativas += celdas->total;
    }
}

static int procesar_registros(int cantidad, ResumenEscuadron *resumen)
{
    for (int numero = 1; numero <= cantidad; numero++)
    {
        RegistroNave registro = {0};

        if (!leer_registro(&registro) || !registro_valido(&registro))
        {
            return 0;
        }

        CeldasNave celdas = preparar_celdas(&registro);
        registrar_celdas(resumen, &registro, &celdas);
    }

    return 1;
}

static int calcular_promedio(int celdas, int naves)
{
    return celdas / naves;
}

static InformeEscuadron preparar_informe(const ResumenEscuadron *resumen)
{
    InformeEscuadron informe = {0};

    informe.resumen = *resumen;
    informe.promedio_operativas = calcular_promedio(resumen->celdas_operativas,
                                                     resumen->operativas);

    return informe;
}

static void imprimir_informe(const InformeEscuadron *informe)
{
    printf("Naves registradas: %d\n", informe->resumen.registrados);
    printf("Naves operativas: %d\n", informe->resumen.operativas);
    printf("Celdas requeridas: %d\n", informe->resumen.celdas_totales);
    printf("Promedio de celdas por nave operativa: %d\n",
           informe->promedio_operativas);
}

int main(void)
{
    int cantidad = 0;
    ResumenEscuadron resumen = {0};

    if (!leer_cantidad(&cantidad))
    {
        fprintf(stderr, "Error: cantidad de naves invalida\n");
        return 1;
    }

    if (!procesar_registros(cantidad, &resumen))
    {
        fprintf(stderr, "Error: registro de nave invalido\n");
        return 1;
    }

    InformeEscuadron informe = preparar_informe(&resumen);
    imprimir_informe(&informe);

    return 0;
}
