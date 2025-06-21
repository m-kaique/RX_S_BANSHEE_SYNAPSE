//+------------------------------------------------------------------+
//| TrendLines.mqh - Implementação de Linhas de Tendência           |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef TREND_LINES_H
#define TREND_LINES_H

#include <Object.mqh>
#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "../Core/CoreUtils.mqh"

//+------------------------------------------------------------------+
//| Classe de Linhas de Tendência                                   |
//+------------------------------------------------------------------+
class CTrendLines : public CObject
{
private:
    TrendLine            m_lta;              // Linha de Tendência de Alta
    TrendLine            m_ltb;              // Linha de Tendência de Baixa
    string               m_symbol;           // Símbolo
    
    // Arrays para análise
    double               m_high[];           // Máximas
    double               m_low[];            // Mínimas
    double               m_close[];          // Fechamentos
    datetime             m_time[];           // Tempos
    
    // Cache de pontos importantes
    struct PivotPoint
    {
        datetime time;
        double   price;
        bool     isHigh;    // true = topo, false = fundo
        int      index;
    };
    
    PivotPoint           m_pivots[];         // Pontos de pivô identificados
    
public:
    //+------------------------------------------------------------------+
    //| Construtor                                                       |
    //+------------------------------------------------------------------+
    CTrendLines()
    {
        m_symbol = "";
        InitializeTrendLine(m_lta);
        InitializeTrendLine(m_ltb);
        
        ArraySetAsSeries(m_high, true);
        ArraySetAsSeries(m_low, true);
        ArraySetAsSeries(m_close, true);
        ArraySetAsSeries(m_time, true);
    }
    
    //+------------------------------------------------------------------+
    //| Destrutor                                                        |
    //+------------------------------------------------------------------+
    ~CTrendLines()
    {
        ArrayFree(m_high);
        ArrayFree(m_low);
        ArrayFree(m_close);
        ArrayFree(m_time);
        ArrayFree(m_pivots);
    }
    
    //+------------------------------------------------------------------+
    //| Inicializar com símbolo                                         |
    //+------------------------------------------------------------------+
    bool Initialize(string symbol)
    {
        if(symbol == "" || symbol == NULL)
        {
            CCoreUtils::LogError("Símbolo inválido para TrendLines");
            return false;
        }
        
        m_symbol = symbol;
        CCoreUtils::LogInfo("TrendLines inicializado para " + symbol);
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular Linha de Tendência de Alta (LTA)                      |
    //+------------------------------------------------------------------+
    bool CalculateLTA(string symbol, ENUM_TIMEFRAMES tf)
    {
        if(symbol != "") m_symbol = symbol;
        
        // Obter dados históricos
        if(!GetHistoricalData(tf, HISTORY_BARS_TRENDLINE))
        {
            CCoreUtils::LogError("Falha ao obter dados para LTA");
            return false;
        }
        
        // Identificar fundos locais
        if(!IdentifyPivotPoints(false)) // false = fundos
        {
            CCoreUtils::LogError("Falha ao identificar fundos para LTA");
            return false;
        }
        
        // Encontrar a melhor linha conectando fundos ascendentes
        if(!FindBestTrendLine(false, m_lta)) // false = linha de alta (conecta fundos)
        {
            CCoreUtils::LogWarning("Não foi possível encontrar LTA válida");
            return false;
        }
        
        // Validar linha com terceiro toque
        if(!ValidateTrendLine(m_lta, false))
        {
            CCoreUtils::LogWarning("LTA não passou na validação");
            return false;
        }
        
        CCoreUtils::LogInfo("LTA calculada com sucesso. Toques: " + IntegerToString(m_lta.touches));
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular Linha de Tendência de Baixa (LTB)                     |
    //+------------------------------------------------------------------+
    bool CalculateLTB(string symbol, ENUM_TIMEFRAMES tf)
    {
        if(symbol != "") m_symbol = symbol;
        
        // Obter dados históricos
        if(!GetHistoricalData(tf, HISTORY_BARS_TRENDLINE))
        {
            CCoreUtils::LogError("Falha ao obter dados para LTB");
            return false;
        }
        
        // Identificar topos locais
        if(!IdentifyPivotPoints(true)) // true = topos
        {
            CCoreUtils::LogError("Falha ao identificar topos para LTB");
            return false;
        }
        
        // Encontrar a melhor linha conectando topos descendentes
        if(!FindBestTrendLine(true, m_ltb)) // true = linha de baixa (conecta topos)
        {
            CCoreUtils::LogWarning("Não foi possível encontrar LTB válida");
            return false;
        }
        
        // Validar linha com terceiro toque
        if(!ValidateTrendLine(m_ltb, true))
        {
            CCoreUtils::LogWarning("LTB não passou na validação");
            return false;
        }
        
        CCoreUtils::LogInfo("LTB calculada com sucesso. Toques: " + IntegerToString(m_ltb.touches));
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Obter nível atual da LTA                                        |
    //+------------------------------------------------------------------+
    double GetCurrentLTALevel(datetime time)
    {
        if(!m_lta.isValid)
        {
            return 0;
        }
        
        return CCoreUtils::CalculateLinePrice(m_lta.time1, m_lta.price1, m_lta.slope, time);
    }
    
    //+------------------------------------------------------------------+
    //| Obter nível atual da LTB                                        |
    //+------------------------------------------------------------------+
    double GetCurrentLTBLevel(datetime time)
    {
        if(!m_ltb.isValid)
        {
            return 0;
        }
        
        return CCoreUtils::CalculateLinePrice(m_ltb.time1, m_ltb.price1, m_ltb.slope, time);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está próximo da LTA                         |
    //+------------------------------------------------------------------+
    bool IsPriceNearLTA(double currentPrice, double tolerance)
    {
        if(!m_lta.isValid)
        {
            return false;
        }
        
        double ltaLevel = GetCurrentLTALevel(TimeCurrent());
        if(ltaLevel == 0) return false;
        
        return CCoreUtils::IsPriceWithinTolerance(currentPrice, ltaLevel, tolerance, m_symbol);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está próximo da LTB                         |
    //+------------------------------------------------------------------+
    bool IsPriceNearLTB(double currentPrice, double tolerance)
    {
        if(!m_ltb.isValid)
        {
            return false;
        }
        
        double ltbLevel = GetCurrentLTBLevel(TimeCurrent());
        if(ltbLevel == 0) return false;
        
        return CCoreUtils::IsPriceWithinTolerance(currentPrice, ltbLevel, tolerance, m_symbol);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se LTA está sendo respeitada                         |
    //+------------------------------------------------------------------+
    bool IsLTABeingRespected()
    {
        if(!m_lta.isValid) return false;
        
        // Verificar últimas 5 barras
        int barsToCheck = MathMin(5, ArraySize(m_low));
        double tolerance = TOLERANCE_TRENDLINE;
        
        for(int i = 0; i < barsToCheck; i++)
        {
            double ltaLevel = GetCurrentLTALevel(m_time[i]);
            if(ltaLevel > 0)
            {
                // Se preço quebrou significativamente abaixo da LTA
                if(m_low[i] < ltaLevel - CCoreUtils::PointsToPrice(tolerance, m_symbol))
                {
                    return false;
                }
            }
        }
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se LTB está sendo respeitada                         |
    //+------------------------------------------------------------------+
    bool IsLTBBeingRespected()
    {
        if(!m_ltb.isValid) return false;
        
        // Verificar últimas 5 barras
        int barsToCheck = MathMin(5, ArraySize(m_high));
        double tolerance = TOLERANCE_TRENDLINE;
        
        for(int i = 0; i < barsToCheck; i++)
        {
            double ltbLevel = GetCurrentLTBLevel(m_time[i]);
            if(ltbLevel > 0)
            {
                // Se preço quebrou significativamente acima da LTB
                if(m_high[i] > ltbLevel + CCoreUtils::PointsToPrice(tolerance, m_symbol))
                {
                    return false;
                }
            }
        }
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Obter informações da LTA                                        |
    //+------------------------------------------------------------------+
    TrendLine GetLTA() const { return m_lta; }
    
    //+------------------------------------------------------------------+
    //| Obter informações da LTB                                        |
    //+------------------------------------------------------------------+
    TrendLine GetLTB() const { return m_ltb; }
    
    //+------------------------------------------------------------------+
    //| Verificar se LTA é válida                                       |
    //+------------------------------------------------------------------+
    bool IsLTAValid() const { return m_lta.isValid; }
    
    //+------------------------------------------------------------------+
    //| Verificar se LTB é válida                                       |
    //+------------------------------------------------------------------+
    bool IsLTBValid() const { return m_ltb.isValid; }

private:
    //+------------------------------------------------------------------+
    //| Inicializar estrutura de linha de tendência                    |
    //+------------------------------------------------------------------+
    void InitializeTrendLine(TrendLine &line)
    {
        line.time1 = 0;
        line.time2 = 0;
        line.price1 = 0;
        line.price2 = 0;
        line.touches = 0;
        line.slope = 0;
        line.isValid = false;
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
    //| Identificar pontos de pivô                                     |
    //+------------------------------------------------------------------+
    bool IdentifyPivotPoints(bool findHighs)
    {
        ArrayFree(m_pivots);
        
        int arraySize = ArraySize(findHighs ? m_high : m_low);
        if(arraySize < 10) return false;
        
        // Procurar pontos de pivô
        for(int i = 3; i < arraySize - 3; i++)
        {
            bool isPivot = true;
            double currentPrice = findHighs ? m_high[i] : m_low[i];
            
            // Verificar se é máximo/mínimo local
            for(int j = i - 3; j <= i + 3; j++)
            {
                if(j == i) continue;
                
                double comparePrice = findHighs ? m_high[j] : m_low[j];
                
                if(findHighs)
                {
                    if(comparePrice >= currentPrice)
                    {
                        isPivot = false;
                        break;
                    }
                }
                else
                {
                    if(comparePrice <= currentPrice)
                    {
                        isPivot = false;
                        break;
                    }
                }
            }
            
            if(isPivot)
            {
                // Adicionar ponto de pivô
                int newSize = ArraySize(m_pivots) + 1;
                ArrayResize(m_pivots, newSize);
                
                m_pivots[newSize-1].time = m_time[i];
                m_pivots[newSize-1].price = currentPrice;
                m_pivots[newSize-1].isHigh = findHighs;
                m_pivots[newSize-1].index = i;
            }
        }
        
        return ArraySize(m_pivots) >= 2;
    }
    
    //+------------------------------------------------------------------+
    //| Encontrar melhor linha de tendência                            |
    //+------------------------------------------------------------------+
    bool FindBestTrendLine(bool isDownTrend, TrendLine &line)
    {
        if(ArraySize(m_pivots) < 2) return false;
        
        int bestTouches = 0;
        TrendLine bestLine;
        InitializeTrendLine(bestLine);
        
        // Testar todas as combinações de pontos
        for(int i = 0; i < ArraySize(m_pivots) - 1; i++)
        {
            for(int j = i + 1; j < ArraySize(m_pivots); j++)
            {
                // Verificar se a linha tem a direção correta
                bool isAscending = m_pivots[j].price > m_pivots[i].price;
                
                if(isDownTrend && isAscending) continue;    // LTB deve ser descendente
                if(!isDownTrend && !isAscending) continue; // LTA deve ser ascendente
                
                TrendLine testLine;
                testLine.time1 = m_pivots[i].time;
                testLine.price1 = m_pivots[i].price;
                testLine.time2 = m_pivots[j].time;
                testLine.price2 = m_pivots[j].price;
                testLine.slope = CCoreUtils::CalculateSlope(testLine.time1, testLine.price1, 
                                                          testLine.time2, testLine.price2);
                testLine.touches = 2;
                testLine.isValid = true;
                
                // Contar toques adicionais
                int additionalTouches = CountLineTouches(testLine, isDownTrend);
                testLine.touches += additionalTouches;
                
                // Verificar se é a melhor linha até agora
                if(testLine.touches > bestTouches)
                {
                    bestTouches = testLine.touches;
                    bestLine = testLine;
                }
            }
        }
        
        if(bestTouches >= MIN_TRENDLINE_TOUCHES)
        {
            line = bestLine;
            return true;
        }
        
        return false;
    }
    
    //+------------------------------------------------------------------+
    //| Contar toques na linha                                         |
    //+------------------------------------------------------------------+
    int CountLineTouches(const TrendLine &line, bool isDownTrend)
    {
        int touches = 0;
        double tolerance = CCoreUtils::PointsToPrice(TOLERANCE_TRENDLINE, m_symbol);
        
        int arraySize = ArraySize(m_time);
        
        for(int i = 0; i < arraySize; i++)
        {
            if(m_time[i] <= line.time1 || m_time[i] >= line.time2) continue;
            
            double linePrice = CCoreUtils::CalculateLinePrice(line.time1, line.price1, line.slope, m_time[i]);
            double testPrice = isDownTrend ? m_high[i] : m_low[i];
            
            if(MathAbs(testPrice - linePrice) <= tolerance)
            {
                touches++;
            }
        }
        
        return touches;
    }
    
    //+------------------------------------------------------------------+
    //| Validar linha de tendência                                     |
    //+------------------------------------------------------------------+
    bool ValidateTrendLine(const TrendLine &line, bool isDownTrend)
    {
        if(!line.isValid) return false;
        if(line.touches < MIN_TRENDLINE_TOUCHES) return false;
        
        // Verificar se a inclinação está na direção correta
        if(isDownTrend && line.slope >= 0) return false;  // LTB deve ter inclinação negativa
        if(!isDownTrend && line.slope <= 0) return false; // LTA deve ter inclinação positiva
        
        // Verificar se a linha não foi quebrada recentemente
        double tolerance = CCoreUtils::PointsToPrice(TOLERANCE_TRENDLINE, m_symbol);
        int recentBars = MathMin(10, ArraySize(m_time));
        
        for(int i = 0; i < recentBars; i++)
        {
            double linePrice = CCoreUtils::CalculateLinePrice(line.time1, line.price1, line.slope, m_time[i]);
            
            if(isDownTrend)
            {
                // Para LTB, verificar se preço não quebrou significativamente acima
                if(m_high[i] > linePrice + tolerance)
                {
                    return false;
                }
            }
            else
            {
                // Para LTA, verificar se preço não quebrou significativamente abaixo
                if(m_low[i] < linePrice - tolerance)
                {
                    return false;
                }
            }
        }
        
        return true;
    }
};

#endif // TREND_LINES_H

