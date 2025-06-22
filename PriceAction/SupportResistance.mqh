//+------------------------------------------------------------------+
//| SupportResistance.mqh - Identificação de Suporte e Resistência  |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef SUPPORT_RESISTANCE_H
#define SUPPORT_RESISTANCE_H
#property strict

#include <Object.mqh>
#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "../Core/CoreUtils.mqh"
#include "../Visualization/IValidationVisualizer.mqh"

//+------------------------------------------------------------------+
//| Classe de Suporte e Resistência                                 |
//+------------------------------------------------------------------+
class CSupportResistance : public CObject
{
private:
    SR_Level             m_levels[];         // Níveis identificados
    string               m_symbol;           // Símbolo
    IValidationVisualizer* m_visualizer;    // Visualizador opcional
    
    // Arrays para análise
    double               m_high[];           // Máximas
    double               m_low[];            // Mínimas
    double               m_close[];          // Fechamentos
    datetime             m_time[];           // Tempos
    long                 m_volume[];         // Volume
    
public:
    //+------------------------------------------------------------------+
    //| Construtor                                                       |
    //+------------------------------------------------------------------+
    CSupportResistance()
    {
        m_symbol = "";
        m_visualizer = NULL;
        
        ArraySetAsSeries(m_high, true);
        ArraySetAsSeries(m_low, true);
        ArraySetAsSeries(m_close, true);
        ArraySetAsSeries(m_time, true);
        ArraySetAsSeries(m_volume, true);
    }
    
    //+------------------------------------------------------------------+
    //| Destrutor                                                        |
    //+------------------------------------------------------------------+
    ~CSupportResistance()
    {
        ArrayResize(m_levels, 0);
        ArrayFree(m_high);
        ArrayFree(m_low);
        ArrayFree(m_close);
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
            CCoreUtils::LogError("Símbolo inválido para SupportResistance");
            return false;
        }
        
        m_symbol = symbol;
        CCoreUtils::LogInfo("SupportResistance inicializado para " + symbol);
        return true;
    }

    void SetVisualizer(IValidationVisualizer* visualizer)
    {
        m_visualizer = visualizer;
    }
    
    //+------------------------------------------------------------------+
    //| Identificar níveis de suporte e resistência                    |
    //+------------------------------------------------------------------+
    void IdentifyLevels(string symbol, ENUM_TIMEFRAMES tf)
    {
        if(symbol != "") m_symbol = symbol;
        
        // Limpar níveis anteriores
        ArrayResize(m_levels, 0);
        
        // Obter dados históricos
        if(!GetHistoricalData(tf, HISTORY_BARS_SR))
        {
            CCoreUtils::LogError("Falha ao obter dados para S/R");
            return;
        }
        
        // Identificar máximas e mínimas locais
        IdentifyLocalExtremes();
        
        // Agrupar níveis próximos
        GroupNearbyLevels();
        
        // Validar níveis com múltiplos toques
        ValidateLevels();
        
        // Ordenar por relevância
        SortLevelsByRelevance();

        CCoreUtils::LogInfo("Identificados " + IntegerToString(ArraySize(m_levels)) + " níveis S/R");
        if(m_visualizer != NULL)
            m_visualizer.UpdateSupportResistance(this);
    }
    
    //+------------------------------------------------------------------+
    //| Obter suporte mais próximo abaixo do preço                     |
    //+------------------------------------------------------------------+
    double GetNearestSupport(double currentPrice)
    {
        double nearestSupport = 0;
        double minDistance = DBL_MAX;
        
        for(int i = 0; i < ArraySize(m_levels); i++)
        {
            if(m_levels[i].isSupport && m_levels[i].price < currentPrice)
            {
                double distance = currentPrice - m_levels[i].price;
                if(distance < minDistance)
                {
                    minDistance = distance;
                    nearestSupport = m_levels[i].price;
                }
            }
        }
        
        return nearestSupport;
    }
    
    //+------------------------------------------------------------------+
    //| Obter resistência mais próxima acima do preço                  |
    //+------------------------------------------------------------------+
    double GetNearestResistance(double currentPrice)
    {
        double nearestResistance = 0;
        double minDistance = DBL_MAX;
        
        for(int i = 0; i < ArraySize(m_levels); i++)
        {
            if(!m_levels[i].isSupport && m_levels[i].price > currentPrice)
            {
                double distance = m_levels[i].price - currentPrice;
                if(distance < minDistance)
                {
                    minDistance = distance;
                    nearestResistance = m_levels[i].price;
                }
            }
        }
        
        return nearestResistance;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está próximo de suporte                     |
    //+------------------------------------------------------------------+
    bool IsPriceNearSupport(double currentPrice, double tolerance)
    {
        for(int i = 0; i < ArraySize(m_levels); i++)
        {
            if(m_levels[i].isSupport)
            {
                if(CCoreUtils::IsPriceWithinTolerance(currentPrice, m_levels[i].price, tolerance, m_symbol))
                {
                    return true;
                }
            }
        }
        
        return false;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está próximo de resistência                 |
    //+------------------------------------------------------------------+
    bool IsPriceNearResistance(double currentPrice, double tolerance)
    {
        for(int i = 0; i < ArraySize(m_levels); i++)
        {
            if(!m_levels[i].isSupport)
            {
                if(CCoreUtils::IsPriceWithinTolerance(currentPrice, m_levels[i].price, tolerance, m_symbol))
                {
                    return true;
                }
            }
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| Obter suportes próximos                                         |
    //+------------------------------------------------------------------+
    int GetNearbySupports(double currentPrice, double tolerance, double &levels[])
    {
        ArrayFree(levels);
        int count = 0;

        for(int i = 0; i < ArraySize(m_levels); i++)
        {
            if(m_levels[i].isSupport &&
               CCoreUtils::IsPriceWithinTolerance(currentPrice, m_levels[i].price, tolerance, m_symbol))
            {
                ArrayResize(levels, count + 1);
                levels[count] = m_levels[i].price;
                count++;
            }
        }

        return count;
    }

    //+------------------------------------------------------------------+
    //| Obter resistências próximas                                    |
    //+------------------------------------------------------------------+
    int GetNearbyResistances(double currentPrice, double tolerance, double &levels[])
    {
        ArrayFree(levels);
        int count = 0;

        for(int i = 0; i < ArraySize(m_levels); i++)
        {
            if(!m_levels[i].isSupport &&
               CCoreUtils::IsPriceWithinTolerance(currentPrice, m_levels[i].price, tolerance, m_symbol))
            {
                ArrayResize(levels, count + 1);
                levels[count] = m_levels[i].price;
                count++;
            }
        }

        return count;
    }
    
    //+------------------------------------------------------------------+
    //| Obter força do nível (baseado no número de toques)             |
    //+------------------------------------------------------------------+
    int GetLevelStrength(double price, bool isSupport)
    {
        for(int i = 0; i < ArraySize(m_levels); i++)
        {
            if(m_levels[i].isSupport == isSupport)
            {
                if(CCoreUtils::IsPriceWithinTolerance(price, m_levels[i].price, TOLERANCE_SR_LEVEL, m_symbol))
                {
                    return m_levels[i].touches;
                }
            }
        }
        
        return 0;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se nível foi quebrado recentemente                   |
    //+------------------------------------------------------------------+
    bool IsLevelBroken(double price, bool isSupport, int barsToCheck = 5)
    {
        double tolerance = CCoreUtils::PointsToPrice(TOLERANCE_SR_LEVEL, m_symbol);
        int barsCheck = MathMin(barsToCheck, ArraySize(m_close));
        
        for(int i = 0; i < barsCheck; i++)
        {
            if(isSupport)
            {
                // Suporte quebrado se preço fechou significativamente abaixo
                if(m_close[i] < price - tolerance)
                {
                    return true;
                }
            }
            else
            {
                // Resistência quebrada se preço fechou significativamente acima
                if(m_close[i] > price + tolerance)
                {
                    return true;
                }
            }
        }
        
        return false;
    }
    
    //+------------------------------------------------------------------+
    //| Obter todos os níveis                                          |
    //+------------------------------------------------------------------+
    void GetAllLevels(SR_Level &levels[])
    {
        ArrayResize(levels, ArraySize(m_levels));
        for(int i = 0; i < ArraySize(m_levels); i++)
        {
            levels[i] = m_levels[i];
        }
    }
    
    //+------------------------------------------------------------------+
    //| Obter número de níveis identificados                           |
    //+------------------------------------------------------------------+
    int GetLevelsCount() const
    {
        return ArraySize(m_levels);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se há confluência de níveis                          |
    //+------------------------------------------------------------------+
    bool HasConfluence(double price, double tolerance)
    {
        int nearbyLevels = 0;
        
        for(int i = 0; i < ArraySize(m_levels); i++)
        {
            if(CCoreUtils::IsPriceWithinTolerance(price, m_levels[i].price, tolerance, m_symbol))
            {
                nearbyLevels++;
            }
        }
        
        return nearbyLevels >= 2; // Confluência se 2+ níveis próximos
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
           ArrayResize(m_time, bars) < 0 ||
           ArrayResize(m_volume, bars) < 0)
        {
            return false;
        }
        
        if(CopyHigh(m_symbol, tf, 0, bars, m_high) < 0 ||
           CopyLow(m_symbol, tf, 0, bars, m_low) < 0 ||
           CopyClose(m_symbol, tf, 0, bars, m_close) < 0 ||
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
    //| Identificar extremos locais                                    |
    //+------------------------------------------------------------------+
    void IdentifyLocalExtremes()
    {
        int arraySize = ArraySize(m_high);
        if(arraySize < 10) return;
        
        // Identificar máximas locais (resistências potenciais)
        for(int i = 5; i < arraySize - 5; i++)
        {
            bool isLocalHigh = true;
            
            // Verificar se é máxima local
            for(int j = i - 5; j <= i + 5; j++)
            {
                if(j != i && m_high[j] >= m_high[i])
                {
                    isLocalHigh = false;
                    break;
                }
            }
            
            if(isLocalHigh)
            {
                AddLevel(m_high[i], false, m_time[i], TIMEFRAME_TREND); // false = resistência
            }
        }
        
        // Identificar mínimas locais (suportes potenciais)
        for(int i = 5; i < arraySize - 5; i++)
        {
            bool isLocalLow = true;
            
            // Verificar se é mínima local
            for(int j = i - 5; j <= i + 5; j++)
            {
                if(j != i && m_low[j] <= m_low[i])
                {
                    isLocalLow = false;
                    break;
                }
            }
            
            if(isLocalLow)
            {
                AddLevel(m_low[i], true, m_time[i], TIMEFRAME_TREND); // true = suporte
            }
        }
        
        // Adicionar níveis psicológicos (números redondos)
        AddPsychologicalLevels();
    }
    
    //+------------------------------------------------------------------+
    //| Adicionar nível                                                |
    //+------------------------------------------------------------------+
    void AddLevel(double price, bool isSupport, datetime time, ENUM_TIMEFRAMES tf)
    {
        int newSize = ArraySize(m_levels) + 1;
        ArrayResize(m_levels, newSize);
        
        m_levels[newSize-1].price = CCoreUtils::NormalizePrice(price, m_symbol);
        m_levels[newSize-1].touches = 1;
        m_levels[newSize-1].firstTouch = time;
        m_levels[newSize-1].lastTouch = time;
        m_levels[newSize-1].isSupport = isSupport;
        m_levels[newSize-1].timeframe = tf;
    }
    
    //+------------------------------------------------------------------+
    //| Adicionar níveis psicológicos                                  |
    //+------------------------------------------------------------------+
    void AddPsychologicalLevels()
    {
        if(ArraySize(m_high) == 0) return;
        
        double currentPrice = m_close[0];
        double range = m_high[ArrayMaximum(m_high)] - m_low[ArrayMinimum(m_low)];
        
        // Calcular níveis redondos próximos
        int roundLevel = 1000; // Para WINM25, usar níveis de 1000 pontos
        
        double baseLevel = MathFloor(currentPrice / roundLevel) * roundLevel;
        
        // Adicionar níveis acima e abaixo
        for(int i = -3; i <= 3; i++)
        {
            double level = baseLevel + (i * roundLevel);
            if(level > 0)
            {
                bool isSupport = (level < currentPrice);
                AddLevel(level, isSupport, TimeCurrent(), TIMEFRAME_TREND);
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Agrupar níveis próximos                                        |
    //+------------------------------------------------------------------+
    void GroupNearbyLevels()
    {
        double tolerance = CCoreUtils::PointsToPrice(TOLERANCE_SR_LEVEL, m_symbol);
        
        for(int i = 0; i < ArraySize(m_levels) - 1; i++)
        {
            for(int j = i + 1; j < ArraySize(m_levels); j++)
            {
                if(MathAbs(m_levels[i].price - m_levels[j].price) <= tolerance &&
                   m_levels[i].isSupport == m_levels[j].isSupport)
                {
                    // Mesclar níveis
                    m_levels[i].touches += m_levels[j].touches;
                    m_levels[i].price = (m_levels[i].price + m_levels[j].price) / 2.0;
                    m_levels[i].firstTouch = MathMin(m_levels[i].firstTouch, m_levels[j].firstTouch);
                    m_levels[i].lastTouch = MathMax(m_levels[i].lastTouch, m_levels[j].lastTouch);
                    
                    // Remover nível duplicado
                    for(int k = j; k < ArraySize(m_levels) - 1; k++)
                    {
                        m_levels[k] = m_levels[k + 1];
                    }
                    ArrayResize(m_levels, ArraySize(m_levels) - 1);
                    j--; // Ajustar índice
                }
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Validar níveis com múltiplos toques                            |
    //+------------------------------------------------------------------+
    void ValidateLevels()
    {
        double tolerance = CCoreUtils::PointsToPrice(TOLERANCE_SR_LEVEL, m_symbol);
        
        // Contar toques reais para cada nível
        for(int i = 0; i < ArraySize(m_levels); i++)
        {
            int touches = CountTouches(m_levels[i].price, m_levels[i].isSupport, tolerance);
            m_levels[i].touches = touches;
        }
        
        // Remover níveis com poucos toques
        for(int i = ArraySize(m_levels) - 1; i >= 0; i--)
        {
            if(m_levels[i].touches < MIN_SR_TOUCHES)
            {
                // Remover nível
                for(int j = i; j < ArraySize(m_levels) - 1; j++)
                {
                    m_levels[j] = m_levels[j + 1];
                }
                ArrayResize(m_levels, ArraySize(m_levels) - 1);
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Contar toques em um nível                                      |
    //+------------------------------------------------------------------+
    int CountTouches(double price, bool isSupport, double tolerance)
    {
        int touches = 0;
        
        for(int i = 0; i < ArraySize(m_high); i++)
        {
            double testPrice = isSupport ? m_low[i] : m_high[i];
            
            if(MathAbs(testPrice - price) <= tolerance)
            {
                touches++;
            }
        }
        
        return touches;
    }
    
    //+------------------------------------------------------------------+
    //| Ordenar níveis por relevância                                  |
    //+------------------------------------------------------------------+
    void SortLevelsByRelevance()
    {
        // Ordenação simples por número de toques (bubble sort)
        for(int i = 0; i < ArraySize(m_levels) - 1; i++)
        {
            for(int j = 0; j < ArraySize(m_levels) - 1 - i; j++)
            {
                if(m_levels[j].touches < m_levels[j + 1].touches)
                {
                    // Trocar posições
                    SR_Level temp = m_levels[j];
                    m_levels[j] = m_levels[j + 1];
                    m_levels[j + 1] = temp;
                }
            }
        }
    }
};

#endif // SUPPORT_RESISTANCE_H

