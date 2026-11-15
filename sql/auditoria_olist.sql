-- ============================================================================
-- AUDITORÍA DE INTEGRIDAD CONTABLE Y PERFORMANCE LOGÍSTICA - OLIST BRASIL
-- Motor: SQLite / ANSI SQL (CTEs, LEFT JOIN, Agregaciones Condicionales)
-- ============================================================================

-- PRUEBA 1A: Integridad de Ingresos - Órdenes entregadas sin respaldo de cobro
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_delivered_customer_date
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
  AND p.order_id IS NULL;

-- PRUEBA 1B: Integridad de Cobros - Registros de pago con importe nulo o <= 0
SELECT
    p.order_id,
    o.order_status,
    p.payment_sequential,
    p.payment_type,
    p.payment_value
FROM payments p
LEFT JOIN orders o ON p.order_id = o.order_id
WHERE p.payment_value IS NULL
   OR p.payment_value <= 0;

-- PRUEBA 2: Pasivos Contingentes / Reembolsos - Órdenes canceladas o no disponibles con cobro
SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS ordenes_afectadas,
    COUNT(p.payment_sequential) AS transacciones_pago,
    ROUND(SUM(p.payment_value), 2) AS monto_expuesto_reembolso
FROM orders o
INNER JOIN payments p ON o.order_id = p.order_id
WHERE o.order_status IN ('canceled', 'unavailable')
  AND p.payment_value > 0
GROUP BY o.order_status
ORDER BY monto_expuesto_reembolso DESC;

-- PRUEBA 3: Corte de Operaciones / Devengado (Revenue Recognition)
-- Órdenes aprobadas en un mes calendario y entregadas en un mes posterior (anticipos al cierre)
WITH pagos_por_orden AS (
    SELECT
        order_id,
        ROUND(SUM(payment_value), 2) AS total_pagado
    FROM payments
    GROUP BY order_id
)
SELECT
    strftime('%Y-%m', o.order_approved_at) AS periodo_aprobacion,
    COUNT(o.order_id) AS ordenes_diferidas,
    ROUND(SUM(p.total_pagado), 2) AS ingresos_diferidos_brl
FROM orders o
INNER JOIN pagos_por_orden p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
  AND o.order_approved_at IS NOT NULL
  AND o.order_delivered_customer_date IS NOT NULL
  AND strftime('%Y-%m', o.order_delivered_customer_date) > strftime('%Y-%m', o.order_approved_at)
GROUP BY periodo_aprobacion
ORDER BY periodo_aprobacion;

-- PRUEBA 4: Performance Logística y SLA Normalizado por Estado (Universo completo)
WITH metricas_entrega AS (
    SELECT
        c.customer_state AS estado,
        o.order_id,
        CAST(julianday(o.order_delivered_customer_date) - julianday(o.order_purchase_timestamp) AS INTEGER) AS lead_time_dias,
        CASE
            WHEN CAST(julianday(o.order_delivered_customer_date) - julianday(o.order_purchase_timestamp) AS INTEGER) > 30 THEN 1
            ELSE 0
        END AS es_demora_critica,
        CASE
            WHEN date(o.order_delivered_customer_date) > date(o.order_estimated_delivery_date) THEN 1
            ELSE 0
        END AS es_fuera_de_plazo
    FROM orders o
    INNER JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
)
SELECT
    estado,
    COUNT(order_id) AS total_entregas,
    ROUND(AVG(lead_time_dias), 1) AS lead_time_promedio_dias,
    SUM(es_demora_critica) AS demoras_criticas_30d,
    ROUND(SUM(es_demora_critica) * 100.0 / COUNT(order_id), 2) AS tasa_demora_critica_pct,
    SUM(es_fuera_de_plazo) AS entregas_fuera_plazo,
    ROUND(SUM(es_fuera_de_plazo) * 100.0 / COUNT(order_id), 2) AS tasa_fuera_plazo_pct
FROM metricas_entrega
GROUP BY estado
ORDER BY tasa_demora_critica_pct DESC, total_entregas DESC;
