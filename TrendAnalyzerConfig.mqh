//+------------------------------------------------------------------+
//| TrendAnalyzerWINM25 - Configurações e Constantes               |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef TREND_ANALYZER_CONFIG_H
#define TREND_ANALYZER_CONFIG_H

//+------------------------------------------------------------------+
//| Configurações de Timeframes                                     |
//+------------------------------------------------------------------+
#define TIMEFRAME_MACRO     PERIOD_H4    // Timeframe macro (contexto estrutural)
#define TIMEFRAME_TREND     PERIOD_H1    // Timeframe de tendência principal
#define TIMEFRAME_SETUP     PERIOD_M15   // Timeframe de setup
#define TIMEFRAME_ENTRY     PERIOD_M5    // Timeframe de entrada
#define TIMEFRAME_TIMING    PERIOD_M3    // Timeframe de timing

//+------------------------------------------------------------------+
//| Configurações de Médias Móveis                                  |
//+------------------------------------------------------------------+
#define MA_PERIOD_9         9            // Período EMA 9
#define MA_PERIOD_21        21           // Período EMA 21
#define MA_PERIOD_50        50           // Período EMA 50
#define MA_PERIOD_200       200          // Período SMA 200

#define MA_METHOD_EMA       MODE_EMA     // Método Exponencial
#define MA_METHOD_SMA       MODE_SMA     // Método Simples

//+------------------------------------------------------------------+
//| Configurações de Bandas de Bollinger                            |
//+------------------------------------------------------------------+
#define BB_PERIOD           20           // Período das Bandas
#define BB_DEVIATION        2.0          // Desvio padrão
#define BB_APPLIED_PRICE    PRICE_CLOSE  // Preço aplicado

//+------------------------------------------------------------------+
//| Configurações de Fibonacci                                      |
//+------------------------------------------------------------------+
#define FIBO_LEVEL_0        0.000        // 0%
#define FIBO_LEVEL_236      0.236        // 23.6%
#define FIBO_LEVEL_382      0.382        // 38.2%
#define FIBO_LEVEL_500      0.500        // 50%
#define FIBO_LEVEL_618      0.618        // 61.8% (Zona de Ouro)
#define FIBO_LEVEL_786      0.786        // 78.6%
#define FIBO_LEVEL_100      1.000        // 100%

//+------------------------------------------------------------------+
//| Tolerâncias e Distâncias (em pontos)                            |
//+------------------------------------------------------------------+
#define TOLERANCE_TRENDLINE 10           // Tolerância para linha de tendência
#define TOLERANCE_SR_LEVEL  20           // Tolerância para suporte/resistência
#define TOLERANCE_MA_NEAR   15           // Tolerância para "perto das médias"
#define TOLERANCE_FIBO      10           // Tolerância para níveis de Fibonacci
// Aliases e tolerâncias adicionais
#define TOLERANCE_MA        TOLERANCE_MA_NEAR
#define TOLERANCE_SUPPORT_RESISTANCE TOLERANCE_SR_LEVEL
#define TOLERANCE_BB        10           // Tolerância para Bandas de Bollinger
#define TOLERANCE_FIBONACCI TOLERANCE_FIBO
#define TOLERANCE_VWAP      10           // Tolerância para VWAP

//+------------------------------------------------------------------+
//| Configurações de Volume                                          |
//+------------------------------------------------------------------+
#define VOLUME_PERIOD       20           // Período para média de volume
#define VOLUME_HIGH_RATIO   1.5          // Ratio para volume alto
#define LIQUIDITY_START     10           // Início alta liquidez (10h)
#define LIQUIDITY_END       16           // Fim alta liquidez (16h)
// Parâmetros adicionais para análise de volume
#define VOLUME_ANALYSIS_PERIOD   VOLUME_PERIOD
#define HIGH_VOLUME_THRESHOLD    1.5
#define LOW_VOLUME_THRESHOLD     0.7
#define VOLUME_CLIMAX_MULTIPLIER 3.0

//+------------------------------------------------------------------+
//| Configurações de Price Action                                   |
//+------------------------------------------------------------------+
#define MIN_TRENDLINE_TOUCHES   3        // Mínimo de toques para validar linha
#define MIN_SR_TOUCHES          3        // Mínimo de toques para validar S/R
#define MAX_PULLBACK_BARS       3        // Máximo de barras para pullback pequeno
#define MAX_PULLBACK_PERCENT    25       // Máximo % para pullback pequeno
#define SPIKE_ATR_MULTIPLIER    2.0      // Multiplicador ATR para spike
#define SPIKE_MAX_BARS          5        // Máximo de barras para spike

//+------------------------------------------------------------------+
//| Configurações de Canal                                          |
//+------------------------------------------------------------------+
#define CHANNEL_WIDTH_TOLERANCE 10       // Tolerância % para largura do canal
#define CHANNEL_UPPER_THRESHOLD 80       // Threshold superior do canal (%)
#define CHANNEL_LOWER_THRESHOLD 20       // Threshold inferior do canal (%)

//+------------------------------------------------------------------+
//| Configurações de Sinal                                          |
//+------------------------------------------------------------------+
#define SIGNAL_MIN_CONFIDENCE   70       // Confiança mínima para sinal válido
#define SIGNAL_STRONG_THRESHOLD 85       // Threshold para sinal forte
#define SIGNAL_MEDIUM_THRESHOLD 75       // Threshold para sinal médio
#define SIGNAL_MIN_INTERVAL     300      // Intervalo mínimo entre sinais (seg)

//+------------------------------------------------------------------+
//| Configurações de Risk Management                                |
//+------------------------------------------------------------------+
#define DEFAULT_STOP_LOSS_POINTS    100  // Stop Loss padrão em pontos
#define DEFAULT_TAKE_PROFIT_POINTS  200  // Take Profit padrão em pontos
#define RISK_REWARD_RATIO           2.0  // Ratio Risco/Recompensa
#define STOP_LOSS_ATR_MULTIPLIER    2.0  // Multiplicador ATR para Stop Loss

//+------------------------------------------------------------------+
//| Pesos e Limiares de Confluência                                  |
//+------------------------------------------------------------------+
#define WEIGHT_TRENDLINE            1.0
#define WEIGHT_SUPPORT_RESISTANCE   1.0
#define WEIGHT_CHANNEL              1.0
#define WEIGHT_MOVING_AVERAGES      1.0
#define WEIGHT_VWAP                 1.0
#define WEIGHT_BOLLINGER            1.0
#define WEIGHT_FIBONACCI            1.0
#define WEIGHT_VOLUME               1.0
#define MIN_SIGNAL_STRENGTH         50    // Força mínima do sinal (%)
#define MIN_CONFLUENCE_SCORE        60    // Score mínimo de confluência (%)

//+------------------------------------------------------------------+
//| Configurações de Análise Histórica                              |
//+------------------------------------------------------------------+
#define HISTORY_BARS_ANALYSIS   500      // Barras para análise histórica
#define HISTORY_BARS_TRENDLINE  100      // Barras para linha de tendência
#define HISTORY_BARS_SR         200      // Barras para suporte/resistência
#define HISTORY_BARS_PATTERN    50       // Barras para padrões
#define HISTORY_BARS_FIBONACCI  200      // Barras para análise de Fibonacci

//+------------------------------------------------------------------+
//| Limites de armazenamento                                         |
//+------------------------------------------------------------------+
#define MAX_CONFLUENCE_FACTORS  64       // Máximo de fatores de confluência
#define MAX_SIGNAL_HISTORY      50       // Tamanho do histórico de sinais

//+------------------------------------------------------------------+
//| Configurações de Debug e Log                                    |
//+------------------------------------------------------------------+
#define DEBUG_MODE              true     // Modo debug ativo
#define LOG_LEVEL_INFO          1        // Nível de log informativo
#define LOG_LEVEL_WARNING       2        // Nível de log warning
#define LOG_LEVEL_ERROR         3        // Nível de log erro

//+------------------------------------------------------------------+
//| Configurações Específicas do WINM25                             |
//+------------------------------------------------------------------+
#define WINM25_SYMBOL           "WINM25" // Símbolo padrão
#define WINM25_POINT_VALUE      1.0      // Valor do ponto
#define WINM25_TICK_SIZE        5        // Tamanho do tick
#define WINM25_CONTRACT_SIZE    1        // Tamanho do contrato

//+------------------------------------------------------------------+
//| Horários de Negociação WINM25                                   |
//+------------------------------------------------------------------+
#define MARKET_OPEN_HOUR        9        // Abertura do mercado
#define MARKET_CLOSE_HOUR       17       // Fechamento do mercado
#define LUNCH_START_HOUR        12       // Início do almoço
#define LUNCH_END_HOUR          13       // Fim do almoço

//+------------------------------------------------------------------+
//| Configurações de Performance                                    |
//+------------------------------------------------------------------+
#define MAX_BARS_CALCULATION    1000     // Máximo de barras para cálculo
#define UPDATE_FREQUENCY_MS     1000     // Frequência de atualização (ms)
#define CACHE_VALIDITY_SECONDS  60       // Validade do cache (segundos)

//+------------------------------------------------------------------+
//| Limiares de Força para o Sequenciador                            |
//+------------------------------------------------------------------+
#define MIN_H4_TREND_STRENGTH   60       // Força mínima da tendência no H4
#define MIN_H1_TREND_STRENGTH   50       // Força mínima da tendência no H1
#define MIN_M15_TREND_STRENGTH  40       // Força mínima da tendência no M15
#define MIN_SEQUENCE_STRENGTH   50       // Força mínima da sequência completa

#endif // TREND_ANALYZER_CONFIG_H

