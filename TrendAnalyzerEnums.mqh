//+------------------------------------------------------------------+
//| TrendAnalyzerWINM25 - Enumerações e Estruturas Principais       |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef TREND_ANALYZER_ENUMS_H
#define TREND_ANALYZER_ENUMS_H
#property strict

//+------------------------------------------------------------------+
//| Enumerações de Direção de Tendência                             |
//+------------------------------------------------------------------+
enum ENUM_TREND_DIRECTION
{
   TREND_UP,        // Tendência de Alta
   TREND_DOWN,      // Tendência de Baixa  
   TREND_NEUTRAL    // Tendência Neutra/Lateral
};

//+------------------------------------------------------------------+
//| Enumerações de Tipo de Sinal                                    |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_TYPE
{
   SIGNAL_NONE,     // Nenhum sinal
   SIGNAL_BUY,      // Sinal de Compra
   SIGNAL_SELL      // Sinal de Venda
};

//+------------------------------------------------------------------+
//| Enumerações de Força do Sinal                                   |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_STRENGTH
{
   SIGNAL_WEAK,     // Sinal Fraco
   SIGNAL_MEDIUM,   // Sinal Médio
   SIGNAL_STRONG    // Sinal Forte
};

//+------------------------------------------------------------------+
//| Enumerações de Alinhamento de Médias Móveis                     |
//+------------------------------------------------------------------+
enum ENUM_MA_ALIGNMENT
{
   MA_BULLISH,      // Alinhamento de Alta (EMA9 > EMA21 > EMA50 > SMA200)
   MA_BEARISH,      // Alinhamento de Baixa (EMA9 < EMA21 < EMA50 < SMA200)
   MA_NEUTRAL       // Alinhamento Neutro
};

//+------------------------------------------------------------------+
//| Enumerações de Posição no Canal                                 |
//+------------------------------------------------------------------+
enum ENUM_CHANNEL_POSITION
{
   CHANNEL_UPPER,   // Próximo à banda superior (>80%)
   CHANNEL_MIDDLE,  // No meio do canal (20-80%)
   CHANNEL_LOWER    // Próximo à banda inferior (<20%)
};

//+------------------------------------------------------------------+
//| Enumerações de Tipo de Canal                                    |
//+------------------------------------------------------------------+
enum ENUM_CHANNEL_TYPE
{
   CHANNEL_ASCENDING,   // Canal Ascendente
   CHANNEL_DESCENDING,  // Canal Descendente
   CHANNEL_HORIZONTAL   // Canal Horizontal
};

//+------------------------------------------------------------------+
//| Enumerações de Banda de Bollinger                               |
//+------------------------------------------------------------------+
enum ENUM_BB_BAND
{
   BB_UPPER,        // Banda Superior
   BB_MIDDLE,       // Linha Central
   BB_LOWER         // Banda Inferior
};

//+------------------------------------------------------------------+
//| Enumerações de Sinal de Fibonacci                               |
//+------------------------------------------------------------------+
enum ENUM_FIBO_SIGNAL
{
   FIBO_BUY,        // Sinal de Compra (acima de 61.8%)
   FIBO_SELL,       // Sinal de Venda (abaixo de 61.8%)
   FIBO_NEUTRAL     // Neutro
};

//+------------------------------------------------------------------+
//| Enumerações de Tipo de Sequência                                |
//+------------------------------------------------------------------+
enum ENUM_SEQUENCE_TYPE
{
   SEQUENCE_NONE,
   SEQUENCE_ASCENDING,
   SEQUENCE_DESCENDING
};

//+------------------------------------------------------------------+
//| Enumerações de Alinhamento entre Timeframes                      |
//+------------------------------------------------------------------+
enum ENUM_TIMEFRAME_ALIGNMENT
{
   TF_BULLISH_STRONG,
   TF_BULLISH_WEAK,
   TF_BEARISH_STRONG,
   TF_BEARISH_WEAK,
   TF_NEUTRAL
};

//+------------------------------------------------------------------+
//| Enumerações de Tipo de Confluência                               |
//+------------------------------------------------------------------+
enum ENUM_CONFLUENCE_TYPE
{
   CONFLUENCE_BULLISH,
   CONFLUENCE_BEARISH,
   CONFLUENCE_NEUTRAL
};

//+------------------------------------------------------------------+
//| Estrutura de Linha de Tendência                                 |
//+------------------------------------------------------------------+
struct TrendLine
{
   datetime time1;      // Primeiro ponto de tempo
   datetime time2;      // Segundo ponto de tempo
   double   price1;     // Primeiro preço
   double   price2;     // Segundo preço
   int      touches;    // Número de toques
   double   slope;      // Inclinação da linha
   bool     isValid;    // Se a linha é válida
};

//+------------------------------------------------------------------+
//| Estrutura de Nível de Suporte/Resistência                       |
//+------------------------------------------------------------------+
struct SR_Level
{
   double            price;        // Preço do nível
   int               touches;      // Número de toques
   datetime          firstTouch;  // Primeiro toque
   datetime          lastTouch;   // Último toque
   bool              isSupport;   // Se é suporte (true) ou resistência (false)
   ENUM_TIMEFRAMES   timeframe;   // Timeframe de origem
};

//+------------------------------------------------------------------+
//| Estrutura de Canal                                              |
//+------------------------------------------------------------------+
struct Channel
{
   TrendLine            upperLine;  // Linha superior
   TrendLine            lowerLine;  // Linha inferior
   double               width;      // Largura do canal
   bool                 isValid;    // Se o canal é válido
   ENUM_CHANNEL_TYPE    type;       // Tipo do canal
};

//+------------------------------------------------------------------+
//| Estrutura de Sinal de Trading                                   |
//+------------------------------------------------------------------+
struct TradingSignal
{
   ENUM_SIGNAL_TYPE     type;        // Tipo do sinal
   string               symbol;      // Símbolo analisado
   datetime             timestamp;   // Momento do sinal
   double               strength;    // Força do sinal (0-100)
   double               confluence;  // Score de confluência (0-100)
   double               entryPrice;  // Preço de entrada
   double               stopLoss;    // Stop Loss
   double               takeProfit;  // Take Profit
   double               riskReward;  // Razão risco/recompensa
   ENUM_TIMEFRAMES      timeframe;   // Timeframe dominante
   string               reason;      // Razão detalhada
   bool                 isValid;     // Se o sinal é válido
};

//+------------------------------------------------------------------+
//| Estrutura de Resultado de Tendência                              |
//+------------------------------------------------------------------+
struct TrendAnalysisResult
{
   ENUM_TREND_DIRECTION trendDirection;   // Direção identificada
   double               trendStrength;    // Força da tendência (0-100)
   bool                 hasSequence;      // Possui sequência de topos/fundos
   ENUM_SEQUENCE_TYPE   sequenceType;     // Tipo de sequência
   double               sequenceStrength; // Força da sequência
   bool                 isValid;          // Resultado válido
   datetime             lastUpdate;       // Última atualização
};

//+------------------------------------------------------------------+
//| Estrutura de Resultado da Sequência de Timeframes                |
//+------------------------------------------------------------------+
struct SequenceAnalysisResult
{
   ENUM_TIMEFRAMES      timeframe;      // Timeframe analisado
   int                  stepNumber;     // Número do passo
   bool                 stepPassed;     // Passo passou
   double               stepStrength;   // Força do passo
   ENUM_TREND_DIRECTION trendDirection; // Direção do passo
   string               failureReason;  // Motivo da falha
   bool                 isValid;        // Resultado válido
};

//+------------------------------------------------------------------+
//| Estrutura de Fator de Confluência                                |
//+------------------------------------------------------------------+
struct ConfluenceFactor
{
   string              name;        // Nome do fator
   ENUM_CONFLUENCE_TYPE type;       // Tipo do fator
   double              weight;      // Peso do fator
   string              description; // Descrição
   bool                isValid;     // Validade
};

//+------------------------------------------------------------------+
//| Estrutura de Resultado de Confluência                            |
//+------------------------------------------------------------------+
struct ConfluenceResult
{
   string    symbol;           // Símbolo analisado
   datetime  timestamp;        // Momento da análise
   double    confluenceScore;  // Score geral (0-100)
   int       bullishFactors;   // Quantidade de fatores bullish
   int       bearishFactors;   // Quantidade de fatores bearish
   int       neutralFactors;   // Quantidade de fatores neutros
   int       totalFactors;     // Total de fatores
   string    strongestFactor;  // Fator com maior peso
   string    weakestFactor;    // Fator com menor peso
   bool      isValid;          // Resultado válido
};

//+------------------------------------------------------------------+
//| Estrutura de Análise Multi-Timeframe                            |
//+------------------------------------------------------------------+
struct MultiTimeframeAnalysis
{
   ENUM_TREND_DIRECTION overallDirection;   // Direção geral
   double               overallStrength;    // Força consolidada
   ENUM_TIMEFRAME_ALIGNMENT alignment;      // Alinhamento entre timeframes
   ENUM_TIMEFRAMES      dominantTimeframe;  // Timeframe dominante
   double               confluenceScore;    // Score de confluência
   bool                 isValid;            // Resultado válido
   datetime             lastUpdate;         // Última atualização
};

//+------------------------------------------------------------------+
//| Estrutura de Dados de Fibonacci                                 |
//+------------------------------------------------------------------+
struct FibonacciData
{
   double   levels[6];      // Níveis: 0%, 23.6%, 38.2%, 50%, 61.8%, 100%
   double   highPrice;      // Preço máximo
   double   lowPrice;       // Preço mínimo
   datetime highTime;       // Tempo da máxima
   datetime lowTime;        // Tempo da mínima
   bool     isValid;        // Se os dados são válidos
};

//+------------------------------------------------------------------+
//| Estrutura de Níveis de Fibonacci                                 |
//+------------------------------------------------------------------+
struct FibonacciLevels
{
   double   level0;         // Nível 0%
   double   level236;       // Nível 23.6%
   double   level382;       // Nível 38.2%
   double   level500;       // Nível 50%
   double   level618;       // Nível 61.8%
   double   level786;       // Nível 78.6%
   double   level1000;      // Nível 100%/200%
   double   swingHigh;      // Preço do swing high
   double   swingLow;       // Preço do swing low
   datetime swingHighTime;  // Tempo do swing high
   datetime swingLowTime;   // Tempo do swing low
   bool     isValid;        // Níveis válidos
   bool     isRetracement;  // Tipo de cálculo (retração ou extensão)
};

//+------------------------------------------------------------------+
//| Estrutura de Dados de Volume                                    |
//+------------------------------------------------------------------+
struct VolumeData
{
   long     currentVolume;  // Volume atual
   double   averageVolume;  // Volume médio
   double   volumeRatio;    // Ratio volume atual/médio
   bool     isHighLiquidity;// Se está em horário de alta liquidez
   bool     isConfirming;   // Se o volume confirma o movimento
};

// Constantes de Timeframe para análise
#define TIMEFRAME_MACRO    PERIOD_H4   // Timeframe macro (H4)
#define TIMEFRAME_TREND    PERIOD_H1   // Timeframe de tendência (H1)
#define TIMEFRAME_ENTRY    PERIOD_M15  // Timeframe de entrada (M15)
#define TIMEFRAME_TIMING   PERIOD_M5   // Timeframe de timing (M5)

#endif // TREND_ANALYZER_ENUMS_H

