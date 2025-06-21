//+------------------------------------------------------------------+
//| TrendAnalyzerWINM25 - Enumerações e Estruturas Principais       |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef TREND_ANALYZER_ENUMS_H
#define TREND_ANALYZER_ENUMS_H

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
struct TradeSignal
{
   datetime             time;           // Tempo do sinal
   ENUM_SIGNAL_TYPE     type;           // Tipo do sinal
   ENUM_SIGNAL_STRENGTH strength;       // Força do sinal
   double               entryPrice;     // Preço de entrada
   double               stopLoss;       // Stop Loss
   double               takeProfit;     // Take Profit
   string               reason;         // Razão do sinal
   double               confidence;     // Confiança (0-100%)
   ENUM_TIMEFRAMES      timeframe;      // Timeframe principal
   bool                 isValid;        // Se o sinal é válido
};

//+------------------------------------------------------------------+
//| Estrutura de Análise Multi-Timeframe                            |
//+------------------------------------------------------------------+
struct MultiTimeframeAnalysis
{
   ENUM_TREND_DIRECTION trendH4;    // Tendência H4
   ENUM_TREND_DIRECTION trendH1;    // Tendência H1
   ENUM_TREND_DIRECTION trendM15;   // Tendência M15
   ENUM_TREND_DIRECTION trendM5;    // Tendência M5
   bool                 aligned;    // Se os timeframes estão alinhados
   double               confidence; // Confiança da análise
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

//+------------------------------------------------------------------+
//| Estrutura de Resultado de Análise de Tendência                  |
//+------------------------------------------------------------------+
struct TrendAnalysisResult
{
    ENUM_TREND_DIRECTION trendDirection;    // Direção da tendência
    double               trendStrength;     // Força da tendência (0-100)
    bool                 hasSequence;       // Se tem sequência válida
    ENUM_SEQUENCE_TYPE   sequenceType;      // Tipo da sequência
    double               sequenceStrength;  // Força da sequência (0-100)
    bool                 isValid;           // Se o resultado é válido
    datetime             lastUpdate;        // Última atualização
};

//+------------------------------------------------------------------+
//| Estrutura de Análise Multi-Timeframe                            |
//+------------------------------------------------------------------+
struct MultiTimeframeAnalysis
{
    ENUM_TREND_DIRECTION overallDirection;  // Direção geral
    double               overallStrength;   // Força geral (0-100)
    ENUM_TIMEFRAME_ALIGNMENT alignment;     // Alinhamento dos timeframes
    ENUM_TIMEFRAMES      dominantTimeframe; // Timeframe dominante
    double               confluenceScore;   // Score de confluência (0-100)
    bool                 isValid;           // Se a análise é válida
    datetime             lastUpdate;        // Última atualização
};

//+------------------------------------------------------------------+
//| Estrutura de Resultado de Confluência                           |
//+------------------------------------------------------------------+
struct ConfluenceResult
{
    double   confluenceScore;   // Score total de confluência (0-100)
    int      bullishFactors;    // Número de fatores bullish
    int      bearishFactors;    // Número de fatores bearish
    int      neutralFactors;    // Número de fatores neutros
    bool     isValid;           // Se o resultado é válido
    datetime lastUpdate;        // Última atualização
};

//+------------------------------------------------------------------+
//| Estrutura de Fator de Confluência                               |
//+------------------------------------------------------------------+
struct ConfluenceFactor
{
    string           factorName;   // Nome do fator
    ENUM_SIGNAL_TYPE direction;    // Direção do fator
    double           weight;       // Peso do fator (0-1)
    double           confidence;   // Confiança do fator (0-100)
    bool             isActive;     // Se o fator está ativo
};

//+------------------------------------------------------------------+
//| Estrutura de Resultado de Análise de Sequência                  |
//+------------------------------------------------------------------+
struct SequenceAnalysisResult
{
    ENUM_TIMEFRAMES      timeframe;    // Timeframe analisado
    ENUM_TREND_DIRECTION direction;    // Direção identificada
    double               strength;     // Força da sequência (0-100)
    bool                 isValid;      // Se o resultado é válido
    bool                 allowsEntry;  // Se permite entrada
    datetime             timestamp;    // Timestamp da análise
};

//+------------------------------------------------------------------+
//| Enumeração de Alinhamento de Timeframes                         |
//+------------------------------------------------------------------+
enum ENUM_TIMEFRAME_ALIGNMENT
{
    TF_BULLISH_STRONG,    // Alinhamento bullish forte (3+ timeframes)
    TF_BULLISH_WEAK,      // Alinhamento bullish fraco (2 timeframes)
    TF_BEARISH_STRONG,    // Alinhamento bearish forte (3+ timeframes)
    TF_BEARISH_WEAK,      // Alinhamento bearish fraco (2 timeframes)
    TF_NEUTRAL            // Sem alinhamento claro
};

//+------------------------------------------------------------------+
//| Enumeração de Tipo de Sequência                                 |
//+------------------------------------------------------------------+
enum ENUM_SEQUENCE_TYPE
{
    SEQUENCE_NONE,                // Nenhuma sequência identificada
    SEQUENCE_ASCENDING_TOPS,      // Topos ascendentes
    SEQUENCE_DESCENDING_TOPS,     // Topos descendentes
    SEQUENCE_ASCENDING_BOTTOMS,   // Fundos ascendentes
    SEQUENCE_DESCENDING_BOTTOMS   // Fundos descendentes
};

#endif // TREND_ANALYZER_ENUMS_H

