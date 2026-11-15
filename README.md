# 📊 Auditoría de Integridad de Cobros y Performance Logística — Olist E-commerce

![Python](https://img.shields.io/badge/Python-3.13-blue?logo=python)
![SQL](https://img.shields.io/badge/SQL-SQLite%20%7C%20ANSI-orange?logo=sqlite)
![pandas](https://img.shields.io/badge/pandas-2.x-lightgrey?logo=pandas)
![Status](https://img.shields.io/badge/Estado-Completo-success)

**Autor:** Jonathan Monserrat ([@Jmonse](https://github.com/Jmonse))  
**Stack:** Python · SQL (SQLite) · pandas · Matplotlib · Seaborn · OpenPyXL  
**Universo Auditado:** 99.441 órdenes · 103.886 registros de pago · Dataset público Olist Brasil (Kaggle)

---

## 🎯 Resumen Ejecutivo

Este proyecto aplica reglas de control interno y auditoría financiera sobre 99.441 órdenes reales del marketplace Olist (Brasil) mediante **SQL (SQLite) y Python**. El objetivo es detectar fugas de cobro, cuantificar saldos de anticipos al cierre mensual y medir el cumplimiento real de plazos de entrega (SLA) por estado sin sesgos de volumen. El entregable final automatiza un reporte ejecutivo en Excel de 5 pestañas listo para revisión operativa.

---

## 🧠 Enfoque de Auditoría y Pruebas Sustantivas

1. **Integridad de Cobros (Pruebas 1A y 1B):** Cruce relacional (`LEFT JOIN`) entre órdenes entregadas y registros de pago para aislar entregas sin respaldo financiero y transacciones con importes nulos o $\le 0$.
2. **Exposición por Cancelaciones (Prueba 2):** Cuantificación de órdenes en estado `canceled` o `unavailable` que registran cobros efectivos, determinando el monto sujeto a conciliación contra devoluciones emitidas.
3. **Corte Patrimonial al Cierre Mensual (Prueba 3):** Determinación del stock de órdenes aprobadas hasta el último día de cada mes calendario y aún pendientes de entrega a esa fecha (saldo de anticipos de clientes al cierre).
4. **Performance Logística y SLA Normalizado (Prueba 4):** Evaluación de tasa de incumplimiento de fecha prometida (`delivered > estimated`) y demora estructural ($>30$ días) sobre órdenes efectivamente entregadas (`96.470`), aplicando un umbral muestral de $n \ge 100$ por estado para evitar distorsiones por bajo volumen.

---

## 📈 Hallazgos Clave Auditados

| Prueba / Indicador | Resultado Verificado | Observación Técnica |
| :--- | :--- | :--- |
| **Total de Órdenes Auditadas** | 99.441 | Universo completo de transacciones en sistema |
| **Órdenes Entregadas (Base SLA)** | 96.470 | Denominador real para indicadores de entrega |
| **Entregas sin Respaldo de Pago (Prueba 1A)** | 1 orden (0,001%) | ID `bfbd0f9bdef84302105ad712db648a6c` |
| **Registros de Pago con Importe $\le 0$ (Prueba 1B)** | 9 registros | Anomalías de registro en tabla `payments` |
| **Órdenes Canceladas/No Disp. con Cobro (Prueba 2)** | 1.231 órdenes | **R$ 269.735,11** de exposición potencial a verificar |
| **Pico Saldo Anticipos al Cierre (Prueba 3)** | **R$ 650.720,07** | Corte **2018-03** (3.778 órdenes cobradas pendientes de entrega) |
| **Incumplimiento Global de Fecha Prometida (SLA)** | **6,77%** | Peor desempeño ($n \ge 100$): **AL (21,41%)**, **MA (17,43%)**, **SE (15,22%)** |
| **Tasa Global de Demora Estructural ($>30$ días)** | **4,27%** (4.117 / 96.470) | Estados más distantes: **AM (31,03%)**, **RR (29,27%)**, **AL (24,18%)** |
| **Medio de Pago Dominante (GMV Entregado)** | Tarjeta de Crédito (**78,46%**) | R$ 12.101.094,88 en cobros brutos sobre órdenes entregadas |

---

## 📊 Visualizaciones

### Cobros Brutos (GMV) por Método de Pago (Órdenes Entregadas)
![Métodos de pago](docs/img/grafico_metodos_pago.png)

### Top 10 Estados por Incumplimiento de Fecha Prometida (SLA, $n \ge 100$)
![Demoras geográficas](docs/img/grafico_demoras_geograficas.png)

---

## 📋 Recomendaciones de Control Interno

- **Controles de Cierre y Devoluciones:** Implementar una validación automática que impida marcar órdenes como `delivered` sin registro de cobro acreditado, y conciliar periódicamente las 1.231 órdenes canceladas/no disponibles con cobro (`R$ 269.735,11`) contra el auxiliar de reembolsos emitidos.
- **Corte Contable Mensual:** Automatizar el reporte de órdenes aprobadas pendientes de entrega al último día hábil de cada mes (con picos superiores a `R$ 650k` en cierres de alta demanda) para respaldar la reclasificación contable de anticipos de clientes.
- **Gestión Logística por SLA Real:** Priorizar la renegociación de operadores logísticos en **Alagoas (`21,41%` fuera de plazo)**, **Maranhão (`17,43%`)** y **Sergipe (`15,22%`)**. En estados aislados como **Amazonas (`31,03%` $>30$ días, pero solo `2,76%` fuera de plazo)**, el sistema ya ajusta la promesa de entrega a la distancia real, por lo que el foco operativo debe centrarse en reducir los desvíos contractuales del Nordeste.

---

## 💡 Lecciones Aprendidas (Iteración Metodológica)

- **De conteos absolutos a tasas normalizadas:** En una primera versión del análisis, Río de Janeiro (`RJ`) figuraba como el estado más problemático por acumular el mayor número absoluto de demoras (`1.079` pedidos). Al normalizar por el volumen total de entregas de cada estado (`12.350` en RJ) y separar la distancia estructural (>30 días) del incumplimiento de fecha prometida (SLA), el diagnóstico cambió por completo: `RJ` cae al 7.º puesto (`12,11%` fuera de plazo) y emergen los verdaderos cuellos de botella en el Nordeste (`AL` y `MA`).
- **Stock vs. Flujo en auditoría de corte:** El análisis de corte mensual se refactorizó para calcular la foto patrimonial al último día de cada cierre en lugar de sumar flujos intermensuales entre períodos.

---

## 🗂️ Estructura del Proyecto

```text
Auditoria-Olist-Ecommerce/
├── data/                  # Datasets CSV crudos de Kaggle (ignorados en Git)
├── docs/
│   └── img/               # Gráficos exportados en alta resolución
├── notebooks/
│   └── 01_Auditoria_Olist.ipynb   # Notebook con motor SQLite, pruebas y visualización
├── outputs/
│   └── reporte_auditoria_olist.xlsx # Reporte ejecutivo multi-hoja (5 pestañas)
├── sql/
│   └── auditoria_olist.sql        # Queries SQL estructuradas (CTEs, JOINs, SLA)
├── .gitignore
├── README.md
└── requirements.txt

```

---

## 🚀 Cómo Ejecutar el Proyecto

1. **Clonar el repositorio y crear el entorno virtual:**
```bash
git clone [https://github.com/Jmonse/Auditoria-Olist-Ecommerce.git](https://github.com/Jmonse/Auditoria-Olist-Ecommerce.git)
cd Auditoria-Olist-Ecommerce
python -m venv .venv
source .venv/Scripts/activate   # Windows (Git Bash)
source .venv/bin/activate       # Linux / macOS
pip install -r requirements.txt

```


2. **Descargar los datos fuente:**
Descargá el dataset [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) desde Kaggle y copiá estos tres archivos dentro de la carpeta `data/`:
* `olist_orders_dataset.csv`
* `olist_order_payments_dataset.csv`
* `olist_customers_dataset.csv`


3. **Ejecutar el análisis:**
Abrí y ejecutá todas las celdas de `notebooks/01_Auditoria_Olist.ipynb` (o ejecutá las consultas directamente desde `sql/auditoria_olist.sql` sobre SQLite).

