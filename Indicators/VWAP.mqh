//+------------------------------------------------------------------+
//| VWAP.mqh - Volume Weighted Average Price                        |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef VWAP_H
#define VWAP_H

#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "../Core/CoreUtils.mqh"

//+------------------------------------------------------------------+
//| Classe VWAP                                                      |
//+------------------------------------------------------------------+
class CVWAP : public CObject
{
private:
    string               m_symbol;           // Símbolo
    
    // Dados para cálculo
    double               m_vwapValue;        // Valor atual do VWAP
    double               m_vwapSD1Plus;      // VWAP + 1 desvio padrão
    double               m_vwapSD1Minus;     // VWAP - 1 desvio padrão
    double               m_vwapSD2Plus;      // VWAP + 2 desvios padrão
    double               m_vwapSD2Minus;     // VWAP - 2 desvios padrão
    double               m_vwapSD3Plus;      // VWAP + 3 desvios padrão
    double               m_vwapSD3Minus;     // VWAP - 3 desvios padrão
    
    // Acumuladores
    double               m_sumPriceVolume;   // Soma (preço típico * volume)
    double               m_sumVolume;        // Soma do volume
    double               m_sumPriceVolumeSquared; // Para cálculo do desvio padrão
    
    datetime             m_lastReset;        // Último reset (início do dia)
    datetime             m_lastUpdate;       // Última atualização
    bool                 m_initialized;      // Status de inicialização
    
    // Arrays para dados históricos
    double               m_high[];           // Máximas
    double               m_low[];            // Mínimas
    double               m_close[];          // Fechamentos
    datetime             m_time[];           // Tempos
    long                 m_volume[];         // Volume
    
public:
    //+------------------------------------------------------------------+
    //| Construtor                                                       |
    //+------------------------------------------------------------------+
    CVWAP()
    {
        m_symbol = "";
        m_vwapValue = 0;
        m_vwapSD1Plus = 0;
        m_vwapSD1Minus = 0;
        m_vwapSD2Plus = 0;
        m_vwapSD2Minus = 0;
        m_vwapSD3Plus = 0;
        m_vwapSD3Minus = 0;
        
        m_sumPriceVolume = 0;
        m_sumVolume = 0;
        m_sumPriceVolumeSquared = 0;
        
        m_lastReset = 0;
        m_lastUpdate = 0;
        m_initialized = false;
        
        ArraySetAsSeries(m_high, true);
        ArraySetAsSeries(m_low, true);
        ArraySetAsSeries(m_close, true);
        ArraySetAsSeries(m_time, true);
        ArraySetAsSeries(m_volume, true);
    }
    
    //+------------------------------------------------------------------+
    //| Destrutor                                                        |
    //+------------------------------------------------------------------+
    ~CVWAP()
    {
        ArrayFree(m_high);
        ArrayFree(m_low);
        ArrayFree(m_close);
        ArrayFree(m_time);
        ArrayFree(m_volume);
    }
    
    //+------------------------------------------------------------------+
    //| Inicializar VWAP                                               |
    //+------------------------------------------------------------------+
    bool Initialize(string symbol)
    {
        if(symbol == "" || symbol == NULL)
        {
            CCoreUtils::LogError("Símbolo inválido para VWAP");
            return false;
        }
        
        m_symbol = symbol;
        
        // Definir reset para início do dia atual
        datetime currentTime = TimeCurrent();
        m_lastReset = GetDayStart(currentTime);
        
        // Calcular VWAP inicial
        if(!Calculate(symbol, PERIOD_M15))
        {
            CCoreUtils::LogError("Falha no cálculo inicial do VWAP");
            return false;
        }
        
        m_initialized = true;
        CCoreUtils::LogInfo("VWAP inicializado com sucesso para " + symbol);
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular VWAP                                                  |
    //+------------------------------------------------------------------+
    void Calculate(string symbol, ENUM_TIMEFRAMES tf)
    {
        if(symbol != "") m_symbol = symbol;
        
        // Verificar se precisa resetar (novo dia)
        datetime currentTime = TimeCurrent();
        datetime todayStart = GetDayStart(currentTime);
        
        if(todayStart > m_lastReset)
        {
            ResetVWAP(todayStart);
        }
        
        // Obter dados desde o reset
        if(!GetHistoricalDataSinceReset(tf))
        {
            CCoreUtils::LogError("Falha ao obter dados para VWAP");
            return;
        }
        
        // Recalcular VWAP completo
        CalculateVWAPFromData();
        
        m_lastUpdate = currentTime;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está acima do VWAP                          |
    //+------------------------------------------------------------------+
    bool IsPriceAboveVWAP(double currentPrice)
    {
        if(!m_initialized || m_vwapValue == 0)
        {
            return false;
        }
        
        return (currentPrice > m_vwapValue);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está abaixo do VWAP                         |
    //+------------------------------------------------------------------+
    bool IsPriceBelowVWAP(double currentPrice)
    {
        if(!m_initialized || m_vwapValue == 0)
        {
            return false;
        }
        
        return (currentPrice < m_vwapValue);
    }
    
    //+------------------------------------------------------------------+
    //| Obter distância do preço ao VWAP                               |
    //+------------------------------------------------------------------+
    double GetVWAPDistance(double currentPrice)
    {
        if(!m_initialized || m_vwapValue == 0)
        {
            return 0;
        }
        
        return CCoreUtils::PriceToPoints(currentPrice - m_vwapValue, m_symbol);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está próximo do VWAP                        |
    //+------------------------------------------------------------------+
    bool IsPriceNearVWAP(double currentPrice, double tolerance)
    {
        if(!m_initialized || m_vwapValue == 0)
        {
            return false;
        }
        
        return CCoreUtils::IsPriceWithinTolerance(currentPrice, m_vwapValue, tolerance, m_symbol);
    }
    
    //+------------------------------------------------------------------+
    //| Obter nível de desvio padrão do preço                          |
    //+------------------------------------------------------------------+
    int GetPriceDeviationLevel(double currentPrice)
    {
        if(!m_initialized || m_vwapValue == 0)
        {
            return 0;
        }
        
        if(currentPrice >= m_vwapSD3Plus || currentPrice <= m_vwapSD3Minus)
        {
            return 3; // ±3 sigma
        }
        else if(currentPrice >= m_vwapSD2Plus || currentPrice <= m_vwapSD2Minus)
        {
            return 2; // ±2 sigma
        }
        else if(currentPrice >= m_vwapSD1Plus || currentPrice <= m_vwapSD1Minus)
        {
            return 1; // ±1 sigma
        }
        
        return 0; // Dentro de ±1 sigma
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está em extremo (±2 sigma)                  |
    //+------------------------------------------------------------------+
    bool IsPriceAtExtreme(double currentPrice)
    {
        return (GetPriceDeviationLevel(currentPrice) >= 2);
    }
    
    //+------------------------------------------------------------------+
    //| Obter valor atual do VWAP                                      |
    //+------------------------------------------------------------------+
    double GetVWAP() const { return m_vwapValue; }
    
    //+------------------------------------------------------------------+
    //| Obter banda superior (+1 sigma)                                |
    //+------------------------------------------------------------------+
    double GetUpperBand1() const { return m_vwapSD1Plus; }
    
    //+------------------------------------------------------------------+
    //| Obter banda inferior (-1 sigma)                                |
    //+------------------------------------------------------------------+
    double GetLowerBand1() const { return m_vwapSD1Minus; }
    
    //+------------------------------------------------------------------+
    //| Obter banda superior (+2 sigma)                                |
    //+------------------------------------------------------------------+
    double GetUpperBand2() const { return m_vwapSD2Plus; }
    
    //+------------------------------------------------------------------+
    //| Obter banda inferior (-2 sigma)                                |
    //+------------------------------------------------------------------+
    double GetLowerBand2() const { return m_vwapSD2Minus; }
    
    //+------------------------------------------------------------------+
    //| Obter banda superior (+3 sigma)                                |
    //+------------------------------------------------------------------+
    double GetUpperBand3() const { return m_vwapSD3Plus; }
    
    //+------------------------------------------------------------------+
    //| Obter banda inferior (-3 sigma)                                |
    //+------------------------------------------------------------------+
    double GetLowerBand3() const { return m_vwapSD3Minus; }
    
    //+------------------------------------------------------------------+
    //| Verificar se está inicializado                                 |
    //+------------------------------------------------------------------+
    bool IsInitialized() const { return m_initialized; }
    
    //+------------------------------------------------------------------+
    //| Obter viés intradiário baseado no VWAP                         |
    //+------------------------------------------------------------------+
    ENUM_TREND_DIRECTION GetIntradayBias(double currentPrice)
    {
        if(!m_initialized || m_vwapValue == 0)
        {
            return TREND_NEUTRAL;
        }
        
        // Viés baseado na posição em relação ao VWAP
        if(currentPrice > m_vwapValue)
        {
            return TREND_UP;
        }
        else if(currentPrice < m_vwapValue)
        {
            return TREND_DOWN;
        }
        
        return TREND_NEUTRAL;
    }

private:
    //+------------------------------------------------------------------+
    //| Obter início do dia                                            |
    //+------------------------------------------------------------------+
    datetime GetDayStart(datetime time)
    {
        MqlDateTime dt;
        TimeToStruct(time, dt);
        
        dt.hour = MARKET_OPEN_HOUR;  // 9h conforme configuração
        dt.min = 0;
        dt.sec = 0;
        
        return StructToTime(dt);
    }
    
    //+------------------------------------------------------------------+
    //| Resetar VWAP para novo dia                                     |
    //+------------------------------------------------------------------+
    void ResetVWAP(datetime newResetTime)
    {
        m_sumPriceVolume = 0;
        m_sumVolume = 0;
        m_sumPriceVolumeSquared = 0;
        
        m_vwapValue = 0;
        m_vwapSD1Plus = 0;
        m_vwapSD1Minus = 0;
        m_vwapSD2Plus = 0;
        m_vwapSD2Minus = 0;
        m_vwapSD3Plus = 0;
        m_vwapSD3Minus = 0;
        
        m_lastReset = newResetTime;
        
        CCoreUtils::LogInfo("VWAP resetado para novo dia: " + TimeToString(newResetTime, TIME_DATE));
    }
    
    //+------------------------------------------------------------------+
    //| Obter dados históricos desde o reset                           |
    //+------------------------------------------------------------------+
    bool GetHistoricalDataSinceReset(ENUM_TIMEFRAMES tf)
    {
        // Calcular número de barras desde o reset
        datetime currentTime = TimeCurrent();
        int periodMinutes = 0;
        
        switch(tf)
        {
            case PERIOD_M1:  periodMinutes = 1; break;
            case PERIOD_M3:  periodMinutes = 3; break;
            case PERIOD_M5:  periodMinutes = 5; break;
            case PERIOD_M15: periodMinutes = 15; break;
            case PERIOD_M30: periodMinutes = 30; break;
            case PERIOD_H1:  periodMinutes = 60; break;
            default: periodMinutes = 15; break;
        }
        
        int minutesSinceReset = (int)((currentTime - m_lastReset) / 60);
        int barsNeeded = (minutesSinceReset / periodMinutes) + 10; // +10 para margem
        barsNeeded = MathMin(barsNeeded, 500); // Máximo 500 barras
        
        if(barsNeeded < 1) barsNeeded = 1;
        
        // Redimensionar arrays
        if(ArrayResize(m_high, barsNeeded) < 0 || 
           ArrayResize(m_low, barsNeeded) < 0 ||
           ArrayResize(m_close, barsNeeded) < 0 ||
           ArrayResize(m_time, barsNeeded) < 0 ||
           ArrayResize(m_volume, barsNeeded) < 0)
        {
            return false;
        }
        
        // Copiar dados
        if(CopyHigh(m_symbol, tf, 0, barsNeeded, m_high) < 0 ||
           CopyLow(m_symbol, tf, 0, barsNeeded, m_low) < 0 ||
           CopyClose(m_symbol, tf, 0, barsNeeded, m_close) < 0 ||
           CopyTime(m_symbol, tf, 0, barsNeeded, m_time) < 0 ||
           CopyTickVolume(m_symbol, tf, 0, barsNeeded, m_volume) < 0)
        {
            return false;
        }
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular VWAP a partir dos dados                               |
    //+------------------------------------------------------------------+
    void CalculateVWAPFromData()
    {
        m_sumPriceVolume = 0;
        m_sumVolume = 0;
        m_sumPriceVolumeSquared = 0;
        
        int dataSize = ArraySize(m_time);
        
        // Processar barras desde o reset até agora
        for(int i = dataSize - 1; i >= 0; i--)
        {
            // Verificar se a barra é posterior ao reset
            if(m_time[i] < m_lastReset) continue;
            
            // Calcular preço típico
            double typicalPrice = (m_high[i] + m_low[i] + m_close[i]) / 3.0;
            double volume = (double)m_volume[i];
            
            if(volume <= 0) volume = 1; // Evitar divisão por zero
            
            // Acumular valores
            m_sumPriceVolume += typicalPrice * volume;
            m_sumVolume += volume;
            m_sumPriceVolumeSquared += (typicalPrice * typicalPrice) * volume;
        }
        
        // Calcular VWAP
        if(m_sumVolume > 0)
        {
            m_vwapValue = m_sumPriceVolume / m_sumVolume;
            
            // Calcular desvio padrão
            double variance = (m_sumPriceVolumeSquared / m_sumVolume) - (m_vwapValue * m_vwapValue);
            double stdDev = (variance > 0) ? MathSqrt(variance) : 0;
            
            // Calcular bandas
            m_vwapSD1Plus = m_vwapValue + stdDev;
            m_vwapSD1Minus = m_vwapValue - stdDev;
            m_vwapSD2Plus = m_vwapValue + (2 * stdDev);
            m_vwapSD2Minus = m_vwapValue - (2 * stdDev);
            m_vwapSD3Plus = m_vwapValue + (3 * stdDev);
            m_vwapSD3Minus = m_vwapValue - (3 * stdDev);
        }
        else
        {
            // Sem dados suficientes
            m_vwapValue = 0;
            m_vwapSD1Plus = 0;
            m_vwapSD1Minus = 0;
            m_vwapSD2Plus = 0;
            m_vwapSD2Minus = 0;
            m_vwapSD3Plus = 0;
            m_vwapSD3Minus = 0;
        }
    }
    
public:
    //+------------------------------------------------------------------+
    //| Obter informações de debug                                     |
    //+------------------------------------------------------------------+
    string GetDebugInfo()
    {
        if(!m_initialized)
        {
            return "VWAP não inicializado";
        }
        
        string info = "=== VWAP ===\n";
        info += "VWAP: " + DoubleToString(m_vwapValue, 2) + "\n";
        info += "+1σ: " + DoubleToString(m_vwapSD1Plus, 2) + "\n";
        info += "-1σ: " + DoubleToString(m_vwapSD1Minus, 2) + "\n";
        info += "+2σ: " + DoubleToString(m_vwapSD2Plus, 2) + "\n";
        info += "-2σ: " + DoubleToString(m_vwapSD2Minus, 2) + "\n";
        info += "+3σ: " + DoubleToString(m_vwapSD3Plus, 2) + "\n";
        info += "-3σ: " + DoubleToString(m_vwapSD3Minus, 2) + "\n";
        info += "Volume acumulado: " + DoubleToString(m_sumVolume, 0) + "\n";
        info += "Último reset: " + TimeToString(m_lastReset, TIME_DATE|TIME_SECONDS) + "\n";
        info += "Última atualização: " + TimeToString(m_lastUpdate, TIME_DATE|TIME_SECONDS);
        
        return info;
    }
};

#endif // VWAP_H

