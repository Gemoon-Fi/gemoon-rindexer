-- Вычисляемые поля для таблиц AssetPrices (см. контракт AssetPrices в ../rindexer.yaml).
--
-- PostGraphile (GraphQL-сервер rindexer) превращает SQL-функцию вида
-- <таблица>_<поле>(строка таблицы) в поле <поле> этой таблицы. Отсюда в GraphQL у типа
-- Prices появляются priceUsd, ticker, changeDay, changeWeek, changeMonth.
--
-- Применять после первого запуска rindexer (таблицы должны уже существовать):
--   psql "$DATABASE_URL" -f project/sql/asset_prices.sql
-- Скрипт идемпотентный, его можно запускать повторно. Если у пользователя БД нет прав
-- суперпользователя, GraphQL увидит новые поля только после перезапуска rindexer.

-- Справочник тикеров: пул -> тикер (адрес актива индексер пишет сам, колонка asset).
CREATE TABLE IF NOT EXISTS franky_asset_prices.asset_tickers (
  pool   CHAR(42) PRIMARY KEY,
  ticker TEXT     NOT NULL
);
COMMENT ON TABLE franky_asset_prices.asset_tickers IS E'@omit';

INSERT INTO franky_asset_prices.asset_tickers (pool, ticker) VALUES
  ('0xaae0d815ee56e4092a5e5c2911e676fea50b2d6d', 'AAPL'),
  ('0xaa34fea710a1a737840329051d81d3b0b7c564d5', 'AMC'),
  ('0x48d284a2a4d3dc1b3da08231fe44317e7e7aa51f', 'AMD'),
  ('0x8ac92da74ab5f3b1d024dc1943ad7e15dc4179ef', 'AMZN'),
  ('0xedb22516b14eb2d1c86927db373b0e8bf70f5cd1', 'ASML'),
  ('0x5b7c404f1d7d77f9f3885ab13d7764f8a173028c', 'AVGO'),
  ('0xc6517047b189c72d3baa9ef37d1d28f27a63638a', 'BA'),
  ('0xa57ab582b310dd6f9e934ea1eeea152741545e6a', 'BABA'),
  ('0xc424e56e816f148a8b30ccbde2128e04d21f51e9', 'BB'),
  ('0x1bad145c8f06444e0df81c28257cd20231bd1f16', 'BE'),
  ('0x0a2121a50a09ed0796ae81f9c53ff9398355a398', 'COST'),
  ('0x654e4143e82a5824445ade0824351c2a9acd95a8', 'CRCL'),
  ('0xc30c89cb7815a1488b7998d15eec73961707fc5a', 'DELL'),
  ('0x31a89afd92f9397465649ad03226c52292fc1ae5', 'DJT'),
  ('0x4dbac19e895322ac5b93abad9008691632bffc05', 'F'),
  ('0xca5904c0a9d42f0ec1bf760fdf779907877144fd', 'FIG'),
  ('0x7a6a053eccf1446a2633e05aa6d40d09381997ec', 'GLD'),
  ('0xc67c2d200e0b7e5d99f4cfbede8cb09b48892f2c', 'GLXY'),
  ('0xe9713f453adb9245b19559790c96f470a18f2fdf', 'GME'),
  ('0x34d0dc122cf9a8eb296fc5e0d3a233625d7d19b7', 'GOOGL'),
  ('0xc8c90d3a1c1a24967e773ac2ad0d456ba3e31f64', 'HIMS'),
  ('0x8cd848ce18b829c5c769aff27164078bb52e0e97', 'IBM'),
  ('0x2e5a92f5013a64661a49312111be2e8abd33f56a', 'INTC'),
  ('0x7f0ace18d1dced47063cf26e649bc8ab14d09e67', 'JNJ'),
  ('0xf212d02146a897f5f686e9d629f6a73da534324a', 'LLY'),
  ('0x54f160bea60ec5207918c539d86e0b906b4da297', 'LMT'),
  ('0x0f4227d27082b3bca6818381b9ea6460275e49f4', 'LULU'),
  ('0x107a7cb40d8665360ba10e59471af06150a50922', 'META'),
  ('0xb40196272a6d2eb5edf6d93bc4dc39856ad95e0e', 'MRNA'),
  ('0xeb60bcd1d920ad6e102690ccfc6fb488899e1510', 'MSFT'),
  ('0x17578c0e0d15da44f31677263114f71ae76653ea', 'MSTR'),
  ('0xd057b1bc54917855bbee58ead58647f47cab35e5', 'MU'),
  ('0xa9caebb1b2fb2b954f192572b309aef1caf6a330', 'NET'),
  ('0x59895c0302f41aeaa129d2fa2442cec01e7ef45e', 'NFLX'),
  ('0xb6d047637151f6de1d02028acdd187aa9cb7afe3', 'NU'),
  ('0xd4eb21209c4d6093f80b5b84f5c45cc093ea14a3', 'NVDA'),
  ('0xc7d573fcda6d2107c97fb582ae18411f9db32e7f', 'PFE'),
  ('0x851680416a4f4e1c463d45171d61acddbc8554c0', 'PLTR'),
  ('0xd60a5d14db690b7afad71f76b108071d7175597d', 'QQQ'),
  ('0x227bbce9a81b3694b01754298a983be3f9e44a93', 'QUBT'),
  ('0x2ef5945cd5664876b6481fdacfaa2942995a4da8', 'RBLX'),
  ('0x64710a70839585af718e1b1faef9e7f1665f1116', 'RCAT'),
  ('0xa8744e76aed23b05f0126335e7bd38f7935d19fe', 'RDDT'),
  ('0xb30a75b200d98a600a3766869344928e35823e23', 'RIVN'),
  ('0xfab520051f96f4d2a32c22b6a3dd7fffdf231bfe', 'SGOV'),
  ('0x5f2a5025feb93a4c44da4e3b37e4fd3fb0ab5171', 'SKHY'),
  ('0x8cb787e6c315d464775289bad00fdd67d53ecb3d', 'SLV'),
  ('0x0ebd4650c9e641e9745b5a508a2d46935dfe753e', 'SNAP'),
  ('0xa1e1c9519cd5ae47e9a935645e1a7b935b944559', 'SNDK'),
  ('0xc61284332117c3fb23a2a56cceffd07f7af60029', 'SPCX'),
  ('0xa7bb1ac63bbab0c44316e6c8c455213441689167', 'SPY'),
  ('0xf4acdaeeb7022862a763c9b1b885e11191c889e3', 'TSLA'),
  ('0x07e8ea83d4c1340774c8965125e26e12bf943bf1', 'TSM'),
  ('0xd9ab4b7fae6dc2f7020134ec744a8f53ef3e5e24', 'TTWO'),
  ('0x3ab74c45dcecc6a62898204dd42143a816b44cb1', 'UPS'),
  ('0x04391780f519b7d3ba59c9590459d76e23d225c4', 'USAR'),
  ('0x02175608f1b5e6b5ed221ccfdc7be197d111d915', 'USO'),
  ('0xb78dd1a97fa544c65d7d1f12453ecaaf1e05c36d', 'VTI'),
  ('0x9664d869540e9d0a76f12c6623946c6d5d201e09', 'cbBTC'),
  ('0x52e65b17fb6e5ba00ed806f37afcd2daa50271ca', 'WETH'),
  ('0x7a192e71564ec66ee0763e328a3ac274942de4e1', 'PONS'),
  ('0x4b0c312ffbb068f6a0bea128759e35d94b94d0e1', 'CASHCAT'),
  ('0xe547c18f46db55ab788343bcc503f9cf0bd7d564', 'AI'),
  ('0x75ee717303f5212cc1be3c52ea21f7128954902e', 'ORBIO')
ON CONFLICT (pool) DO UPDATE SET ticker = EXCLUDED.ticker;

CREATE OR REPLACE FUNCTION franky_asset_prices.prices_ticker(p franky_asset_prices.prices)
RETURNS text LANGUAGE sql STABLE AS $$
  SELECT ticker FROM franky_asset_prices.asset_tickers WHERE pool = lower(p.pool)
$$;

-- Цена в USDG обычным десятичным числом (в таблице она хранится умноженной на 1e18).
CREATE OR REPLACE FUNCTION franky_asset_prices.prices_price_usd(p franky_asset_prices.prices)
RETURNS numeric LANGUAGE sql STABLE AS $$
  SELECT p.price / 1e18
$$;

-- Изменение цены в процентах за последние window_seconds секунд.
-- "Сейчас" = время самого свежего проиндексированного свопа в сети, то есть время
-- блокчейна, а не часы сервера (как в abis/indexing.md: now - 24h по block.timestamp).
-- Цена "тогда" = цена закрытия последнего часа, закончившегося не позже (сейчас - окно),
-- поэтому точность окна один час. NULL, если истории на всё окно ещё нет.
CREATE OR REPLACE FUNCTION franky_asset_prices.prices_change_since(
  p franky_asset_prices.prices,
  window_seconds bigint
) RETURNS numeric LANGUAGE sql STABLE AS $$
  SELECT round((p.price / NULLIF(h.close, 0) - 1) * 100, 4)
  FROM franky_asset_prices.prices_hourly h
  WHERE h.network = p.network
    AND h.pool = p.pool
    AND h.hour < floor((
      extract(epoch FROM (
        SELECT max(rindexer_block_timestamp) FROM franky_asset_prices.prices WHERE network = p.network
      )) - window_seconds
    ) / 3600)
  ORDER BY h.hour DESC
  LIMIT 1
$$;
COMMENT ON FUNCTION franky_asset_prices.prices_change_since(franky_asset_prices.prices, bigint) IS E'@omit';

CREATE OR REPLACE FUNCTION franky_asset_prices.prices_change_day(p franky_asset_prices.prices)
RETURNS numeric LANGUAGE sql STABLE AS $$
  SELECT franky_asset_prices.prices_change_since(p, 86400)
$$;

CREATE OR REPLACE FUNCTION franky_asset_prices.prices_change_week(p franky_asset_prices.prices)
RETURNS numeric LANGUAGE sql STABLE AS $$
  SELECT franky_asset_prices.prices_change_since(p, 7 * 86400)
$$;

CREATE OR REPLACE FUNCTION franky_asset_prices.prices_change_month(p franky_asset_prices.prices)
RETURNS numeric LANGUAGE sql STABLE AS $$
  SELECT franky_asset_prices.prices_change_since(p, 30 * 86400)
$$;

-- Начало часа свечи как дата-время.
CREATE OR REPLACE FUNCTION franky_asset_prices.prices_hourly_hour_start(h franky_asset_prices.prices_hourly)
RETURNS timestamptz LANGUAGE sql STABLE AS $$
  SELECT to_timestamp(h.hour * 3600)
$$;
