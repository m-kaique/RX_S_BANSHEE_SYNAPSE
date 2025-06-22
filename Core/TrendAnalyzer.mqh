//+------------------------------------------------------------------+
//| TrendAnalyzer.mqh - Classe Principal de Análise de Tendência    |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef TREND_ANALYZER_H
#define TREND_ANALYZER_H
#property strict

#include <Object.mqh>
#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "CoreUtils.mqh"

//+------------------------------------------------------------------+
//| Classe Principal de Análise de Tendência                        |
//+------------------------------------------------------------------+
class CTrendAnalyzer : public CObject
{
private:
    string               m_symbol;           // Símbolo analisado
    ENUM_TIMEFRAMES      m_timeframes[4];    // Timeframes de análise
    double               m_pointValue;       // Valor do ponto
    int                  m_digits;           // Dígitos do símbolo
    bool                 m_initialized;      // Status de inicialização
    
    // Arrays para análise de barras
    double               m_high[];           // Máximas
    double               m_low[];            // Mínimas
    double               m_close[];          // Fechamentos
    datetime             m_time[];           // Tempos
    long                 m_volume[];         // Volume
    
    // Cache de resultados
    ENUM_TREND_DIRECTION m_lastTrendH4;      // Última tendência H4
    ENUM_TREND_DIRECTION m_lastTrendH1;      // Última tendência H1
    ENUM_TREND_DIRECTION m_lastTrendM15;     // Última tendência M15
    ENUM_TREND_DIRECTION m_lastTrendM5;      // Última tendência M5
    datetime             m_lastUpdate;       // Última atualização
    
public:
    //+------------------------------------------------------------------+
    //| Construtor                                                       |
    //+------------------------------------------------------------------+
    CTrendAnalyzer()
    {
        m_symbol = "";
        m_pointValue = 0.0;
        m_digits = 0;
        m_initialized = false;
        m_lastTrendH4 = TREND_NEUTRAL;
        m_lastTrendH1 = TREND_NEUTRAL;
        m_lastTrendM15 = TREND_NEUTRAL;
        m_lastTrendM5 = TREND_NEUTRAL;
        m_lastUpdate = 0;
        
        // Configurar timeframes de análise
        m_timeframes[0] = TIMEFRAME_MACRO;   // H4
        m_timeframes[1] = TIMEFRAME_TREND;   // H1
        m_timeframes[2] = TIMEFRAME_SETUP;   // M15
        m_timeframes[3] = TIMEFRAME_ENTRY;   // M5
        
        // Configurar arrays como séries
        ArraySetAsSeries(m_high, true);
        ArraySetAsSeries(m_low, true);
        ArraySetAsSeries(m_close, true);
        ArraySetAsSeries(m_time, true);
        ArraySetAsSeries(m_volume, true);
    }
    
    //+------------------------------------------------------------------+
    //| Destrutor                                                        |
    //+------------------------------------------------------------------+
    ~CTrendAnalyzer()
    {
        ArrayFree(m_high);
        ArrayFree(m_low);
        ArrayFree(m_close);
        ArrayFree(m_time);
        ArrayFree(m_volume);
    }
    
    //+------------------------------------------------------------------+
    //| Inicialização do analisador                                     |
    //+------------------------------------------------------------------+
    bool Initialize(string symbol)
    {
        // Validar símbolo
        if(symbol == "" || symbol == NULL)
        {
            Print("ERRO: Símbolo inválido");
            return false;
        }
        
        // Verificar se é WINM25 ou similar
        if(StringFind(symbol, "WIN") == -1)
        {
            Print("AVISO: Símbolo não é WINM25. Símbolo: ", symbol);
        }
        
        m_symbol = symbol;
        
        // Obter propriedades do símbolo
        m_pointValue = SymbolInfoDouble(symbol, SYMBOL_POINT);
        m_digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
        
        if(m_pointValue <= 0)
        {
            Print("ERRO: Não foi possível obter propriedades do símbolo ", symbol);
            return false;
        }
        
        // Verificar disponibilidade dos timeframes
        for(int i = 0; i < 4; i++)
        {
            if(!IsTimeframeAvailable(m_timeframes[i]))
            {
                Print("ERRO: Timeframe não disponível: ", EnumToString(m_timeframes[i]));
                return false;
            }
        }
        
        m_initialized = true;
        Print("TrendAnalyzer inicializado com sucesso para ", symbol);
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Análise de tendência por timeframe                              |
    //+------------------------------------------------------------------+
    ENUM_TREND_DIRECTION AnalyzeTrend(ENUM_TIMEFRAMES tf)
    {
        if(!m_initialized)
        {
            Print("ERRO: TrendAnalyzer não inicializado");
            return TREND_NEUTRAL;
        }
        
        // Obter dados históricos
        if(!GetHistoricalData(tf, HISTORY_BARS_TRENDLINE))
        {
            Print("ERRO: Falha ao obter dados históricos para ", EnumToString(tf));
            return TREND_NEUTRAL;
        }
        
        // Identificar sequência de topos e fundos
        int topsCount = 0, bottomsCount = 0;
        int ascendingTops = 0, descendingTops = 0;
        int ascendingBottoms = 0, descendingBottoms = 0;
        
        // Analisar últimas 20 barras para identificar padrão
        int barsToAnalyze = MathMin(20, ArraySize(m_high) - 1);
        
        for(int i = 2; i < barsToAnalyze; i++)
        {
            // Identificar topos locais
            if(m_high[i] > m_high[i-1] && m_high[i] > m_high[i+1])
            {
                topsCount++;
                
                // Verificar se é ascendente ou descendente
                if(topsCount > 1)
                {
                    // Encontrar topo anterior
                    for(int j = i + 1; j < barsToAnalyze; j++)
                    {
                        if(m_high[j] > m_high[j-1] && m_high[j] > m_high[j+1])
                        {
                            if(m_high[i] > m_high[j])
                                ascendingTops++;
                            else
                                descendingTops++;
                            break;
                        }
                    }
                }
            }
            
            // Identificar fundos locais
            if(m_low[i] < m_low[i-1] && m_low[i] < m_low[i+1])
            {
                bottomsCount++;
                
                // Verificar se é ascendente ou descendente
                if(bottomsCount > 1)
                {
                    // Encontrar fundo anterior
                    for(int j = i + 1; j < barsToAnalyze; j++)
                    {
                        if(m_low[j] < m_low[j-1] && m_low[j] < m_low[j+1])
                        {
                            if(m_low[i] > m_low[j])
                                ascendingBottoms++;
                            else
                                descendingBottoms++;
                            break;
                        }
                    }
                }
            }
        }
        
        // Determinar tendência baseada na sequência
        ENUM_TREND_DIRECTION trend = TREND_NEUTRAL;
        
        // Tendência de alta: topos e fundos ascendentes
        if(ascendingTops >= descendingTops && ascendingBottoms >= descendingBottoms)
        {
            if(ascendingTops > 0 || ascendingBottoms > 0)
            {
                trend = TREND_UP;
            }
        }
        // Tendência de baixa: topos e fundos descendentes
        else if(descendingTops >= ascendingTops && descendingBottoms >= ascendingBottoms)
        {
            if(descendingTops > 0 || descendingBottoms > 0)
            {
                trend = TREND_DOWN;
            }
        }
        
        // Confirmar com análise de preço atual vs médias
        double currentPrice = m_close[0];
        double avgPrice = 0;
        
        // Calcular média dos últimos 10 fechamentos
        for(int i = 0; i < 10 && i < ArraySize(m_close); i++)
        {
            avgPrice += m_close[i];
        }
        avgPrice /= MathMin(10, ArraySize(m_close));
        
        // Ajustar tendência baseado na posição atual
        if(trend == TREND_NEUTRAL)
        {
            if(currentPrice > avgPrice * 1.002) // 0.2% acima
                trend = TREND_UP;
            else if(currentPrice < avgPrice * 0.998) // 0.2% abaixo
                trend = TREND_DOWN;
        }
        
        // Cache do resultado
        CacheTrendResult(tf, trend);

        Print("TENDENCIA CRUA SEM VALIDAÇÃO DE FORÇA ---->>>>>>: " + EnumToString(trend));
        return trend;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está próximo de nível                        |
    //+------------------------------------------------------------------+
    bool IsPriceNearLevel(double price, double level, double tolerance)
    {
        if(level == 0) return false;
        
        double distance = MathAbs(price - level);
        double tolerancePoints = tolerance * m_pointValue;
        
        return (distance <= tolerancePoints);
    }
    
    //+------------------------------------------------------------------+
    //| Calcular força da tendência usando direção fornecida (0-100)    |
    //+------------------------------------------------------------------+
    double CalculateTrendStrength(ENUM_TIMEFRAMES tf, ENUM_TREND_DIRECTION currentTrend)
    {
        if(currentTrend == TREND_NEUTRAL)
            return 0;

        if(!GetHistoricalData(tf, 50))
            return 0;

        int bars = MathMin(50, ArraySize(m_close));

        // -------------------------------------------------------------
        // 1) Inclinação da linha de tendência
        // -------------------------------------------------------------
        double slopePoints = 0;
        if(bars >= 2)
        {
            double priceDiff = m_close[0] - m_close[bars-1];
            slopePoints = MathAbs(priceDiff) / (m_pointValue * bars);
        }
        double slopeScore = MathMin(100.0, slopePoints * 2.0); // 50 pts/bar -> 100

        // -------------------------------------------------------------
        // 2) Consistência (desvio padrão da regressão linear)
        // -------------------------------------------------------------
        double stdDev = 0;
        if(bars >= 2)
        {
            // Utilize o método utilitário para calcular a inclinação
            double slope = CCoreUtils::CalculateSlope(m_time[bars-1],
                                                     m_close[bars-1],
                                                     m_time[0],
                                                     m_close[0]);
            double intercept = m_close[0] - slope * (double)m_time[0];
            double sumSq = 0;
            for(int i=0;i<bars;i++)
            {
                double predicted = intercept + slope * (double)m_time[i];
                double diff = m_close[i] - predicted;
                sumSq += diff * diff;
            }
            stdDev = MathSqrt(sumSq / bars);
        }
        // Converter desvio padrão para pontos diretamente para evitar
        // dependência do utilitário
        double stdPoints = (m_pointValue>0) ? (stdDev / m_pointValue) : 0.0;
        double consistencyScore = MathMax(0.0, 100.0 - (stdPoints * 2.0));

        // -------------------------------------------------------------
        // 3) Volume médio durante formação
        // -------------------------------------------------------------
        double volumeScore = 50.0; // valor padrão caso não haja dados
        if(ArraySize(m_volume) >= 21)
        {
            long totalVol = 0;
            for(int i=1;i<21;i++)
                totalVol += m_volume[i];
            double avgVol = (double)totalVol / 20.0;
            double ratio = (avgVol>0) ? ((double)m_volume[0] / avgVol) : 1.0;
            volumeScore = MathMin(100.0, ratio * 50.0);
        }

        // -------------------------------------------------------------
        // 4) Duração (barras consecutivas na direção atual)
        // -------------------------------------------------------------
        int duration = 0;
        for(int i=1;i<bars;i++)
        {
            bool bullish = (m_close[i] > m_close[i-1]);
            bool bearish = (m_close[i] < m_close[i-1]);

            if((currentTrend == TREND_UP && bullish) ||
               (currentTrend == TREND_DOWN && bearish))
            {
                duration++;
            }
            else
            {
                break;
            }
        }
        double durationScore = MathMin(100.0, ((double)duration / 10.0) * 100.0);

        // -------------------------------------------------------------
        // Composição final (pesos: 40%, 20%, 20%, 20%)
        // -------------------------------------------------------------
        double strength = (slopeScore * 0.4) +
                          (consistencyScore * 0.2) +
                          (volumeScore * 0.2) +
                          (durationScore * 0.2);

        return MathMin(100.0, MathMax(0.0, strength));
    }

    //+------------------------------------------------------------------+
    //| Obter força da tendência (0-100)                                |
    //+------------------------------------------------------------------+
    double GetTrendStrength(ENUM_TIMEFRAMES tf)
    {
        ENUM_TREND_DIRECTION trend = AnalyzeTrend(tf);
        return CalculateTrendStrength(tf, trend);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar alinhamento de tendências                             |
    //+------------------------------------------------------------------+
    bool AreTrendsAligned()
    {
        ENUM_TREND_DIRECTION trendH4 = AnalyzeTrend(PERIOD_H4);
        ENUM_TREND_DIRECTION trendH1 = AnalyzeTrend(PERIOD_H1);
        ENUM_TREND_DIRECTION trendM15 = AnalyzeTrend(PERIOD_M15);
        ENUM_TREND_DIRECTION trendM5 = AnalyzeTrend(PERIOD_M5);
        
        // Verificar se todas as tendências apontam na mesma direção
        if(trendH4 == TREND_NEUTRAL || trendH1 == TREND_NEUTRAL || 
           trendM15 == TREND_NEUTRAL || trendM5 == TREND_NEUTRAL)
        {
            return false;
        }
        
        return (trendH4 == trendH1 && trendH1 == trendM15 && trendM15 == trendM5);
    }
    
    //+------------------------------------------------------------------+
    //| Obter símbolo atual                                             |
    //+------------------------------------------------------------------+
    string GetSymbol() const { return m_symbol; }
    
    //+------------------------------------------------------------------+
    //| Obter valor do ponto                                            |
    //+------------------------------------------------------------------+
    double GetPointValue() const { return m_pointValue; }
    
    //+------------------------------------------------------------------+
    //| Verificar se está inicializado                                  |
    //+------------------------------------------------------------------+
    bool IsInitialized() const { return m_initialized; }

private:
    //+------------------------------------------------------------------+
    //| Obter dados históricos                                          |
    //+------------------------------------------------------------------+
    bool GetHistoricalData(ENUM_TIMEFRAMES tf, int bars)
    {
        // Redimensionar arrays
        if(ArrayResize(m_high, bars) < 0 ||
           ArrayResize(m_low, bars) < 0 ||
           ArrayResize(m_close, bars) < 0 ||
           ArrayResize(m_time, bars) < 0 ||
           ArrayResize(m_volume, bars) < 0)
        {
            CCoreUtils::LogError("Falha ao redimensionar arrays de histórico");
            return false;
        }

        // Copiar dados com tentativa de recuperação
        bool success = false;
        for(int attempt=0; attempt<2 && !success; attempt++)
        {
            int highCopied   = CopyHigh(m_symbol, tf, 0, bars, m_high);
            int lowCopied    = CopyLow(m_symbol, tf, 0, bars, m_low);
            int closeCopied  = CopyClose(m_symbol, tf, 0, bars, m_close);
            int timeCopied   = CopyTime(m_symbol, tf, 0, bars, m_time);
            int volumeCopied = CopyTickVolume(m_symbol, tf, 0, bars, m_volume);

            if(highCopied == bars && lowCopied == bars &&
               closeCopied == bars && timeCopied == bars &&
               volumeCopied == bars)
            {
                success = true;
            }
            else
            {
                CCoreUtils::LogWarning("Falha ao copiar histórico (tentativa " +
                                      IntegerToString(attempt+1) + ") - High:" +
                                      IntegerToString(highCopied) +
                                      " Low:" + IntegerToString(lowCopied) +
                                      " Close:" + IntegerToString(closeCopied) +
                                      " Time:" + IntegerToString(timeCopied));
                // Aguarda um curto período para nova tentativa
                Sleep(50);
            }
        }

        if(!success)
        {
            CCoreUtils::LogError("Falha definitiva ao copiar histórico");
            return false;
        }

        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar disponibilidade do timeframe                         |
    //+------------------------------------------------------------------+
    bool IsTimeframeAvailable(ENUM_TIMEFRAMES tf)
    {
        double testArray[];
        int result = CopyClose(m_symbol, tf, 0, 1, testArray);
        ArrayFree(testArray);
        
        return (result > 0);
    }
    
    //+------------------------------------------------------------------+
    //| Cache do resultado de tendência                                 |
    //+------------------------------------------------------------------+
    void CacheTrendResult(ENUM_TIMEFRAMES tf, ENUM_TREND_DIRECTION trend)
    {
        switch(tf)
        {
            case PERIOD_H4:  m_lastTrendH4 = trend; break;
            case PERIOD_H1:  m_lastTrendH1 = trend; break;
            case PERIOD_M15: m_lastTrendM15 = trend; break;
            case PERIOD_M5:  m_lastTrendM5 = trend; break;
        }
        
        m_lastUpdate = TimeCurrent();
    }
};

#endif // TREND_ANALYZER_H

