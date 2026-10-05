# PR2: Práctica integrada de depuración

## Introducción

Esta actividad integra las estrategias de depuración trabajadas en PF1, PF2 y GDB. Se utilizarán test cases para reproducir un fallo de cálculo y un error de ejecución, observar los valores involucrados y comprobar las correcciones realizadas.

Cada problema se investigará mediante trazas enviadas a `stderr` y mediante GDB. Ambas técnicas se utilizarán sobre la misma entrada y la misma versión del programa. El objetivo es comparar la evidencia obtenida antes de corregir el código y comprender qué información aporta cada técnica para investigar un mismo problema.

### Prerrequisitos

- Haber completado PF1, PF2 y GDB
- Saber compilar programas en C con warnings estrictos y símbolos de depuración
- Saber editar código con Vim y ejecutar una suite de test cases
- Saber enviar trazas a `stderr` y limitar cuándo se muestran
- Saber detener y avanzar la ejecución con GDB e inspeccionar variables y llamadas activas

### Objetivo general

- Diagnosticar y corregir problemas de un programa en C utilizando trazas y depuración interactiva

### Objetivos específicos

- Distinguir entre un fallo en el resultado y un error de ejecución
- Seguir la evolución de un valor a través de un ciclo y sus funciones auxiliares
- Seleccionar los valores pertinentes para investigar un problema
- Contrastar la evidencia obtenida mediante trazas y GDB con la especificación
- Comprobar las correcciones sin alterar los casos que ya funcionan
- Desactivar la instrumentación antes de realizar la verificación final

### Estructura inicial

```text
workspace/
├── code/
│   └── escuadron.c
├── scripts/
│   ├── check.sh
│   └── tests-run.sh
└── tests/
    ├── test001.in
    ├── test001.expected
    ├── ...
    ├── test005.in
    └── test005.expected
```

El programa inicial compila sin warnings, pero contiene problemas. Los archivos `.in` y `.expected` entregados son correctos y no se deben modificar. El script `tests-run.sh` ejecuta los casos y compara los resultados; `check.sh` permite revisar qué actividades están completas y cuáles permanecen pendientes.

## Contexto

En una base de la Alianza Rebelde se prepara un escuadrón para una misión contra el Imperio. Del total de naves disponibles, las que participarán en la misión se registran como operativas y las demás permanecerán en reserva, disponibles para reemplazar a las que deban regresar a la base. El equipo de mantenimiento debe preparar tanto las naves operativas como las de reserva antes del combate.

Los escudos de deflección de cada nave utilizan celdas de energía. Para preparar las naves, se retiran las celdas gastadas y se reemplazan por otras cargadas. Este procedimiento permite dejar las naves disponibles mucho más rápido que esperar a que las celdas se recarguen.

El equipo de mantenimiento indica dos cantidades para cada nave: la cantidad de celdas base que requieren sus escudos y la cantidad de celdas de emergencia asignadas para la operación. Ambas cantidades pueden variar entre naves. El total asignado a una nave corresponde a la suma de estas cantidades. Todas las naves deben recibir tanto sus celdas base como sus celdas de emergencia, incluso si no participarán inicialmente en la misión.

Para organizar la distribución de las celdas, la base utiliza un programa que genera un informe del escuadrón. El informe debe indicar cuántas naves se registraron, cuántas están operativas y cuántas celdas se necesitan para preparar todas las naves, incluidas las de reserva.

Además, el informe debe mostrar el promedio de celdas asignadas a las naves operativas, considerando tanto las celdas base como las celdas de emergencia de cada una. Las naves que permanecen en reserva no se incluyen en este promedio. El resultado se expresa como un número entero, descartando la parte decimal. También es válido preparar un escuadrón en el que todas las naves permanezcan en reserva; en ese caso, el informe debe mostrar cero como promedio de celdas por nave operativa.

### Entrada y salida

La primera línea contiene la cantidad de naves registradas, entre 1 y 40. A continuación aparece un registro por nave, con tres números enteros en este orden:

```text
<CELDAS_BASE> <CELDAS_EMERGENCIA> <OPERATIVA>
```

- La cantidad de celdas base y la cantidad de celdas de emergencia deben encontrarse entre 0 y 100
- El tercer valor es `1` si la nave está operativa y `0` si permanece en reserva
- El orden de los registros no modifica las reglas de asignación

Por ejemplo, una entrada con dos naves puede ser:

```text
2
8 2 1
6 3 0
```

La primera nave está operativa y recibe diez celdas: ocho celdas base y dos celdas de emergencia. La segunda permanece en reserva y recibe nueve: seis celdas base y tres celdas de emergencia. El informe correspondiente es:

```text
Naves registradas: 2
Naves operativas: 1
Celdas requeridas: 19
Promedio de celdas por nave operativa: 10
```

Todos los test cases de este laboratorio contienen entradas válidas. Al procesarlos, el programa debe finalizar con código de salida cero y no escribir mensajes en `stderr` cuando la depuración esté desactivada.

### Organización del programa

El programa lee y valida cada `RegistroNave`, reúne sus celdas base y de emergencia en una estructura `CeldasNave` y actualiza el `ResumenEscuadron`. Después de procesar todos los registros, reúne los resultados en un `InformeEscuadron` y los imprime.

La cantidad total de celdas calculada para una nave pasa por varias funciones antes de incorporarse al informe. Por ello, observar solo la salida final puede ser insuficiente: se debe identificar en qué etapa el valor deja de coincidir con lo esperado.

La función `myprint` ya está implementada. Como en PF2, recibe una etiqueta, un valor entero y una condición local. La función envía la traza a `stderr` solamente cuando `debug_enabled` es distinto de cero y se cumple la condición local. Se pueden agregar llamadas a esta función sin tener que desarrollarla nuevamente.

## Actividad

### 1. Preparar y observar el programa

#### 1.1. Inspeccionar los archivos

Ingresar a `workspace` y permanecer en este directorio durante la práctica. Revisar `code/escuadron.c`, identificar el ciclo que procesa los registros y ubicar las funciones que actualizan el resumen y preparan el informe. No es necesario comprender todas las funciones antes de comenzar.

#### 1.2. Compilar con símbolos de depuración

Construir el comando para compilar `code/escuadron.c` con `-Wall`, `-Wextra`, `-Werror`, `-std=c11`, `-g` y `-O0`. El ejecutable debe llamarse `escuadron` y quedar dentro de `code`.

#### 1.3. Ejecutar la suite inicial

Agregar permiso de ejecución para el propietario de `scripts/tests-run.sh`. Construir el comando para ejecutar la suite: el script recibe la ruta del ejecutable y la del directorio de tests.

La salida inicial debe ser:

```text
PASS:  test001
PASS:  test002
FAIL:  test003
FAIL:  test004
ERRO:  test005
```

Los dos primeros test cases son controles y deben continuar entregando `PASS`. La investigación se organizará en dos casos. El primero corresponde a un fallo de cálculo que se investigará mediante `test003`. `test004` no presenta un problema diferente: es una validación adicional del mismo cálculo con otros datos y debería entregar `PASS` después de corregir el problema observado en `test003`. El segundo caso corresponde a un error de ejecución que se investigará mediante `test005`.

En cada caso, observar el problema con ambas técnicas, trazas y GDB, antes de modificar la lógica del programa. Se pueden alternar las técnicas para investigar los mismos valores. Al agregar o ajustar trazas, recompilar antes de iniciar otra ejecución o sesión de GDB, de modo que el ejecutable corresponda al código fuente que se está revisando.

### 2. Caso 1: Investigar el fallo de cálculo

#### 2.1. Examinar el problema con `test003`

Revisar `test003.in`, `test003.expected` y el archivo `.out` generado. Comparar los campos del informe e identificar cuáles coinciden y cuál presenta una diferencia. El caso contiene diez registros; no es necesario mostrar trazas para todos ellos con el fin de investigar el problema.

`test004` corresponde a una validación adicional del mismo cálculo con otra combinación de celdas y naves operativas y en reserva. No se debe investigar como un problema independiente: la corrección desarrollada a partir de `test003` debería hacer que ambos test cases entreguen `PASS`.

#### 2.2. Observar con trazas

Activar `debug_enabled` y utilizar `myprint` para observar el número de registro, las cantidades de celdas de la nave y el total acumulado antes y después de la actualización. Utilizar una condición local para limitar los mensajes a los registros pertinentes.

Recompilar y ejecutar con `test003.in`, separando `stdout` y `stderr` para conservar el informe y las trazas en archivos diferentes. Identificar un registro en el que la actualización no coincida con las reglas del contexto y registrar los valores observados, sin corregir todavía el cálculo.

#### 2.3. Observar con GDB

Ejecutar el mismo caso con GDB. Recordar que `<` permite utilizar `test003.in` como entrada del programa, igual que en el laboratorio anterior. Las trazas pueden permanecer activadas mientras se utiliza GDB.

Colocar un breakpoint en la función que actualiza el resumen y avanzar hasta el registro identificado con las trazas. Consultar el registro, las cantidades de celdas y los acumulados mediante `print`. Utilizar `next`, `step` y `finish` según se necesite para seguir el recorrido del dato y observar cómo cambia el total.

#### 2.4. Contrastar la evidencia y corregir

Comparar los valores de las trazas con los observados en GDB para el mismo registro. Explicar en qué etapa se origina la diferencia y qué información aportó cada técnica para identificarla. Corregir el código con Vim, recompilar y ejecutar nuevamente la suite.

Los cuatro primeros test cases deben entregar `PASS`; `test005` todavía debe entregar `ERRO`. Si `test004` continúa entregando `FAIL`, revisar la corrección realizada a partir de `test003` y contrastar nuevamente las trazas con los valores observados en GDB.

### 3. Caso 2: Investigar el error de ejecución

#### 3.1. Observar `test005`

Revisar la entrada y el informe esperado. Confirmar que la entrada es válida y que el programa debe procesarla.

#### 3.2. Observar con trazas

Mantener activado `debug_enabled` y agregar llamadas a `myprint` para seguir la preparación del informe y observar los valores entregados a las funciones auxiliares. Recompilar y ejecutar con `test005.in`, separando el informe y las trazas.

Identificar hasta qué punto avanza el programa antes de detenerse y observar los valores utilizados en la operación siguiente. Si las trazas aún no permiten acotar el origen del error, ajustar su ubicación y repetir la ejecución. Registrar la evidencia sin corregir todavía el problema.

#### 3.3. Observar con GDB

Ejecutar el mismo caso con GDB hasta que el programa se detenga por el error. Utilizar `backtrace`, `frame`, `info args`, `info locals` y `print` para identificar la operación involucrada y el origen de sus valores.

Consultar los mismos argumentos observados en las trazas. GDB permite inspeccionar sus valores directamente en el punto donde se manifiesta el error, mientras que las trazas registran los valores antes de que este ocurra.

#### 3.4. Contrastar la evidencia y corregir

Relacionar la última traza con la línea en la que GDB detiene la ejecución. Comparar los valores obtenidos con ambas técnicas y explicar por qué la operación no puede completarse en este caso.

Contrastar la evidencia con el comportamiento solicitado y corregir la causa del error con Vim. No basta con evitar que el programa se detenga: también debe producir el informe esperado.

Recompilar y comprobar que los cinco test cases entreguen `PASS`. Si alguno sigue entregando `FAIL` o `ERRO`, revisar la información disponible y ajustar la corrección.

### 4. Verificar la actividad

#### 4.1. Desactivar las trazas y repetir la suite

Desactivar globalmente las trazas asignando cero a `debug_enabled`. Las llamadas a `myprint` pueden permanecer en el código. Si se agregaron otros mensajes temporales, retirarlos o desactivarlos.

Recompilar, repetir la suite y comprobar que el programa mantiene los resultados esperados sin emitir trazas a `stderr`.

#### 4.2. Habilitar `check.sh`

Agregar permiso de ejecución para el propietario de `scripts/check.sh`.

#### 4.3. Ejecutar la revisión

Ejecutar `scripts/check.sh` desde `workspace`. El script permite revisar qué actividades están completas y cuáles permanecen pendientes.
