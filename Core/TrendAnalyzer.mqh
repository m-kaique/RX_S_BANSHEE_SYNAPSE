//+------------------------------------------------------------------+
//| TrendAnalyzer.mqh - Classe Principal de Análise de Tendência    |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef TREND_ANALYZER_H
#define TREND_ANALYZER_H

#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"

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
    //| Obter força da tendência (0-100)                                |
    //+------------------------------------------------------------------+
    double GetTrendStrength(ENUM_TIMEFRAMES tf)
    {
        if(!GetHistoricalData(tf, 50))
            return 0;
        
        double strength = 0;
        int consecutiveBars = 0;
        ENUM_TREND_DIRECTION currentTrend = AnalyzeTrend(tf);
        
        if(currentTrend == TREND_NEUTRAL)
            return 0;
        
        // Contar barras consecutivas na direção da tendência
        for(int i = 1; i < MathMin(20, ArraySize(m_close)); i++)
        {
            bool bullishBar = (m_close[i-1] > m_close[i]);
            bool bearishBar = (m_close[i-1] < m_close[i]);
            
            if((currentTrend == TREND_UP && bullishBar) || 
               (currentTrend == TREND_DOWN && bearishBar))
            {
                consecutiveBars++;
            }
            else
            {
                break;
            }
        }
        
        // Calcular força baseada em barras consecutivas e amplitude
        strength = MathMin(100, consecutiveBars * 5); // Máximo 100%
        
        // Ajustar baseado na amplitude do movimento
        if(ArraySize(m_close) >= 20)
        {
            double highestHigh = m_high[ArrayMaximum(m_high, 0, 20)];
            double lowestLow = m_low[ArrayMinimum(m_low, 0, 20)];
            double range = highestHigh - lowestLow;
            double currentRange = MathAbs(m_close[0] - m_close[19]);
            
            if(range > 0)
            {
                double rangeRatio = currentRange / range;
                strength *= rangeRatio;
            }
        }
        
        return MathMin(100, MathMax(0, strength));
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
           ArrayResize(m_time, bars) < 0)
        {
            return false;
        }
        
        // Copiar dados
        if(CopyHigh(m_symbol, tf, 0, bars, m_high) < 0 ||
           CopyLow(m_symbol, tf, 0, bars, m_low) < 0 ||
           CopyClose(m_symbol, tf, 0, bars, m_close) < 0 ||
           CopyTime(m_symbol, tf, 0, bars, m_time) < 0)
        {
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

