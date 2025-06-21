//+------------------------------------------------------------------+
//| Fibonacci.mqh - Análise de Fibonacci                            |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef FIBONACCI_H
#define FIBONACCI_H

#include <Object.mqh>
#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "../Core/CoreUtils.mqh"

//+------------------------------------------------------------------+
//| Classe de Análise de Fibonacci                                  |
//+------------------------------------------------------------------+
class CFibonacci : public CObject
{
private:
    string               m_symbol;           // Símbolo
    
    // Níveis de Fibonacci
    FibonacciLevels      m_currentLevels;    // Níveis atuais
    
    // Dados para análise
    double               m_high[];           // Máximas
    double               m_low[];            // Mínimas
    double               m_close[];          // Fechamentos
    datetime             m_time[];           // Tempos
    
    datetime             m_lastUpdate;       // Última atualização
    bool                 m_initialized;      // Status de inicialização
    
public:
    //+------------------------------------------------------------------+
    //| Construtor                                                       |
    //+------------------------------------------------------------------+
    CFibonacci()
    {
        m_symbol = "";
        InitializeFibLevels(m_currentLevels);
        m_lastUpdate = 0;
        m_initialized = false;
        
        ArraySetAsSeries(m_high, true);
        ArraySetAsSeries(m_low, true);
        ArraySetAsSeries(m_close, true);
        ArraySetAsSeries(m_time, true);
    }
    
    //+------------------------------------------------------------------+
    //| Destrutor                                                        |
    //+------------------------------------------------------------------+
    ~CFibonacci()
    {
        ArrayFree(m_high);
        ArrayFree(m_low);
        ArrayFree(m_close);
        ArrayFree(m_time);
    }
    
    //+------------------------------------------------------------------+
    //| Inicializar Fibonacci                                          |
    //+------------------------------------------------------------------+
    bool Initialize(string symbol)
    {
        if(symbol == "" || symbol == NULL)
        {
            CCoreUtils::LogError("Símbolo inválido para Fibonacci");
            return false;
        }
        
        m_symbol = symbol;
        m_initialized = true;
        
        CCoreUtils::LogInfo("Fibonacci inicializado com sucesso para " + symbol);
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular níveis de Fibonacci                                   |
    //+------------------------------------------------------------------+
    bool CalculateLevels(string symbol, ENUM_TIMEFRAMES tf, bool isRetracement = true)
    {
        if(symbol != "") m_symbol = symbol;
        
        if(!m_initialized)
        {
            CCoreUtils::LogError("Fibonacci não inicializado");
            return false;
        }
        
        // Obter dados históricos
        if(!GetHistoricalData(tf, HISTORY_BARS_FIBONACCI))
        {
            CCoreUtils::LogError("Falha ao obter dados para Fibonacci");
            return false;
        }
        
        // Encontrar swing high e swing low
        int swingHighIndex = -1, swingLowIndex = -1;
        double swingHigh = 0, swingLow = 0;
        
        if(!FindSwingPoints(swingHighIndex, swingLowIndex, swingHigh, swingLow))
        {
            CCoreUtils::LogWarning("Não foi possível encontrar swing points válidos");
            return false;
        }
        
        // Calcular níveis baseado no tipo
        if(isRetracement)
        {
            CalculateRetracementLevels(swingHigh, swingLow);
        }
        else
        {
            CalculateExtensionLevels(swingHigh, swingLow);
        }
        
        m_currentLevels.isValid = true;
        m_currentLevels.swingHigh = swingHigh;
        m_currentLevels.swingLow = swingLow;
        m_currentLevels.swingHighTime = m_time[swingHighIndex];
        m_currentLevels.swingLowTime = m_time[swingLowIndex];
        m_currentLevels.isRetracement = isRetracement;
        
        m_lastUpdate = TimeCurrent();
        
        CCoreUtils::LogInfo("Níveis de Fibonacci calculados. Swing High: " + 
                          DoubleToString(swingHigh, 2) + ", Swing Low: " + 
                          DoubleToString(swingLow, 2));
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está próximo de nível de Fibonacci          |
    //+------------------------------------------------------------------+
    bool IsPriceNearFibLevel(double price, double tolerance, double &nearestLevel)
    {
        if(!m_currentLevels.isValid)
        {
            return false;
        }
        
        // Verificar proximidade a cada nível
        double levels[] = {
            m_currentLevels.level0,
            m_currentLevels.level236,
            m_currentLevels.level382,
            m_currentLevels.level500,
            m_currentLevels.level618,
            m_currentLevels.level786,
            m_currentLevels.level1000
        };
        
        double minDistance = DBL_MAX;
        nearestLevel = 0;
        
        for(int i = 0; i < ArraySize(levels); i++)
        {
            if(levels[i] == 0) continue;
            
            double distance = MathAbs(price - levels[i]);
            
            if(distance < minDistance)
            {
                minDistance = distance;
                nearestLevel = levels[i];
            }
        }
        
        // Verificar se está dentro da tolerância
        return CCoreUtils::IsPriceWithinTolerance(price, nearestLevel, tolerance, m_symbol);
    }
    
    //+------------------------------------------------------------------+
    //| Obter nível de Fibonacci específico                            |
    //+------------------------------------------------------------------+
    double GetFibLevel(double percentage)
    {
        if(!m_currentLevels.isValid)
        {
            return 0;
        }
        
        // Retornar nível baseado na porcentagem
        if(MathAbs(percentage - 0.0) < 0.001) return m_currentLevels.level0;
        if(MathAbs(percentage - 23.6) < 0.001) return m_currentLevels.level236;
        if(MathAbs(percentage - 38.2) < 0.001) return m_currentLevels.level382;
        if(MathAbs(percentage - 50.0) < 0.001) return m_currentLevels.level500;
        if(MathAbs(percentage - 61.8) < 0.001) return m_currentLevels.level618;
        if(MathAbs(percentage - 78.6) < 0.001) return m_currentLevels.level786;
        if(MathAbs(percentage - 100.0) < 0.001) return m_currentLevels.level1000;
        
        return 0;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está em zona de confluência                 |
    //+------------------------------------------------------------------+
    bool IsInConfluenceZone(double price, double tolerance)
    {
        if(!m_currentLevels.isValid)
        {
            return false;
        }
        
        // Verificar confluência entre níveis importantes (38.2%, 50%, 61.8%)
        double importantLevels[] = {
            m_currentLevels.level382,
            m_currentLevels.level500,
            m_currentLevels.level618
        };
        
        int nearLevels = 0;
        
        for(int i = 0; i < ArraySize(importantLevels); i++)
        {
            if(importantLevels[i] == 0) continue;
            
            if(CCoreUtils::IsPriceWithinTolerance(price, importantLevels[i], tolerance, m_symbol))
            {
                nearLevels++;
            }
        }
        
        // Confluência se próximo de 2+ níveis importantes
        return (nearLevels >= 2);
    }
    
    //+------------------------------------------------------------------+
    //| Obter força do nível de Fibonacci                              |
    //+------------------------------------------------------------------+
    double GetLevelStrength(double fibLevel)
    {
        if(!m_currentLevels.isValid || fibLevel == 0)
        {
            return 0;
        }
        
        // Força baseada na importância histórica dos níveis
        if(MathAbs(fibLevel - m_currentLevels.level618) < 0.001) return 100; // 61.8% - mais forte
        if(MathAbs(fibLevel - m_currentLevels.level382) < 0.001) return 90;  // 38.2%
        if(MathAbs(fibLevel - m_currentLevels.level500) < 0.001) return 85;  // 50%
        if(MathAbs(fibLevel - m_currentLevels.level786) < 0.001) return 75;  // 78.6%
        if(MathAbs(fibLevel - m_currentLevels.level236) < 0.001) return 60;  // 23.6%
        if(MathAbs(fibLevel - m_currentLevels.level0) < 0.001) return 50;    // 0%
        if(MathAbs(fibLevel - m_currentLevels.level1000) < 0.001) return 50; // 100%
        
        return 0;
    }
    
    //+------------------------------------------------------------------+
    //| Obter níveis atuais                                            |
    //+------------------------------------------------------------------+
    FibonacciLevels GetCurrentLevels() const { return m_currentLevels; }
    
    //+------------------------------------------------------------------+
    //| Verificar se níveis são válidos                                |
    //+------------------------------------------------------------------+
    bool IsValid() const { return m_currentLevels.isValid; }
    
    //+------------------------------------------------------------------+
    //| Verificar se está inicializado                                 |
    //+------------------------------------------------------------------+
    bool IsInitialized() const { return m_initialized; }

private:
    //+------------------------------------------------------------------+
    //| Inicializar estrutura de níveis                                |
    //+------------------------------------------------------------------+
    void InitializeFibLevels(FibonacciLevels &levels)
    {
        levels.level0 = 0;
        levels.level236 = 0;
        levels.level382 = 0;
        levels.level500 = 0;
        levels.level618 = 0;
        levels.level786 = 0;
        levels.level1000 = 0;
        levels.swingHigh = 0;
        levels.swingLow = 0;
        levels.swingHighTime = 0;
        levels.swingLowTime = 0;
        levels.isValid = false;
        levels.isRetracement = true;
    }
    
    //+------------------------------------------------------------------+
    //| Obter dados históricos                                          |
    //+------------------------------------------------------------------+
    bool GetHistoricalData(ENUM_TIMEFRAMES tf, int bars)
    {
        if(ArrayResize(m_high, bars) < 0 || 
           ArrayResize(m_low, bars) < 0 ||
           ArrayResize(m_close, bars) < 0 ||
           ArrayResize(m_time, bars) < 0)
        {
            return false;
        }
        
        if(CopyHigh(m_symbol, tf, 0, bars, m_high) < 0 ||
           CopyLow(m_symbol, tf, 0, bars, m_low) < 0 ||
           CopyClose(m_symbol, tf, 0, bars, m_close) < 0 ||
           CopyTime(m_symbol, tf, 0, bars, m_time) < 0)
        {
            return false;
        }
        
        return CCoreUtils::ValidateArrayData(m_high, bars) &&
               CCoreUtils::ValidateArrayData(m_low, bars) &&
               CCoreUtils::ValidateArrayData(m_close, bars);
    }
    
    //+------------------------------------------------------------------+
    //| Encontrar swing points                                         |
    //+------------------------------------------------------------------+
    bool FindSwingPoints(int &highIndex, int &lowIndex, double &swingHigh, double &swingLow)
    {
        int dataSize = ArraySize(m_high);
        if(dataSize < 20) return false;
        
        // Procurar swing high e swing low nas últimas 50 barras
        int searchBars = MathMin(50, dataSize - 10);
        
        // Encontrar máxima e mínima mais significativas
        highIndex = ArrayMaximum(m_high, 10, searchBars);
        lowIndex = ArrayMinimum(m_low, 10, searchBars);
        
        if(highIndex == -1 || lowIndex == -1)
        {
            return false;
        }
        
        swingHigh = m_high[highIndex];
        swingLow = m_low[lowIndex];
        
        // Validar se os pontos são significativos
        double range = swingHigh - swingLow;
        double atr = CCoreUtils::CalculateATR(m_high, m_low, m_close, 20, 20);
        
        // Range deve ser pelo menos 1.5x ATR
        if(range < atr * 1.5)
        {
            return false;
        }
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular níveis de retração                                    |
    //+------------------------------------------------------------------+
    void CalculateRetracementLevels(double high, double low)
    {
        double range = high - low;
        
        // Calcular níveis de retração (do high para o low)
        m_currentLevels.level0 = high;                          // 0% (swing high)
        m_currentLevels.level236 = high - (range * 0.236);      // 23.6%
        m_currentLevels.level382 = high - (range * 0.382);      // 38.2%
        m_currentLevels.level500 = high - (range * 0.500);      // 50%
        m_currentLevels.level618 = high - (range * 0.618);      // 61.8%
        m_currentLevels.level786 = high - (range * 0.786);      // 78.6%
        m_currentLevels.level1000 = low;                        // 100% (swing low)
    }
    
    //+------------------------------------------------------------------+
    //| Calcular níveis de extensão                                    |
    //+------------------------------------------------------------------+
    void CalculateExtensionLevels(double high, double low)
    {
        double range = high - low;
        
        // Calcular níveis de extensão (além do movimento original)
        m_currentLevels.level0 = low;                           // 0% (swing low)
        m_currentLevels.level236 = high + (range * 0.236);      // 123.6%
        m_currentLevels.level382 = high + (range * 0.382);      // 138.2%
        m_currentLevels.level500 = high + (range * 0.500);      // 150%
        m_currentLevels.level618 = high + (range * 0.618);      // 161.8%
        m_currentLevels.level786 = high + (range * 0.786);      // 178.6%
        m_currentLevels.level1000 = high + range;               // 200%
    }
    
public:
    //+------------------------------------------------------------------+
    //| Obter informações de debug                                     |
    //+------------------------------------------------------------------+
    string GetDebugInfo()
    {
        if(!m_initialized)
        {
            return "Fibonacci não inicializado";
        }
        
        if(!m_currentLevels.isValid)
        {
            return "Níveis de Fibonacci não calculados";
        }
        
        string info = "=== FIBONACCI ===\n";
        string typeStr = m_currentLevels.isRetracement ? "RETRAÇÃO" : "EXTENSÃO";
        info += "Tipo: " + typeStr + "\n";
        info += "Swing High: " + DoubleToString(m_currentLevels.swingHigh, 2) + 
                " (" + TimeToString(m_currentLevels.swingHighTime, TIME_DATE|TIME_MINUTES) + ")\n";
        info += "Swing Low: " + DoubleToString(m_currentLevels.swingLow, 2) + 
                " (" + TimeToString(m_currentLevels.swingLowTime, TIME_DATE|TIME_MINUTES) + ")\n";
        info += "0%: " + DoubleToString(m_currentLevels.level0, 2) + "\n";
        info += "23.6%: " + DoubleToString(m_currentLevels.level236, 2) + "\n";
        info += "38.2%: " + DoubleToString(m_currentLevels.level382, 2) + "\n";
        info += "50%: " + DoubleToString(m_currentLevels.level500, 2) + "\n";
        info += "61.8%: " + DoubleToString(m_currentLevels.level618, 2) + "\n";
        info += "78.6%: " + DoubleToString(m_currentLevels.level786, 2) + "\n";
        info += "100%: " + DoubleToString(m_currentLevels.level1000, 2) + "\n";
        info += "Última atualização: " + TimeToString(m_lastUpdate, TIME_DATE|TIME_SECONDS);
        
        return info;
    }
};

#endif // FIBONACCI_H

