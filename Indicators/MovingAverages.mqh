//+------------------------------------------------------------------+
//| MovingAverages.mqh - Implementação de Médias Móveis             |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef MOVING_AVERAGES_H
#define MOVING_AVERAGES_H

#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "../Core/CoreUtils.mqh"

//+------------------------------------------------------------------+
//| Classe de Médias Móveis                                         |
//+------------------------------------------------------------------+
class CMovingAverages : public CObject
{
private:
    string               m_symbol;           // Símbolo
    
    // Handles dos indicadores
    int                  m_handleEMA9;       // Handle EMA 9 (M15)
    int                  m_handleEMA21;      // Handle EMA 21 (M15)
    int                  m_handleEMA50;      // Handle EMA 50 (H1)
    int                  m_handleSMA200;     // Handle SMA 200 (H4)
    
    // Arrays de dados
    double               m_ema9[];           // Valores EMA 9
    double               m_ema21[];          // Valores EMA 21
    double               m_ema50[];          // Valores EMA 50
    double               m_sma200[];         // Valores SMA 200
    
    // Cache de valores atuais
    double               m_currentEMA9;      // EMA 9 atual
    double               m_currentEMA21;     // EMA 21 atual
    double               m_currentEMA50;     // EMA 50 atual
    double               m_currentSMA200;    // SMA 200 atual
    
    datetime             m_lastUpdate;       // Última atualização
    bool                 m_initialized;      // Status de inicialização
    
public:
    //+------------------------------------------------------------------+
    //| Construtor                                                       |
    //+------------------------------------------------------------------+
    CMovingAverages()
    {
        m_symbol = "";
        m_handleEMA9 = INVALID_HANDLE;
        m_handleEMA21 = INVALID_HANDLE;
        m_handleEMA50 = INVALID_HANDLE;
        m_handleSMA200 = INVALID_HANDLE;
        
        m_currentEMA9 = 0;
        m_currentEMA21 = 0;
        m_currentEMA50 = 0;
        m_currentSMA200 = 0;
        
        m_lastUpdate = 0;
        m_initialized = false;
        
        // Configurar arrays como séries
        ArraySetAsSeries(m_ema9, true);
        ArraySetAsSeries(m_ema21, true);
        ArraySetAsSeries(m_ema50, true);
        ArraySetAsSeries(m_sma200, true);
    }
    
    //+------------------------------------------------------------------+
    //| Destrutor                                                        |
    //+------------------------------------------------------------------+
    ~CMovingAverages()
    {
        // Liberar handles
        if(m_handleEMA9 != INVALID_HANDLE) IndicatorRelease(m_handleEMA9);
        if(m_handleEMA21 != INVALID_HANDLE) IndicatorRelease(m_handleEMA21);
        if(m_handleEMA50 != INVALID_HANDLE) IndicatorRelease(m_handleEMA50);
        if(m_handleSMA200 != INVALID_HANDLE) IndicatorRelease(m_handleSMA200);
        
        // Liberar arrays
        ArrayFree(m_ema9);
        ArrayFree(m_ema21);
        ArrayFree(m_ema50);
        ArrayFree(m_sma200);
    }
    
    //+------------------------------------------------------------------+
    //| Inicializar médias móveis                                       |
    //+------------------------------------------------------------------+
    bool Initialize(string symbol)
    {
        if(symbol == "" || symbol == NULL)
        {
            CCoreUtils::LogError("Símbolo inválido para MovingAverages");
            return false;
        }
        
        m_symbol = symbol;
        
        // Criar handles dos indicadores conforme especificações do guia
        
        // EMA 9 e EMA 21 em M15
        m_handleEMA9 = iMA(m_symbol, PERIOD_M15, MA_PERIOD_9, 0, MA_METHOD_EMA, PRICE_CLOSE);
        m_handleEMA21 = iMA(m_symbol, PERIOD_M15, MA_PERIOD_21, 0, MA_METHOD_EMA, PRICE_CLOSE);
        
        // EMA 50 em H1
        m_handleEMA50 = iMA(m_symbol, PERIOD_H1, MA_PERIOD_50, 0, MA_METHOD_EMA, PRICE_CLOSE);
        
        // SMA 200 em H4
        m_handleSMA200 = iMA(m_symbol, PERIOD_H4, MA_PERIOD_200, 0, MA_METHOD_SMA, PRICE_CLOSE);
        
        // Verificar se todos os handles são válidos
        if(m_handleEMA9 == INVALID_HANDLE)
        {
            CCoreUtils::LogError("Falha ao criar handle EMA 9");
            return false;
        }
        
        if(m_handleEMA21 == INVALID_HANDLE)
        {
            CCoreUtils::LogError("Falha ao criar handle EMA 21");
            return false;
        }
        
        if(m_handleEMA50 == INVALID_HANDLE)
        {
            CCoreUtils::LogError("Falha ao criar handle EMA 50");
            return false;
        }
        
        if(m_handleSMA200 == INVALID_HANDLE)
        {
            CCoreUtils::LogError("Falha ao criar handle SMA 200");
            return false;
        }
        
        // Aguardar cálculo inicial dos indicadores
        Sleep(100);
        
        // Fazer primeira atualização
        if(!UpdateValues())
        {
            CCoreUtils::LogError("Falha na atualização inicial das médias");
            return false;
        }
        
        m_initialized = true;
        CCoreUtils::LogInfo("MovingAverages inicializado com sucesso para " + symbol);
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Atualizar valores das médias                                    |
    //+------------------------------------------------------------------+
    bool UpdateValues()
    {
        if(!m_initialized)
        {
            CCoreUtils::LogError("MovingAverages não inicializado");
            return false;
        }
        
        // Copiar valores dos indicadores
        if(CopyBuffer(m_handleEMA9, 0, 0, 3, m_ema9) < 0)
        {
            CCoreUtils::LogError("Falha ao copiar dados EMA 9");
            return false;
        }
        
        if(CopyBuffer(m_handleEMA21, 0, 0, 3, m_ema21) < 0)
        {
            CCoreUtils::LogError("Falha ao copiar dados EMA 21");
            return false;
        }
        
        if(CopyBuffer(m_handleEMA50, 0, 0, 3, m_ema50) < 0)
        {
            CCoreUtils::LogError("Falha ao copiar dados EMA 50");
            return false;
        }
        
        if(CopyBuffer(m_handleSMA200, 0, 0, 3, m_sma200) < 0)
        {
            CCoreUtils::LogError("Falha ao copiar dados SMA 200");
            return false;
        }
        
        // Atualizar valores atuais
        m_currentEMA9 = m_ema9[0];
        m_currentEMA21 = m_ema21[0];
        m_currentEMA50 = m_ema50[0];
        m_currentSMA200 = m_sma200[0];
        
        m_lastUpdate = TimeCurrent();
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Obter alinhamento das médias                                    |
    //+------------------------------------------------------------------+
    ENUM_MA_ALIGNMENT GetAlignment()
    {
        if(!m_initialized || !UpdateValues())
        {
            return MA_NEUTRAL;
        }
        
        // Verificar alinhamento bullish: EMA9 > EMA21 > EMA50 > SMA200
        if(m_currentEMA9 > m_currentEMA21 && 
           m_currentEMA21 > m_currentEMA50 && 
           m_currentEMA50 > m_currentSMA200)
        {
            return MA_BULLISH;
        }
        
        // Verificar alinhamento bearish: EMA9 < EMA21 < EMA50 < SMA200
        if(m_currentEMA9 < m_currentEMA21 && 
           m_currentEMA21 < m_currentEMA50 && 
           m_currentEMA50 < m_currentSMA200)
        {
            return MA_BEARISH;
        }
        
        return MA_NEUTRAL;
    }
    
    //+------------------------------------------------------------------+
    //| Obter distância do preço à média especificada                  |
    //+------------------------------------------------------------------+
    double GetDistanceToMA(double price, int maPeriod)
    {
        if(!m_initialized)
        {
            return 0;
        }
        
        double maValue = 0;
        
        switch(maPeriod)
        {
            case MA_PERIOD_9:   maValue = m_currentEMA9; break;
            case MA_PERIOD_21:  maValue = m_currentEMA21; break;
            case MA_PERIOD_50:  maValue = m_currentEMA50; break;
            case MA_PERIOD_200: maValue = m_currentSMA200; break;
            default:
                CCoreUtils::LogError("Período de média inválido: " + IntegerToString(maPeriod));
                return 0;
        }
        
        if(maValue == 0) return 0;
        
        // Retornar distância em pontos
        return CCoreUtils::PriceToPoints(price - maValue, m_symbol);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está próximo da EMA21                       |
    //+------------------------------------------------------------------+
    bool IsNearMA21(double price, double tolerance)
    {
        if(!m_initialized || m_currentEMA21 == 0)
        {
            return false;
        }
        
        return CCoreUtils::IsPriceWithinTolerance(price, m_currentEMA21, tolerance, m_symbol);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está próximo da EMA50                       |
    //+------------------------------------------------------------------+
    bool IsNearMA50(double price, double tolerance)
    {
        if(!m_initialized || m_currentEMA50 == 0)
        {
            return false;
        }
        
        return CCoreUtils::IsPriceWithinTolerance(price, m_currentEMA50, tolerance, m_symbol);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está acima da SMA200                        |
    //+------------------------------------------------------------------+
    bool IsPriceAboveSMA200(double price)
    {
        if(!m_initialized || m_currentSMA200 == 0)
        {
            return false;
        }
        
        return (price > m_currentSMA200);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está abaixo da SMA200                       |
    //+------------------------------------------------------------------+
    bool IsPriceBelowSMA200(double price)
    {
        if(!m_initialized || m_currentSMA200 == 0)
        {
            return false;
        }
        
        return (price < m_currentSMA200);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar inclinação da média                                  |
    //+------------------------------------------------------------------+
    bool IsMASloping(int maPeriod, bool upward)
    {
        if(!m_initialized)
        {
            return false;
        }
        
        double currentValue = 0;
        double previousValue = 0;
        
        switch(maPeriod)
        {
            case MA_PERIOD_9:
                if(ArraySize(m_ema9) < 2) return false;
                currentValue = m_ema9[0];
                previousValue = m_ema9[1];
                break;
                
            case MA_PERIOD_21:
                if(ArraySize(m_ema21) < 2) return false;
                currentValue = m_ema21[0];
                previousValue = m_ema21[1];
                break;
                
            case MA_PERIOD_50:
                if(ArraySize(m_ema50) < 2) return false;
                currentValue = m_ema50[0];
                previousValue = m_ema50[1];
                break;
                
            case MA_PERIOD_200:
                if(ArraySize(m_sma200) < 2) return false;
                currentValue = m_sma200[0];
                previousValue = m_sma200[1];
                break;
                
            default:
                return false;
        }
        
        if(upward)
        {
            return (currentValue > previousValue);
        }
        else
        {
            return (currentValue < previousValue);
        }
    }
    
    //+------------------------------------------------------------------+
    //| Obter valor atual da EMA9                                      |
    //+------------------------------------------------------------------+
    double GetEMA9() const { return m_currentEMA9; }
    
    //+------------------------------------------------------------------+
    //| Obter valor atual da EMA21                                     |
    //+------------------------------------------------------------------+
    double GetEMA21() const { return m_currentEMA21; }
    
    //+------------------------------------------------------------------+
    //| Obter valor atual da EMA50                                     |
    //+------------------------------------------------------------------+
    double GetEMA50() const { return m_currentEMA50; }
    
    //+------------------------------------------------------------------+
    //| Obter valor atual da SMA200                                    |
    //+------------------------------------------------------------------+
    double GetSMA200() const { return m_currentSMA200; }
    
    //+------------------------------------------------------------------+
    //| Verificar se está inicializado                                 |
    //+------------------------------------------------------------------+
    bool IsInitialized() const { return m_initialized; }
    
    //+------------------------------------------------------------------+
    //| Obter força do alinhamento (0-100)                             |
    //+------------------------------------------------------------------+
    double GetAlignmentStrength()
    {
        if(!m_initialized)
        {
            return 0;
        }
        
        ENUM_MA_ALIGNMENT alignment = GetAlignment();
        if(alignment == MA_NEUTRAL)
        {
            return 0;
        }
        
        // Calcular força baseada na separação entre médias
        double totalSeparation = 0;
        double maxSeparation = 0;
        
        if(alignment == MA_BULLISH)
        {
            totalSeparation = (m_currentEMA9 - m_currentEMA21) + 
                             (m_currentEMA21 - m_currentEMA50) + 
                             (m_currentEMA50 - m_currentSMA200);
            maxSeparation = m_currentEMA9 - m_currentSMA200;
        }
        else // MA_BEARISH
        {
            totalSeparation = (m_currentEMA21 - m_currentEMA9) + 
                             (m_currentEMA50 - m_currentEMA21) + 
                             (m_currentSMA200 - m_currentEMA50);
            maxSeparation = m_currentSMA200 - m_currentEMA9;
        }
        
        if(maxSeparation == 0) return 0;
        
        // Força baseada na uniformidade da separação
        double uniformity = totalSeparation / (maxSeparation * 3);
        
        return MathMin(100, MathMax(0, uniformity * 100));
    }
    
    //+------------------------------------------------------------------+
    //| Verificar cruzamento de médias                                 |
    //+------------------------------------------------------------------+
    bool IsMAsCrossing(int fastPeriod, int slowPeriod, bool bullishCross)
    {
        if(!m_initialized)
        {
            return false;
        }
        
        double fastCurrent = 0, fastPrevious = 0;
        double slowCurrent = 0, slowPrevious = 0;
        
        // Obter valores das médias
        switch(fastPeriod)
        {
            case MA_PERIOD_9:
                if(ArraySize(m_ema9) < 2) return false;
                fastCurrent = m_ema9[0];
                fastPrevious = m_ema9[1];
                break;
            case MA_PERIOD_21:
                if(ArraySize(m_ema21) < 2) return false;
                fastCurrent = m_ema21[0];
                fastPrevious = m_ema21[1];
                break;
            default: return false;
        }
        
        switch(slowPeriod)
        {
            case MA_PERIOD_21:
                if(ArraySize(m_ema21) < 2) return false;
                slowCurrent = m_ema21[0];
                slowPrevious = m_ema21[1];
                break;
            case MA_PERIOD_50:
                if(ArraySize(m_ema50) < 2) return false;
                slowCurrent = m_ema50[0];
                slowPrevious = m_ema50[1];
                break;
            default: return false;
        }
        
        if(bullishCross)
        {
            // Cruzamento bullish: média rápida cruza acima da lenta
            return (fastPrevious <= slowPrevious && fastCurrent > slowCurrent);
        }
        else
        {
            // Cruzamento bearish: média rápida cruza abaixo da lenta
            return (fastPrevious >= slowPrevious && fastCurrent < slowCurrent);
        }
    }
    
    //+------------------------------------------------------------------+
    //| Obter informações de debug                                     |
    //+------------------------------------------------------------------+
    string GetDebugInfo()
    {
        if(!m_initialized)
        {
            return "MovingAverages não inicializado";
        }
        
        string info = "=== MÉDIAS MÓVEIS ===\n";
        info += "EMA9 (M15): " + DoubleToString(m_currentEMA9, 2) + "\n";
        info += "EMA21 (M15): " + DoubleToString(m_currentEMA21, 2) + "\n";
        info += "EMA50 (H1): " + DoubleToString(m_currentEMA50, 2) + "\n";
        info += "SMA200 (H4): " + DoubleToString(m_currentSMA200, 2) + "\n";
        
        ENUM_MA_ALIGNMENT alignment = GetAlignment();
        string alignmentStr = "";
        switch(alignment)
        {
            case MA_BULLISH: alignmentStr = "BULLISH"; break;
            case MA_BEARISH: alignmentStr = "BEARISH"; break;
            case MA_NEUTRAL: alignmentStr = "NEUTRAL"; break;
        }
        
        info += "Alinhamento: " + alignmentStr + "\n";
        info += "Força do alinhamento: " + DoubleToString(GetAlignmentStrength(), 1) + "%\n";
        info += "Última atualização: " + TimeToString(m_lastUpdate, TIME_DATE|TIME_SECONDS);
        
        return info;
    }
};

#endif // MOVING_AVERAGES_H

