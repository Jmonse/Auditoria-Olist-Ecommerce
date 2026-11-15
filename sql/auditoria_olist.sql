-- ============================================================================
-- AUDITORÍA DE INTEGRIDAD CONTABLE Y PERFORMANCE LOGÍSTICA - OLIST BRASIL
-- Motor: SQLite / ANSI SQL (CTEs, LEFT JOIN, Agregaciones Condicionales)
-- ============================================================================

-- PRUEBA 1A: Integridad de Cobros - Órdenes entregadas sin respaldo de pago
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

-- PRUEBA 2: Exposición Potencial por Cancelaciones - Órdenes canceladas/no disp. con cobro
SELECT
    o.order_status,
    COUNT(DISTINCT o.order_id) AS ordenes_afectadas,
    COUNT(p.payment_sequential) AS transacciones_pago,
    ROUND(SUM(p.payment_value), 2) AS monto_expuesto_brl
FROM orders o
INNER JOIN payments p ON o.order_id = p.order_id
WHERE o.order_status IN ('canceled', 'unavailable')
  AND p.payment_value > 0
GROUP BY o.order_status
ORDER BY monto_expuesto_brl DESC;

-- PRUEBA 3: Corte de Operaciones (Stock Patrimonial al Cierre de Cada Mes)
-- Órdenes aprobadas hasta el último día del mes y aún no entregadas a esa fecha
WITH meses AS (
    SELECT DISTINCT strftime('%Y-%m', order_approved_at) AS mes
    FROM orders
    WHERE order_approved_at IS NOT NULL
),
pagos AS (
    SELECT order_id, ROUND(SUM(payment_value), 2) AS total_cobrado
    FROM payments
    GROUP BY order_id
)
SELECT
    m.mes AS cierre_mensual,
    COUNT(o.order_id) AS ordenes_pendientes_cierre,
    ROUND(SUM(p.total_cobrado), 2) AS saldo_anticipos_brl
FROM meses m
INNER JOIN orders o
    ON o.order_status = 'delivered'
   AND date(o.order_approved_at) <= date(m.mes || '-01', '+1 month', '-1 day')
   AND date(o.order_delivered_customer_date) > date(m.mes || '-01', '+1 month', '-1 day')
INNER JOIN pagos p ON p.order_id = o.order_id
GROUP BY m.mes
ORDER BY m.mes;

-- PRUEBA 4: Performance Logística y SLA Normalizado por Estado
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
    SUM(es_fuera_de_plazo) AS entregas_fuera_plazo,
    ROUND(SUM(es_fuera_de_plazo) * 100.0 / COUNT(order_id), 2) AS tasa_fuera_plazo_pct,
    SUM(es_demora_critica) AS demoras_criticas_30d,
    ROUND(SUM(es_demora_critica) * 100.0 / COUNT(order_id), 2) AS tasa_demora_critica_pct
FROM metricas_entrega
GROUP BY estado
ORDER BY tasa_fuera_plazo_pct DESC, total_entregas DESC;