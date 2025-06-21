//+------------------------------------------------------------------+
//| Channels.mqh - Análise de Canais                                |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef CHANNELS_H
#define CHANNELS_H

#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "../Core/CoreUtils.mqh"
#include "TrendLines.mqh"

//+------------------------------------------------------------------+
//| Classe de Análise de Canais                                     |
//+------------------------------------------------------------------+
class CChannels : public CObject
{
private:
    Channel              m_currentChannel;   // Canal atual
    string               m_symbol;           // Símbolo
    CTrendLines*         m_trendLines;       // Referência para linhas de tendência
    
    // Arrays para análise
    double               m_high[];           // Máximas
    double               m_low[];            // Mínimas
    double               m_close[];          // Fechamentos
    datetime             m_time[];           // Tempos
    
public:
    //+------------------------------------------------------------------+
    //| Construtor                                                       |
    //+------------------------------------------------------------------+
    CChannels()
    {
        m_symbol = "";
        m_trendLines = NULL;
        InitializeChannel(m_currentChannel);
        
        ArraySetAsSeries(m_high, true);
        ArraySetAsSeries(m_low, true);
        ArraySetAsSeries(m_close, true);
        ArraySetAsSeries(m_time, true);
    }
    
    //+------------------------------------------------------------------+
    //| Destrutor                                                        |
    //+------------------------------------------------------------------+
    ~CChannels()
    {
        ArrayFree(m_high);
        ArrayFree(m_low);
        ArrayFree(m_close);
        ArrayFree(m_time);
    }
    
    //+------------------------------------------------------------------+
    //| Inicializar com símbolo e referência de trend lines            |
    //+------------------------------------------------------------------+
    bool Initialize(string symbol, CTrendLines* trendLines)
    {
        if(symbol == "" || symbol == NULL)
        {
            CCoreUtils::LogError("Símbolo inválido para Channels");
            return false;
        }
        
        if(trendLines == NULL)
        {
            CCoreUtils::LogError("Referência de TrendLines inválida");
            return false;
        }
        
        m_symbol = symbol;
        m_trendLines = trendLines;
        
        CCoreUtils::LogInfo("Channels inicializado para " + symbol);
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Identificar canal                                               |
    //+------------------------------------------------------------------+
    bool IdentifyChannel(string symbol, ENUM_TIMEFRAMES tf)
    {
        if(symbol != "") m_symbol = symbol;
        
        // Obter dados históricos
        if(!GetHistoricalData(tf, HISTORY_BARS_ANALYSIS))
        {
            CCoreUtils::LogError("Falha ao obter dados para análise de canal");
            return false;
        }
        
        // Verificar se temos linhas de tendência válidas
        if(m_trendLines == NULL)
        {
            CCoreUtils::LogError("TrendLines não inicializado");
            return false;
        }
        
        // Tentar identificar canal baseado em LTA
        if(m_trendLines.IsLTAValid())
        {
            if(IdentifyChannelFromLTA())
            {
                m_currentChannel.type = CHANNEL_ASCENDING;
                CCoreUtils::LogInfo("Canal ascendente identificado");
                return true;
            }
        }
        
        // Tentar identificar canal baseado em LTB
        if(m_trendLines.IsLTBValid())
        {
            if(IdentifyChannelFromLTB())
            {
                m_currentChannel.type = CHANNEL_DESCENDING;
                CCoreUtils::LogInfo("Canal descendente identificado");
                return true;
            }
        }
        
        // Tentar identificar canal horizontal
        if(IdentifyHorizontalChannel())
        {
            m_currentChannel.type = CHANNEL_HORIZONTAL;
            CCoreUtils::LogInfo("Canal horizontal identificado");
            return true;
        }
        
        CCoreUtils::LogWarning("Nenhum canal válido identificado");
        return false;
    }
    
    //+------------------------------------------------------------------+
    //| Obter posição do preço no canal                                |
    //+------------------------------------------------------------------+
    ENUM_CHANNEL_POSITION GetPricePosition(double currentPrice)
    {
        if(!m_currentChannel.isValid)
        {
            return CHANNEL_MIDDLE; // Padrão se não há canal
        }
        
        datetime currentTime = TimeCurrent();
        
        // Calcular níveis das linhas no tempo atual
        double upperLevel = CCoreUtils::CalculateLinePrice(
            m_currentChannel.upperLine.time1,
            m_currentChannel.upperLine.price1,
            m_currentChannel.upperLine.slope,
            currentTime
        );
        
        double lowerLevel = CCoreUtils::CalculateLinePrice(
            m_currentChannel.lowerLine.time1,
            m_currentChannel.lowerLine.price1,
            m_currentChannel.lowerLine.slope,
            currentTime
        );
        
        // Calcular posição relativa (0-100%)
        double channelRange = upperLevel - lowerLevel;
        if(channelRange <= 0) return CHANNEL_MIDDLE;
        
        double relativePosition = ((currentPrice - lowerLevel) / channelRange) * 100.0;
        
        // Determinar posição
        if(relativePosition >= CHANNEL_UPPER_THRESHOLD)
        {
            return CHANNEL_UPPER;
        }
        else if(relativePosition <= CHANNEL_LOWER_THRESHOLD)
        {
            return CHANNEL_LOWER;
        }
        else
        {
            return CHANNEL_MIDDLE;
        }
    }
    
    //+------------------------------------------------------------------+
    //| Obter largura atual do canal                                   |
    //+------------------------------------------------------------------+
    double GetCurrentChannelWidth()
    {
        if(!m_currentChannel.isValid)
        {
            return 0;
        }
        
        datetime currentTime = TimeCurrent();
        
        double upperLevel = CCoreUtils::CalculateLinePrice(
            m_currentChannel.upperLine.time1,
            m_currentChannel.upperLine.price1,
            m_currentChannel.upperLine.slope,
            currentTime
        );
        
        double lowerLevel = CCoreUtils::CalculateLinePrice(
            m_currentChannel.lowerLine.time1,
            m_currentChannel.lowerLine.price1,
            m_currentChannel.lowerLine.slope,
            currentTime
        );
        
        return upperLevel - lowerLevel;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está próximo da linha superior              |
    //+------------------------------------------------------------------+
    bool IsPriceNearUpperLine(double currentPrice, double tolerance)
    {
        if(!m_currentChannel.isValid) return false;
        
        datetime currentTime = TimeCurrent();
        double upperLevel = CCoreUtils::CalculateLinePrice(
            m_currentChannel.upperLine.time1,
            m_currentChannel.upperLine.price1,
            m_currentChannel.upperLine.slope,
            currentTime
        );
        
        return CCoreUtils::IsPriceWithinTolerance(currentPrice, upperLevel, tolerance, m_symbol);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está próximo da linha inferior              |
    //+------------------------------------------------------------------+
    bool IsPriceNearLowerLine(double currentPrice, double tolerance)
    {
        if(!m_currentChannel.isValid) return false;
        
        datetime currentTime = TimeCurrent();
        double lowerLevel = CCoreUtils::CalculateLinePrice(
            m_currentChannel.lowerLine.time1,
            m_currentChannel.lowerLine.price1,
            m_currentChannel.lowerLine.slope,
            currentTime
        );
        
        return CCoreUtils::IsPriceWithinTolerance(currentPrice, lowerLevel, tolerance, m_symbol);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se canal está sendo respeitado                       |
    //+------------------------------------------------------------------+
    bool IsChannelBeingRespected()
    {
        if(!m_currentChannel.isValid) return false;
        
        // Verificar últimas 10 barras
        int barsToCheck = MathMin(10, ArraySize(m_close));
        double tolerance = CCoreUtils::PointsToPrice(TOLERANCE_TRENDLINE, m_symbol);
        
        for(int i = 0; i < barsToCheck; i++)
        {
            double upperLevel = CCoreUtils::CalculateLinePrice(
                m_currentChannel.upperLine.time1,
                m_currentChannel.upperLine.price1,
                m_currentChannel.upperLine.slope,
                m_time[i]
            );
            
            double lowerLevel = CCoreUtils::CalculateLinePrice(
                m_currentChannel.lowerLine.time1,
                m_currentChannel.lowerLine.price1,
                m_currentChannel.lowerLine.slope,
                m_time[i]
            );
            
            // Verificar se preço quebrou significativamente o canal
            if(m_high[i] > upperLevel + tolerance || m_low[i] < lowerLevel - tolerance)
            {
                return false;
            }
        }
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Obter informações do canal atual                               |
    //+------------------------------------------------------------------+
    Channel GetCurrentChannel() const { return m_currentChannel; }
    
    //+------------------------------------------------------------------+
    //| Verificar se canal é válido                                    |
    //+------------------------------------------------------------------+
    bool IsChannelValid() const { return m_currentChannel.isValid; }
    
    //+------------------------------------------------------------------+
    //| Obter tipo do canal                                            |
    //+------------------------------------------------------------------+
    ENUM_CHANNEL_TYPE GetChannelType() const { return m_currentChannel.type; }

private:
    //+------------------------------------------------------------------+
    //| Inicializar estrutura de canal                                 |
    //+------------------------------------------------------------------+
    void InitializeChannel(Channel &channel)
    {
        InitializeTrendLine(channel.upperLine);
        InitializeTrendLine(channel.lowerLine);
        channel.width = 0;
        channel.isValid = false;
        channel.type = CHANNEL_HORIZONTAL;
    }
    
    //+------------------------------------------------------------------+
    //| Inicializar linha de tendência                                 |
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
    //| Identificar canal baseado em LTA                               |
    //+------------------------------------------------------------------+
    bool IdentifyChannelFromLTA()
    {
        TrendLine lta = m_trendLines.GetLTA();
        if(!lta.isValid) return false;
        
        // Usar LTA como linha inferior do canal
        m_currentChannel.lowerLine = lta;
        
        // Encontrar linha paralela conectando topos
        if(!FindParallelLine(lta, true, m_currentChannel.upperLine))
        {
            return false;
        }
        
        // Validar canal
        return ValidateChannel();
    }
    
    //+------------------------------------------------------------------+
    //| Identificar canal baseado em LTB                               |
    //+------------------------------------------------------------------+
    bool IdentifyChannelFromLTB()
    {
        TrendLine ltb = m_trendLines.GetLTB();
        if(!ltb.isValid) return false;
        
        // Usar LTB como linha superior do canal
        m_currentChannel.upperLine = ltb;
        
        // Encontrar linha paralela conectando fundos
        if(!FindParallelLine(ltb, false, m_currentChannel.lowerLine))
        {
            return false;
        }
        
        // Validar canal
        return ValidateChannel();
    }
    
    //+------------------------------------------------------------------+
    //| Identificar canal horizontal                                   |
    //+------------------------------------------------------------------+
    bool IdentifyHorizontalChannel()
    {
        // Encontrar níveis de suporte e resistência horizontais
        double supportLevel = 0, resistanceLevel = 0;
        
        if(!FindHorizontalLevels(supportLevel, resistanceLevel))
        {
            return false;
        }
        
        // Criar linhas horizontais
        datetime startTime = m_time[ArraySize(m_time) - 50]; // 50 barras atrás
        datetime endTime = m_time[0];
        
        // Linha inferior (suporte)
        m_currentChannel.lowerLine.time1 = startTime;
        m_currentChannel.lowerLine.time2 = endTime;
        m_currentChannel.lowerLine.price1 = supportLevel;
        m_currentChannel.lowerLine.price2 = supportLevel;
        m_currentChannel.lowerLine.slope = 0;
        m_currentChannel.lowerLine.touches = 3; // Mínimo para validação
        m_currentChannel.lowerLine.isValid = true;
        
        // Linha superior (resistência)
        m_currentChannel.upperLine.time1 = startTime;
        m_currentChannel.upperLine.time2 = endTime;
        m_currentChannel.upperLine.price1 = resistanceLevel;
        m_currentChannel.upperLine.price2 = resistanceLevel;
        m_currentChannel.upperLine.slope = 0;
        m_currentChannel.upperLine.touches = 3; // Mínimo para validação
        m_currentChannel.upperLine.isValid = true;
        
        return ValidateChannel();
    }
    
    //+------------------------------------------------------------------+
    //| Encontrar linha paralela                                       |
    //+------------------------------------------------------------------+
    bool FindParallelLine(const TrendLine &baseLine, bool findUpper, TrendLine &parallelLine)
    {
        // Encontrar pontos para linha paralela
        double bestDistance = 0;
        int bestTouches = 0;
        TrendLine bestLine;
        InitializeTrendLine(bestLine);
        
        // Procurar pontos que formem linha paralela
        for(int i = 10; i < ArraySize(m_time) - 10; i++)
        {
            for(int j = i + 10; j < ArraySize(m_time); j++)
            {
                double price1 = findUpper ? m_high[i] : m_low[i];
                double price2 = findUpper ? m_high[j] : m_low[j];
                
                // Calcular inclinação da linha candidata
                double candidateSlope = CCoreUtils::CalculateSlope(m_time[i], price1, m_time[j], price2);
                
                // Verificar se é aproximadamente paralela à linha base
                double slopeDifference = MathAbs(candidateSlope - baseLine.slope);
                double maxSlopeDifference = MathAbs(baseLine.slope) * 0.1; // 10% de tolerância
                
                if(slopeDifference <= maxSlopeDifference)
                {
                    // Criar linha candidata
                    TrendLine candidate;
                    candidate.time1 = m_time[i];
                    candidate.time2 = m_time[j];
                    candidate.price1 = price1;
                    candidate.price2 = price2;
                    candidate.slope = candidateSlope;
                    candidate.isValid = true;
                    
                    // Contar toques
                    int touches = CountParallelLineTouches(candidate, findUpper);
                    candidate.touches = touches;
                    
                    // Calcular distância média à linha base
                    double avgDistance = CalculateAverageDistance(baseLine, candidate);
                    
                    // Verificar se é melhor candidata
                    if(touches >= MIN_TRENDLINE_TOUCHES && 
                       (touches > bestTouches || (touches == bestTouches && avgDistance > bestDistance)))
                    {
                        bestTouches = touches;
                        bestDistance = avgDistance;
                        bestLine = candidate;
                    }
                }
            }
        }
        
        if(bestTouches >= MIN_TRENDLINE_TOUCHES)
        {
            parallelLine = bestLine;
            return true;
        }
        
        return false;
    }
    
    //+------------------------------------------------------------------+
    //| Contar toques na linha paralela                                |
    //+------------------------------------------------------------------+
    int CountParallelLineTouches(const TrendLine &line, bool isUpper)
    {
        int touches = 0;
        double tolerance = CCoreUtils::PointsToPrice(TOLERANCE_TRENDLINE, m_symbol);
        
        for(int i = 0; i < ArraySize(m_time); i++)
        {
            if(m_time[i] < line.time1 || m_time[i] > line.time2) continue;
            
            double linePrice = CCoreUtils::CalculateLinePrice(line.time1, line.price1, line.slope, m_time[i]);
            double testPrice = isUpper ? m_high[i] : m_low[i];
            
            if(MathAbs(testPrice - linePrice) <= tolerance)
            {
                touches++;
            }
        }
        
        return touches;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular distância média entre linhas                         |
    //+------------------------------------------------------------------+
    double CalculateAverageDistance(const TrendLine &line1, const TrendLine &line2)
    {
        double totalDistance = 0;
        int count = 0;
        
        datetime startTime = MathMax(line1.time1, line2.time1);
        datetime endTime = MathMin(line1.time2, line2.time2);
        
        for(int i = 0; i < ArraySize(m_time); i++)
        {
            if(m_time[i] >= startTime && m_time[i] <= endTime)
            {
                double price1 = CCoreUtils::CalculateLinePrice(line1.time1, line1.price1, line1.slope, m_time[i]);
                double price2 = CCoreUtils::CalculateLinePrice(line2.time1, line2.price1, line2.slope, m_time[i]);
                
                totalDistance += MathAbs(price2 - price1);
                count++;
            }
        }
        
        return (count > 0) ? totalDistance / count : 0;
    }
    
    //+------------------------------------------------------------------+
    //| Encontrar níveis horizontais                                   |
    //+------------------------------------------------------------------+
    bool FindHorizontalLevels(double &supportLevel, double &resistanceLevel)
    {
        // Encontrar máxima e mínima das últimas 50 barras
        int barsToAnalyze = MathMin(50, ArraySize(m_high));
        
        double highestHigh = m_high[ArrayMaximum(m_high, 0, barsToAnalyze)];
        double lowestLow = m_low[ArrayMinimum(m_low, 0, barsToAnalyze)];
        
        // Verificar se há níveis horizontais significativos
        supportLevel = lowestLow;
        resistanceLevel = highestHigh;
        
        // Validar se há toques suficientes nos níveis
        int supportTouches = CountHorizontalTouches(supportLevel, false);
        int resistanceTouches = CountHorizontalTouches(resistanceLevel, true);
        
        return (supportTouches >= MIN_TRENDLINE_TOUCHES && resistanceTouches >= MIN_TRENDLINE_TOUCHES);
    }
    
    //+------------------------------------------------------------------+
    //| Contar toques em nível horizontal                              |
    //+------------------------------------------------------------------+
    int CountHorizontalTouches(double level, bool isResistance)
    {
        int touches = 0;
        double tolerance = CCoreUtils::PointsToPrice(TOLERANCE_TRENDLINE, m_symbol);
        
        for(int i = 0; i < ArraySize(m_high); i++)
        {
            double testPrice = isResistance ? m_high[i] : m_low[i];
            
            if(MathAbs(testPrice - level) <= tolerance)
            {
                touches++;
            }
        }
        
        return touches;
    }
    
    //+------------------------------------------------------------------+
    //| Validar canal                                                  |
    //+------------------------------------------------------------------+
    bool ValidateChannel()
    {
        if(!m_currentChannel.upperLine.isValid || !m_currentChannel.lowerLine.isValid)
        {
            return false;
        }
        
        // Calcular largura do canal
        m_currentChannel.width = CalculateAverageDistance(m_currentChannel.upperLine, m_currentChannel.lowerLine);
        
        if(m_currentChannel.width <= 0)
        {
            return false;
        }
        
        // Verificar consistência da largura (variação < 10%)
        if(!IsChannelWidthConsistent())
        {
            return false;
        }
        
        // Verificar toques mínimos
        if(m_currentChannel.upperLine.touches < MIN_TRENDLINE_TOUCHES ||
           m_currentChannel.lowerLine.touches < MIN_TRENDLINE_TOUCHES)
        {
            return false;
        }
        
        m_currentChannel.isValid = true;
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar consistência da largura do canal                     |
    //+------------------------------------------------------------------+
    bool IsChannelWidthConsistent()
    {
        double maxVariation = m_currentChannel.width * (CHANNEL_WIDTH_TOLERANCE / 100.0);
        
        // Verificar largura em diferentes pontos
        datetime startTime = MathMax(m_currentChannel.upperLine.time1, m_currentChannel.lowerLine.time1);
        datetime endTime = MathMin(m_currentChannel.upperLine.time2, m_currentChannel.lowerLine.time2);
        
        for(int i = 0; i < ArraySize(m_time); i++)
        {
            if(m_time[i] >= startTime && m_time[i] <= endTime)
            {
                double upperPrice = CCoreUtils::CalculateLinePrice(
                    m_currentChannel.upperLine.time1,
                    m_currentChannel.upperLine.price1,
                    m_currentChannel.upperLine.slope,
                    m_time[i]
                );
                
                double lowerPrice = CCoreUtils::CalculateLinePrice(
                    m_currentChannel.lowerLine.time1,
                    m_currentChannel.lowerLine.price1,
                    m_currentChannel.lowerLine.slope,
                    m_time[i]
                );
                
                double currentWidth = upperPrice - lowerPrice;
                
                if(MathAbs(currentWidth - m_currentChannel.width) > maxVariation)
                {
                    return false;
                }
            }
        }
        
        return true;
    }
};

#endif // CHANNELS_H

