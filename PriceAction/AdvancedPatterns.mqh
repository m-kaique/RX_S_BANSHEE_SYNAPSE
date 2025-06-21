//+------------------------------------------------------------------+
//| AdvancedPatterns.mqh - Padrões Avançados de Price Action        |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef ADVANCED_PATTERNS_H
#define ADVANCED_PATTERNS_H

#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "../Core/CoreUtils.mqh"
#include <Object.mqh>

//+------------------------------------------------------------------+
//| Classe de Padrões Avançados                                     |
//+------------------------------------------------------------------+
class CAdvancedPatterns : public CObject
{
private:
    string               m_symbol;           // Símbolo
    
    // Arrays para análise
    double               m_high[];           // Máximas
    double               m_low[];            // Mínimas
    double               m_close[];          // Fechamentos
    double               m_open[];           // Aberturas
    datetime             m_time[];           // Tempos
    long                 m_volume[];         // Volume
    
    // Cache de padrões identificados
    bool                 m_spikeAndChannelDetected;
    bool                 m_trendFromOpenDetected;
    bool                 m_smallPullbackTrendDetected;
    datetime             m_lastPatternUpdate;
    
public:
    //+------------------------------------------------------------------+
    //| Construtor                                                       |
    //+------------------------------------------------------------------+
    CAdvancedPatterns()
    {
        m_symbol = "";
        m_spikeAndChannelDetected = false;
        m_trendFromOpenDetected = false;
        m_smallPullbackTrendDetected = false;
        m_lastPatternUpdate = 0;
        
        ArraySetAsSeries(m_high, true);
        ArraySetAsSeries(m_low, true);
        ArraySetAsSeries(m_close, true);
        ArraySetAsSeries(m_open, true);
        ArraySetAsSeries(m_time, true);
        ArraySetAsSeries(m_volume, true);
    }
    
    //+------------------------------------------------------------------+
    //| Destrutor                                                        |
    //+------------------------------------------------------------------+
    ~CAdvancedPatterns()
    {
        ArrayFree(m_high);
        ArrayFree(m_low);
        ArrayFree(m_close);
        ArrayFree(m_open);
        ArrayFree(m_time);
        ArrayFree(m_volume);
    }
    
    //+------------------------------------------------------------------+
    //| Inicializar com símbolo                                         |
    //+------------------------------------------------------------------+
    bool Initialize(string symbol)
    {
        if(symbol == "" || symbol == NULL)
        {
            CCoreUtils::LogError("Símbolo inválido para AdvancedPatterns");
            return false;
        }
        
        m_symbol = symbol;
        CCoreUtils::LogInfo("AdvancedPatterns inicializado para " + symbol);
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Detectar padrão Spike and Channel                              |
    //+------------------------------------------------------------------+
    bool DetectSpikeAndChannel(string symbol, ENUM_TIMEFRAMES tf)
    {
        if(symbol != "") m_symbol = symbol;
        
        // Obter dados históricos
        if(!GetHistoricalData(tf, HISTORY_BARS_PATTERN))
        {
            CCoreUtils::LogError("Falha ao obter dados para Spike and Channel");
            return false;
        }
        
        // Calcular ATR para referência
        double atr = CCoreUtils::CalculateATR(m_high, m_low, m_close, 20, 20);
        if(atr <= 0)
        {
            CCoreUtils::LogError("ATR inválido para análise de spike");
            return false;
        }
        
        // Procurar spike nas últimas barras
        bool spikeFound = false;
        int spikeStartIndex = -1;
        int spikeEndIndex = -1;
        
        for(int i = SPIKE_MAX_BARS; i < 20; i++) // Procurar nos últimos 20 barras
        {
            if(DetectSpike(i, atr, spikeStartIndex, spikeEndIndex))
            {
                spikeFound = true;
                break;
            }
        }
        
        if(!spikeFound)
        {
            m_spikeAndChannelDetected = false;
            return false;
        }
        
        // Verificar se há canal subsequente
        bool channelFound = DetectSubsequentChannel(spikeEndIndex, atr);
        
        m_spikeAndChannelDetected = channelFound;
        m_lastPatternUpdate = TimeCurrent();
        
        if(channelFound)
        {
            CCoreUtils::LogInfo("Padrão Spike and Channel detectado");
        }
        
        return channelFound;
    }
    
    //+------------------------------------------------------------------+
    //| Detectar padrão Trend from the Open                            |
    //+------------------------------------------------------------------+
    bool DetectTrendFromOpen(string symbol)
    {
        if(symbol != "") m_symbol = symbol;
        
        // Obter dados do dia atual em M15
        if(!GetHistoricalData(PERIOD_M15, 100))
        {
            CCoreUtils::LogError("Falha ao obter dados para Trend from Open");
            return false;
        }
        
        // Encontrar abertura do dia
        datetime todayStart = GetDayStart(TimeCurrent());
        int openIndex = FindTimeIndex(todayStart);
        
        if(openIndex == -1)
        {
            CCoreUtils::LogWarning("Não foi possível encontrar abertura do dia");
            return false;
        }
        
        // Verificar movimento direcional nos primeiros 60 minutos (4 barras de M15)
        int barsToCheck = MathMin(4, openIndex);
        if(barsToCheck < 2)
        {
            return false; // Dados insuficientes
        }
        
        double openPrice = m_open[openIndex];
        double currentPrice = m_close[0];
        
        // Calcular movimento total
        double totalMove = MathAbs(currentPrice - openPrice);
        double atr = CCoreUtils::CalculateATR(m_high, m_low, m_close, 20, 20);
        
        // Movimento deve ser significativo (> 0.5 ATR)
        if(totalMove < atr * 0.5)
        {
            m_trendFromOpenDetected = false;
            return false;
        }
        
        // Verificar direção consistente
        bool isUpTrend = (currentPrice > openPrice);
        bool directionConsistent = true;
        double maxPullback = 0;
        
        for(int i = openIndex - 1; i >= 0; i--)
        {
            if(isUpTrend)
            {
                // Para tendência de alta, verificar pullbacks
                double pullback = m_high[i] - m_low[i];
                maxPullback = MathMax(maxPullback, pullback);
                
                // Verificar se houve reversão significativa
                if(m_close[i] < openPrice - (totalMove * 0.3))
                {
                    directionConsistent = false;
                    break;
                }
            }
            else
            {
                // Para tendência de baixa, verificar repiques
                double pullback = m_high[i] - m_low[i];
                maxPullback = MathMax(maxPullback, pullback);
                
                // Verificar se houve reversão significativa
                if(m_close[i] > openPrice + (totalMove * 0.3))
                {
                    directionConsistent = false;
                    break;
                }
            }
        }
        
        // Pullbacks devem ser menores que 30% do movimento
        bool pullbacksSmall = (maxPullback < totalMove * 0.3);
        
        m_trendFromOpenDetected = (directionConsistent && pullbacksSmall);
        m_lastPatternUpdate = TimeCurrent();
        
        if(m_trendFromOpenDetected)
        {
            CCoreUtils::LogInfo("Padrão Trend from Open detectado. Direção: " + 
                              (isUpTrend ? "ALTA" : "BAIXA"));
        }
        
        return m_trendFromOpenDetected;
    }
    
    //+------------------------------------------------------------------+
    //| Detectar padrão Small Pullback Trend                           |
    //+------------------------------------------------------------------+
    bool DetectSmallPullbackTrend(string symbol, ENUM_TIMEFRAMES tf)
    {
        if(symbol != "") m_symbol = symbol;
        
        // Obter dados históricos
        if(!GetHistoricalData(tf, HISTORY_BARS_PATTERN))
        {
            CCoreUtils::LogError("Falha ao obter dados para Small Pullback Trend");
            return false;
        }
        
        // Analisar últimas 50 barras
        int barsToAnalyze = MathMin(50, ArraySize(m_close));
        if(barsToAnalyze < 10) return false;
        
        // Determinar direção da tendência principal
        double startPrice = m_close[barsToAnalyze - 1];
        double endPrice = m_close[0];
        bool isUpTrend = (endPrice > startPrice);
        
        // Calcular movimento total
        double totalMove = MathAbs(endPrice - startPrice);
        double atr = CCoreUtils::CalculateATR(m_high, m_low, m_close, 20, 20);
        
        // Movimento deve ser significativo
        if(totalMove < atr * 1.5)
        {
            m_smallPullbackTrendDetected = false;
            return false;
        }
        
        // Identificar pullbacks
        int pullbackCount = 0;
        int maxPullbackBars = 0;
        double maxPullbackPercent = 0;
        
        bool inPullback = false;
        int pullbackStartIndex = 0;
        double pullbackStartPrice = 0;
        
        for(int i = barsToAnalyze - 2; i >= 0; i--)
        {
            bool isPullbackBar = false;
            
            if(isUpTrend)
            {
                // Em tendência de alta, pullback é movimento para baixo
                isPullbackBar = (m_close[i] < m_close[i + 1]);
            }
            else
            {
                // Em tendência de baixa, pullback é movimento para cima
                isPullbackBar = (m_close[i] > m_close[i + 1]);
            }
            
            if(isPullbackBar && !inPullback)
            {
                // Início de pullback
                inPullback = true;
                pullbackStartIndex = i + 1;
                pullbackStartPrice = m_close[i + 1];
                pullbackCount++;
            }
            else if(!isPullbackBar && inPullback)
            {
                // Fim de pullback
                inPullback = false;
                
                // Calcular características do pullback
                int pullbackBars = pullbackStartIndex - i;
                double pullbackMove = MathAbs(m_close[i] - pullbackStartPrice);
                double pullbackPercent = (pullbackMove / totalMove) * 100.0;
                
                maxPullbackBars = MathMax(maxPullbackBars, pullbackBars);
                maxPullbackPercent = MathMax(maxPullbackPercent, pullbackPercent);
            }
        }
        
        // Validar critérios de Small Pullback Trend
        bool smallPullbacks = (maxPullbackBars <= MAX_PULLBACK_BARS && 
                              maxPullbackPercent <= MAX_PULLBACK_PERCENT);
        
        bool fewPullbacks = (pullbackCount <= barsToAnalyze / 10); // Máximo 10% das barras em pullback
        
        m_smallPullbackTrendDetected = (smallPullbacks && fewPullbacks);
        m_lastPatternUpdate = TimeCurrent();
        
        if(m_smallPullbackTrendDetected)
        {
            CCoreUtils::LogInfo("Padrão Small Pullback Trend detectado. Pullbacks máx: " + 
                              IntegerToString(maxPullbackBars) + " barras, " + 
                              DoubleToString(maxPullbackPercent, 1) + "%");
        }
        
        return m_smallPullbackTrendDetected;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se Spike and Channel está ativo                      |
    //+------------------------------------------------------------------+
    bool IsSpikeAndChannelActive() const
    {
        return m_spikeAndChannelDetected && IsPatternRecent();
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se Trend from Open está ativo                        |
    //+------------------------------------------------------------------+
    bool IsTrendFromOpenActive() const
    {
        return m_trendFromOpenDetected && IsPatternRecent();
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se Small Pullback Trend está ativo                   |
    //+------------------------------------------------------------------+
    bool IsSmallPullbackTrendActive() const
    {
        return m_smallPullbackTrendDetected && IsPatternRecent();
    }
    
    //+------------------------------------------------------------------+
    //| Obter força dos padrões (0-100)                                |
    //+------------------------------------------------------------------+
    double GetPatternStrength()
    {
        double strength = 0;
        
        if(IsSpikeAndChannelActive()) strength += 30;
        if(IsTrendFromOpenActive()) strength += 40;
        if(IsSmallPullbackTrendActive()) strength += 30;
        
        return MathMin(100, strength);
    }

private:
    //+------------------------------------------------------------------+
    //| Obter dados históricos                                          |
    //+------------------------------------------------------------------+
    bool GetHistoricalData(ENUM_TIMEFRAMES tf, int bars)
    {
        if(ArrayResize(m_high, bars) < 0 || 
           ArrayResize(m_low, bars) < 0 ||
           ArrayResize(m_close, bars) < 0 ||
           ArrayResize(m_open, bars) < 0 ||
           ArrayResize(m_time, bars) < 0 ||
           ArrayResize(m_volume, bars) < 0)
        {
            return false;
        }
        
        if(CopyHigh(m_symbol, tf, 0, bars, m_high) < 0 ||
           CopyLow(m_symbol, tf, 0, bars, m_low) < 0 ||
           CopyClose(m_symbol, tf, 0, bars, m_close) < 0 ||
           CopyOpen(m_symbol, tf, 0, bars, m_open) < 0 ||
           CopyTime(m_symbol, tf, 0, bars, m_time) < 0 ||
           CopyTickVolume(m_symbol, tf, 0, bars, m_volume) < 0)
        {
            return false;
        }
        
        return CCoreUtils::ValidateArrayData(m_high, bars) &&
               CCoreUtils::ValidateArrayData(m_low, bars) &&
               CCoreUtils::ValidateArrayData(m_close, bars);
    }
    
    //+------------------------------------------------------------------+
    //| Detectar spike                                                  |
    //+------------------------------------------------------------------+
    bool DetectSpike(int centerIndex, double atr, int &startIndex, int &endIndex)
    {
        if(centerIndex < SPIKE_MAX_BARS || centerIndex >= ArraySize(m_high) - SPIKE_MAX_BARS)
        {
            return false;
        }
        
        // Definir janela de análise
        startIndex = centerIndex + SPIKE_MAX_BARS;
        endIndex = centerIndex - SPIKE_MAX_BARS;
        
        // Calcular amplitude do movimento
        double highestHigh = m_high[ArrayMaximum(m_high, endIndex, SPIKE_MAX_BARS * 2 + 1)];
        double lowestLow = m_low[ArrayMinimum(m_low, endIndex, SPIKE_MAX_BARS * 2 + 1)];
        double spikeRange = highestHigh - lowestLow;
        
        // Verificar se amplitude é significativa (> 2x ATR)
        if(spikeRange < atr * SPIKE_ATR_MULTIPLIER)
        {
            return false;
        }
        
        // Verificar se movimento foi rápido (dentro de SPIKE_MAX_BARS)
        int movementBars = 0;
        for(int i = startIndex; i >= endIndex; i--)
        {
            if(m_high[i] == highestHigh || m_low[i] == lowestLow)
            {
                movementBars++;
            }
        }
        
        // Spike deve ser concentrado em poucas barras
        return (movementBars <= SPIKE_MAX_BARS);
    }
    
    //+------------------------------------------------------------------+
    //| Detectar canal subsequente ao spike                            |
    //+------------------------------------------------------------------+
    bool DetectSubsequentChannel(int spikeEndIndex, double atr)
    {
        if(spikeEndIndex < 10) return false;
        
        // Analisar barras após o spike
        int channelBars = MathMin(20, spikeEndIndex);
        
        // Calcular range médio das barras do canal
        double totalRange = 0;
        for(int i = spikeEndIndex - 1; i >= spikeEndIndex - channelBars; i--)
        {
            totalRange += (m_high[i] - m_low[i]);
        }
        double avgChannelRange = totalRange / channelBars;
        
        // Canal deve ter movimento mais controlado (< 1.5x ATR por barra)
        if(avgChannelRange > atr * 1.5)
        {
            return false;
        }
        
        // Verificar se há direção definida no canal
        double channelStart = m_close[spikeEndIndex - 1];
        double channelEnd = m_close[spikeEndIndex - channelBars];
        double channelMove = MathAbs(channelEnd - channelStart);
        
        // Canal deve ter movimento direcional mínimo
        return (channelMove > atr * 0.5);
    }
    
    //+------------------------------------------------------------------+
    //| Obter início do dia                                            |
    //+------------------------------------------------------------------+
    datetime GetDayStart(datetime time)
    {
        MqlDateTime dt;
        TimeToStruct(time, dt);
        
        dt.hour = MARKET_OPEN_HOUR;
        dt.min = 0;
        dt.sec = 0;
        
        return StructToTime(dt);
    }
    
    //+------------------------------------------------------------------+
    //| Encontrar índice do tempo                                      |
    //+------------------------------------------------------------------+
    int FindTimeIndex(datetime targetTime)
    {
        for(int i = 0; i < ArraySize(m_time); i++)
        {
            if(m_time[i] <= targetTime)
            {
                return i;
            }
        }
        
        return -1;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se padrão é recente                                  |
    //+------------------------------------------------------------------+
    bool IsPatternRecent() const
    {
        return (TimeCurrent() - m_lastPatternUpdate) < 3600; // 1 hora
    }
};

#endif // ADVANCED_PATTERNS_H

