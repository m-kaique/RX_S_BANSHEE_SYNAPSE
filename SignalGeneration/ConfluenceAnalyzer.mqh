//+------------------------------------------------------------------+
//| ConfluenceAnalyzer.mqh - Analisador de Confluência              |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef CONFLUENCE_ANALYZER_H
#define CONFLUENCE_ANALYZER_H
#property strict

#include <Object.mqh>
#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "../Core/CoreUtils.mqh"
#include "../PriceAction/TrendLines.mqh"
#include "../PriceAction/SupportResistance.mqh"
#include "../PriceAction/Channels.mqh"
#include "../Indicators/MovingAverages.mqh"
#include "../Indicators/VWAP.mqh"
#include "../Indicators/BollingerBands.mqh"
#include "../Indicators/Fibonacci.mqh"
#include "../Indicators/VolumeAnalyzer.mqh"

//+------------------------------------------------------------------+
//| Classe Analisadora de Confluência                               |
//+------------------------------------------------------------------+
class CConfluenceAnalyzer : public CObject
{
private:
    string               m_symbol;           // Símbolo
    
    // Componentes de análise
    CTrendLines*         m_trendLines;       // Linhas de tendência
    CSupportResistance*  m_supRes;           // Suporte/Resistência
    CChannels*           m_channels;         // Canais
    CMovingAverages*     m_movingAverages;   // Médias móveis
    CVWAP*               m_vwap;             // VWAP
    CBollingerBands*     m_bollingerBands;   // Bandas de Bollinger
    CFibonacci*          m_fibonacci;        // Fibonacci
    CVolumeAnalyzer*     m_volumeAnalyzer;   // Análise de volume
    
    // Resultado da confluência
    ConfluenceResult     m_confluenceResult;
    
    // Fatores de confluência
    ConfluenceFactor     m_factors[MAX_CONFLUENCE_FACTORS];
    int                  m_factorCount;
    
    datetime             m_lastUpdate;       // Última atualização
    bool                 m_initialized;      // Status de inicialização
    
public:
    //+------------------------------------------------------------------+
    //| Construtor                                                       |
    //+------------------------------------------------------------------+
    CConfluenceAnalyzer()
    {
        m_symbol = "";
        
        m_trendLines = NULL;
        m_supRes = NULL;
        m_channels = NULL;
        m_movingAverages = NULL;
        m_vwap = NULL;
        m_bollingerBands = NULL;
        m_fibonacci = NULL;
        m_volumeAnalyzer = NULL;
        
        InitializeConfluenceResult(m_confluenceResult);
        
        m_factorCount = 0;
        
        m_lastUpdate = 0;
        m_initialized = false;
    }
    
    //+------------------------------------------------------------------+
    //| Destrutor                                                        |
    //+------------------------------------------------------------------+
    ~CConfluenceAnalyzer()
    {
        if(m_trendLines != NULL) delete m_trendLines;
        if(m_supRes != NULL) delete m_supRes;
        if(m_channels != NULL) delete m_channels;
        if(m_movingAverages != NULL) delete m_movingAverages;
        if(m_vwap != NULL) delete m_vwap;
        if(m_bollingerBands != NULL) delete m_bollingerBands;
        if(m_fibonacci != NULL) delete m_fibonacci;
        if(m_volumeAnalyzer != NULL) delete m_volumeAnalyzer;
    }
    
    //+------------------------------------------------------------------+
    //| Inicializar analisador de confluência                          |
    //+------------------------------------------------------------------+
    bool Initialize(string symbol)
    {
        if(symbol == "" || symbol == NULL)
        {
            CCoreUtils::LogError("Símbolo inválido para ConfluenceAnalyzer");
            return false;
        }
        
        m_symbol = symbol;
        
        // Criar componentes de análise
        m_trendLines = new CTrendLines();
        m_supRes = new CSupportResistance();
        m_channels = new CChannels();
        m_movingAverages = new CMovingAverages();
        m_vwap = new CVWAP();
        m_bollingerBands = new CBollingerBands();
        m_fibonacci = new CFibonacci();
        m_volumeAnalyzer = new CVolumeAnalyzer();
        
        // Inicializar componentes
        bool allInitialized = true;
        
        allInitialized &= m_trendLines.Initialize(symbol);
        allInitialized &= m_supRes.Initialize(symbol);
        allInitialized &= m_channels.Initialize(symbol, m_trendLines);
        allInitialized &= m_movingAverages.Initialize(symbol);
        allInitialized &= m_vwap.Initialize(symbol);
        allInitialized &= m_bollingerBands.Initialize(symbol);
        allInitialized &= m_fibonacci.Initialize(symbol);
        allInitialized &= m_volumeAnalyzer.Initialize(symbol);
        
        if(!allInitialized)
        {
            CCoreUtils::LogError("Falha ao inicializar componentes do ConfluenceAnalyzer");
            return false;
        }
        
        m_initialized = true;
        CCoreUtils::LogInfo("ConfluenceAnalyzer inicializado com sucesso para " + symbol);
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Analisar confluência                                           |
    //+------------------------------------------------------------------+
    bool AnalyzeConfluence(string symbol = "")
    {
        if(symbol != "") m_symbol = symbol;
        
        if(!m_initialized)
        {
            CCoreUtils::LogError("ConfluenceAnalyzer não inicializado");
            return false;
        }
        
        // Resetar resultado
        InitializeConfluenceResult(m_confluenceResult);
        m_confluenceResult.symbol = m_symbol;
        m_confluenceResult.timestamp = TimeCurrent();
        
        // Resetar fatores
        m_factorCount = 0;
        
        // Analisar cada componente
        AnalyzePriceActionConfluence();
        AnalyzeIndicatorConfluence();
        AnalyzeVolumeConfluence();
        
        // Consolidar resultado
        ConsolidateConfluenceResult();
        
        m_lastUpdate = TimeCurrent();
        
        CCoreUtils::LogInfo("Análise de confluência concluída - Score: " + 
                          DoubleToString(m_confluenceResult.confluenceScore, 1) + "%");
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Obter resultado da confluência                                 |
    //+------------------------------------------------------------------+
    ConfluenceResult GetConfluenceResult() const { return m_confluenceResult; }
    
    //+------------------------------------------------------------------+
    //| Obter fatores de confluência                                   |
    //+------------------------------------------------------------------+
    int GetConfluenceFactors(ConfluenceFactor &factors[])
    {
        if(m_factorCount == 0) return 0;
        
        ArrayResize(factors, m_factorCount);
        
        for(int i = 0; i < m_factorCount; i++)
        {
            factors[i] = m_factors[i];
        }
        
        return m_factorCount;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se está inicializado                                 |
    //+------------------------------------------------------------------+
    bool IsInitialized() const { return m_initialized; }

private:
    //+------------------------------------------------------------------+
    //| Inicializar resultado de confluência                           |
    //+------------------------------------------------------------------+
    void InitializeConfluenceResult(ConfluenceResult &result)
    {
        result.symbol = "";
        result.timestamp = 0;
        result.confluenceScore = 0;
        result.bullishFactors = 0;
        result.bearishFactors = 0;
        result.neutralFactors = 0;
        result.totalFactors = 0;
        result.strongestFactor = "";
        result.weakestFactor = "";
        result.isValid = false;
    }
    
    //+------------------------------------------------------------------+
    //| Analisar confluência de Price Action                           |
    //+------------------------------------------------------------------+
    void AnalyzePriceActionConfluence()
    {
        double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
        
        // Analisar linhas de tendência
        AnalyzeTrendLinesConfluence(currentPrice);
        
        // Analisar suporte e resistência
        AnalyzeSupportResistanceConfluence(currentPrice);
        
        // Analisar canais
        AnalyzeChannelsConfluence(currentPrice);
    }
    
    //+------------------------------------------------------------------+
    //| Analisar confluência de linhas de tendência                    |
    //+------------------------------------------------------------------+
    void AnalyzeTrendLinesConfluence(double currentPrice)
    {
        // Analisar LTA (Linha de Tendência de Alta)
        if(m_trendLines.IsLTAValid())
        {
            double ltaLevel = m_trendLines.GetCurrentLTALevel(TimeCurrent());
            bool nearLTA = m_trendLines.IsPriceNearLTA(currentPrice, TOLERANCE_TRENDLINE);
            
            if(nearLTA)
            {
                // Preço próximo da LTA - fator bullish
                AddConfluenceFactor("LTA Suporte", CONFLUENCE_BULLISH, 
                                  WEIGHT_TRENDLINE, "Preço próximo da LTA em " + 
                                  DoubleToString(ltaLevel, 2));
            }
            else if(currentPrice > ltaLevel)
            {
                // Preço acima da LTA - fator bullish fraco
                AddConfluenceFactor("Acima LTA", CONFLUENCE_BULLISH, 
                                  WEIGHT_TRENDLINE * 0.5, "Preço acima da LTA");
            }
        }
        
        // Analisar LTB (Linha de Tendência de Baixa)
        if(m_trendLines.IsLTBValid())
        {
            double ltbLevel = m_trendLines.GetCurrentLTBLevel(TimeCurrent());
            bool nearLTB = m_trendLines.IsPriceNearLTB(currentPrice, TOLERANCE_TRENDLINE);
            
            if(nearLTB)
            {
                // Preço próximo da LTB - fator bearish
                AddConfluenceFactor("LTB Resistência", CONFLUENCE_BEARISH, 
                                  WEIGHT_TRENDLINE, "Preço próximo da LTB em " + 
                                  DoubleToString(ltbLevel, 2));
            }
            else if(currentPrice < ltbLevel)
            {
                // Preço abaixo da LTB - fator bearish fraco
                AddConfluenceFactor("Abaixo LTB", CONFLUENCE_BEARISH, 
                                  WEIGHT_TRENDLINE * 0.5, "Preço abaixo da LTB");
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Analisar confluência de suporte e resistência                  |
    //+------------------------------------------------------------------+
    void AnalyzeSupportResistanceConfluence(double currentPrice)
    {
        // Obter níveis próximos
        double supportLevels[], resistanceLevels[];
        int supportCount = m_supRes.GetNearbySupports(currentPrice, TOLERANCE_SUPPORT_RESISTANCE, supportLevels);
        int resistanceCount = m_supRes.GetNearbyResistances(currentPrice, TOLERANCE_SUPPORT_RESISTANCE, resistanceLevels);
        
        // Analisar suportes
        for(int i = 0; i < supportCount; i++)
        {
            double distance = MathAbs(currentPrice - supportLevels[i]);
            double weight = WEIGHT_SUPPORT_RESISTANCE;
            
            // Peso maior para níveis mais próximos
            if(distance < TOLERANCE_SUPPORT_RESISTANCE * 0.5)
            {
                weight *= 1.5;
            }
            
            AddConfluenceFactor("Suporte", CONFLUENCE_BULLISH, weight, 
                              "Suporte em " + DoubleToString(supportLevels[i], 2));
        }
        
        // Analisar resistências
        for(int i = 0; i < resistanceCount; i++)
        {
            double distance = MathAbs(currentPrice - resistanceLevels[i]);
            double weight = WEIGHT_SUPPORT_RESISTANCE;
            
            // Peso maior para níveis mais próximos
            if(distance < TOLERANCE_SUPPORT_RESISTANCE * 0.5)
            {
                weight *= 1.5;
            }
            
            AddConfluenceFactor("Resistência", CONFLUENCE_BEARISH, weight, 
                              "Resistência em " + DoubleToString(resistanceLevels[i], 2));
        }
    }
    
    //+------------------------------------------------------------------+
    //| Analisar confluência de canais                                 |
    //+------------------------------------------------------------------+
    void AnalyzeChannelsConfluence(double currentPrice)
    {
        // Verificar se está em canal
        if(m_channels.IsInChannel(currentPrice))
        {
            ENUM_CHANNEL_TYPE channelType = m_channels.GetChannelType();
            ENUM_CHANNEL_POSITION position = m_channels.GetPricePositionInChannel(currentPrice);
            
            string channelName = "";
            switch(channelType)
            {
                case CHANNEL_ASCENDING:  channelName = "Canal Ascendente"; break;
                case CHANNEL_DESCENDING: channelName = "Canal Descendente"; break;
                case CHANNEL_HORIZONTAL: channelName = "Canal Horizontal"; break;
            }
            
            // Analisar posição no canal
            switch(position)
            {
                case CHANNEL_LOWER:
                    if(channelType == CHANNEL_ASCENDING || channelType == CHANNEL_HORIZONTAL)
                    {
                        AddConfluenceFactor(channelName + " - Inferior", CONFLUENCE_BULLISH, 
                                          WEIGHT_CHANNEL, "Preço na parte inferior do canal");
                    }
                    break;
                    
                case CHANNEL_UPPER:
                    if(channelType == CHANNEL_DESCENDING || channelType == CHANNEL_HORIZONTAL)
                    {
                        AddConfluenceFactor(channelName + " - Superior", CONFLUENCE_BEARISH, 
                                          WEIGHT_CHANNEL, "Preço na parte superior do canal");
                    }
                    break;
                    
                case CHANNEL_MIDDLE:
                    AddConfluenceFactor(channelName + " - Centro", CONFLUENCE_NEUTRAL, 
                                      WEIGHT_CHANNEL * 0.5, "Preço no centro do canal");
                    break;
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Analisar confluência de indicadores                            |
    //+------------------------------------------------------------------+
    void AnalyzeIndicatorConfluence()
    {
        double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
        
        // Analisar médias móveis
        AnalyzeMovingAveragesConfluence(currentPrice);
        
        // Analisar VWAP
        AnalyzeVWAPConfluence(currentPrice);
        
        // Analisar Bandas de Bollinger
        AnalyzeBollingerBandsConfluence(currentPrice);
        
        // Analisar Fibonacci
        AnalyzeFibonacciConfluence(currentPrice);
    }
    
    //+------------------------------------------------------------------+
    //| Analisar confluência de médias móveis                          |
    //+------------------------------------------------------------------+
    void AnalyzeMovingAveragesConfluence(double currentPrice)
    {
        ENUM_MA_ALIGNMENT alignment = m_movingAverages.GetAlignment();
        
        switch(alignment)
        {
            case MA_BULLISH:
                AddConfluenceFactor("MAs Bullish", CONFLUENCE_BULLISH, 
                                  WEIGHT_MOVING_AVERAGES, "Médias móveis alinhadas bullish");
                break;
                
            case MA_BEARISH:
                AddConfluenceFactor("MAs Bearish", CONFLUENCE_BEARISH, 
                                  WEIGHT_MOVING_AVERAGES, "Médias móveis alinhadas bearish");
                break;
                
            case MA_NEUTRAL:
                AddConfluenceFactor("MAs Neutras", CONFLUENCE_NEUTRAL, 
                                  WEIGHT_MOVING_AVERAGES * 0.3, "Médias móveis sem alinhamento");
                break;
        }
        
        // Verificar proximidade das médias
        if(m_movingAverages.IsNearMA21(currentPrice, TOLERANCE_MA))
        {
            AddConfluenceFactor("Próximo EMA21", CONFLUENCE_NEUTRAL, 
                              WEIGHT_MOVING_AVERAGES * 0.7, "Preço próximo da EMA21");
        }
        
        if(m_movingAverages.IsNearMA50(currentPrice, TOLERANCE_MA))
        {
            AddConfluenceFactor("Próximo EMA50", CONFLUENCE_NEUTRAL, 
                              WEIGHT_MOVING_AVERAGES * 0.8, "Preço próximo da EMA50");
        }
        
        // Verificar posição em relação à SMA200
        if(m_movingAverages.IsPriceAboveSMA200(currentPrice))
        {
            AddConfluenceFactor("Acima SMA200", CONFLUENCE_BULLISH, 
                              WEIGHT_MOVING_AVERAGES * 0.6, "Preço acima da SMA200");
        }
        else if(m_movingAverages.IsPriceBelowSMA200(currentPrice))
        {
            AddConfluenceFactor("Abaixo SMA200", CONFLUENCE_BEARISH, 
                              WEIGHT_MOVING_AVERAGES * 0.6, "Preço abaixo da SMA200");
        }
    }
    
    //+------------------------------------------------------------------+
    //| Analisar confluência do VWAP                                   |
    //+------------------------------------------------------------------+
    void AnalyzeVWAPConfluence(double currentPrice)
    {
        m_vwap.Calculate(m_symbol, PERIOD_M15);
        
        if(m_vwap.IsPriceAboveVWAP(currentPrice))
        {
            AddConfluenceFactor("Acima VWAP", CONFLUENCE_BULLISH, 
                              WEIGHT_VWAP, "Preço acima do VWAP");
        }
        else if(m_vwap.IsPriceBelowVWAP(currentPrice))
        {
            AddConfluenceFactor("Abaixo VWAP", CONFLUENCE_BEARISH, 
                              WEIGHT_VWAP, "Preço abaixo do VWAP");
        }
        
        // Verificar extremos
        if(m_vwap.IsPriceAtExtreme(currentPrice))
        {
            int deviationLevel = m_vwap.GetPriceDeviationLevel(currentPrice);
            
            if(deviationLevel >= 2)
            {
                if(currentPrice > m_vwap.GetVWAP())
                {
                    AddConfluenceFactor("VWAP Extremo Superior", CONFLUENCE_BEARISH, 
                                      WEIGHT_VWAP * 1.2, "Preço em extremo superior do VWAP (+" + 
                                      IntegerToString(deviationLevel) + "σ)");
                }
                else
                {
                    AddConfluenceFactor("VWAP Extremo Inferior", CONFLUENCE_BULLISH, 
                                      WEIGHT_VWAP * 1.2, "Preço em extremo inferior do VWAP (-" + 
                                      IntegerToString(deviationLevel) + "σ)");
                }
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Analisar confluência das Bandas de Bollinger                   |
    //+------------------------------------------------------------------+
    void AnalyzeBollingerBandsConfluence(double currentPrice)
    {
        // Verificar proximidade das bandas
        if(m_bollingerBands.IsPriceNearUpperBand(currentPrice, TOLERANCE_BB))
        {
            AddConfluenceFactor("Próximo Banda Superior", CONFLUENCE_BEARISH, 
                              WEIGHT_BOLLINGER, "Preço próximo da banda superior");
        }
        else if(m_bollingerBands.IsPriceNearLowerBand(currentPrice, TOLERANCE_BB))
        {
            AddConfluenceFactor("Próximo Banda Inferior", CONFLUENCE_BULLISH, 
                              WEIGHT_BOLLINGER, "Preço próximo da banda inferior");
        }
        
        // Verificar Walking the Bands
        if(m_bollingerBands.IsWalkingTheBands(m_symbol, BB_UPPER))
        {
            AddConfluenceFactor("Walking Upper Band", CONFLUENCE_BULLISH, 
                              WEIGHT_BOLLINGER * 1.3, "Walking the upper band");
        }
        else if(m_bollingerBands.IsWalkingTheBands(m_symbol, BB_LOWER))
        {
            AddConfluenceFactor("Walking Lower Band", CONFLUENCE_BEARISH, 
                              WEIGHT_BOLLINGER * 1.3, "Walking the lower band");
        }
        
        // Verificar squeeze
        if(m_bollingerBands.IsSqueeze())
        {
            AddConfluenceFactor("BB Squeeze", CONFLUENCE_NEUTRAL, 
                              WEIGHT_BOLLINGER * 0.8, "Bandas em squeeze - possível breakout");
        }
    }
    
    //+------------------------------------------------------------------+
    //| Analisar confluência do Fibonacci                              |
    //+------------------------------------------------------------------+
    void AnalyzeFibonacciConfluence(double currentPrice)
    {
        double nearestLevel = 0;
        bool nearFib = m_fibonacci.IsPriceNearFibLevel(currentPrice, TOLERANCE_FIBONACCI, nearestLevel);
        
        if(nearFib)
        {
            double levelStrength = m_fibonacci.GetLevelStrength(nearestLevel);
            double weight = WEIGHT_FIBONACCI * (levelStrength / 100.0);
            
            // Determinar se é suporte ou resistência baseado na tendência
            bool isSupport = (currentPrice <= nearestLevel * 1.001); // Aproximadamente igual ou abaixo
            
            if(isSupport)
            {
                AddConfluenceFactor("Fibonacci Suporte", CONFLUENCE_BULLISH, weight, 
                                  "Nível Fibonacci " + DoubleToString(nearestLevel, 2) + 
                                  " como suporte");
            }
            else
            {
                AddConfluenceFactor("Fibonacci Resistência", CONFLUENCE_BEARISH, weight, 
                                  "Nível Fibonacci " + DoubleToString(nearestLevel, 2) + 
                                  " como resistência");
            }
        }
        
        // Verificar zona de confluência
        if(m_fibonacci.IsInConfluenceZone(currentPrice, TOLERANCE_FIBONACCI))
        {
            AddConfluenceFactor("Zona Confluência Fib", CONFLUENCE_NEUTRAL, 
                              WEIGHT_FIBONACCI * 1.2, "Preço em zona de confluência Fibonacci");
        }
    }
    
    //+------------------------------------------------------------------+
    //| Analisar confluência de volume                                 |
    //+------------------------------------------------------------------+
    void AnalyzeVolumeConfluence()
    {
        m_volumeAnalyzer.AnalyzeVolume(m_symbol, PERIOD_M15);
        
        // Volume alto
        if(m_volumeAnalyzer.IsHighVolume())
        {
            AddConfluenceFactor("Volume Alto", CONFLUENCE_NEUTRAL, 
                              WEIGHT_VOLUME, "Volume acima da média (" + 
                              DoubleToString(m_volumeAnalyzer.GetVolumeRatio(), 2) + "x)");
        }
        
        // Volume baixo
        if(m_volumeAnalyzer.IsLowVolume())
        {
            AddConfluenceFactor("Volume Baixo", CONFLUENCE_NEUTRAL, 
                              WEIGHT_VOLUME * 0.5, "Volume abaixo da média");
        }
        
        // Climax de volume
        if(m_volumeAnalyzer.IsVolumeClimax())
        {
            AddConfluenceFactor("Climax Volume", CONFLUENCE_NEUTRAL, 
                              WEIGHT_VOLUME * 1.5, "Climax de volume detectado");
        }
        
        // Divergências
        if(m_volumeAnalyzer.IsVolumeDivergence(true))
        {
            AddConfluenceFactor("Divergência Bullish", CONFLUENCE_BULLISH, 
                              WEIGHT_VOLUME * 1.3, "Divergência bullish de volume");
        }
        else if(m_volumeAnalyzer.IsVolumeDivergence(false))
        {
            AddConfluenceFactor("Divergência Bearish", CONFLUENCE_BEARISH, 
                              WEIGHT_VOLUME * 1.3, "Divergência bearish de volume");
        }
    }
    
    //+------------------------------------------------------------------+
    //| Adicionar fator de confluência                                 |
    //+------------------------------------------------------------------+
    void AddConfluenceFactor(string name, ENUM_CONFLUENCE_TYPE type, double weight, string description)
    {
        if(m_factorCount >= MAX_CONFLUENCE_FACTORS)
        {
            return; // Limite atingido
        }
        
        m_factors[m_factorCount].name = name;
        m_factors[m_factorCount].type = type;
        m_factors[m_factorCount].weight = weight;
        m_factors[m_factorCount].description = description;
        m_factors[m_factorCount].isValid = true;
        
        m_factorCount++;
    }
    
    //+------------------------------------------------------------------+
    //| Consolidar resultado da confluência                            |
    //+------------------------------------------------------------------+
    void ConsolidateConfluenceResult()
    {
        if(m_factorCount == 0)
        {
            m_confluenceResult.isValid = false;
            return;
        }
        
        double bullishScore = 0;
        double bearishScore = 0;
        double neutralScore = 0;
        double totalWeight = 0;
        
        double maxWeight = 0;
        double minWeight = 999999;
        string strongestFactor = "";
        string weakestFactor = "";
        
        // Calcular scores e estatísticas
        for(int i = 0; i < m_factorCount; i++)
        {
            if(!m_factors[i].isValid) continue;
            
            double weight = m_factors[i].weight;
            totalWeight += weight;
            
            switch(m_factors[i].type)
            {
                case CONFLUENCE_BULLISH:
                    bullishScore += weight;
                    m_confluenceResult.bullishFactors++;
                    break;
                    
                case CONFLUENCE_BEARISH:
                    bearishScore += weight;
                    m_confluenceResult.bearishFactors++;
                    break;
                    
                case CONFLUENCE_NEUTRAL:
                    neutralScore += weight;
                    m_confluenceResult.neutralFactors++;
                    break;
            }
            
            // Encontrar fator mais forte e mais fraco
            if(weight > maxWeight)
            {
                maxWeight = weight;
                strongestFactor = m_factors[i].name;
            }
            
            if(weight < minWeight)
            {
                minWeight = weight;
                weakestFactor = m_factors[i].name;
            }
        }
        
        // Calcular score final
        if(totalWeight > 0)
        {
            double netScore = bullishScore - bearishScore;
            double maxPossibleScore = totalWeight;
            
            // Score de 0 a 100
            m_confluenceResult.confluenceScore = 50 + (netScore / maxPossibleScore) * 50;
            m_confluenceResult.confluenceScore = MathMax(0, MathMin(100, m_confluenceResult.confluenceScore));
        }
        
        m_confluenceResult.totalFactors = m_factorCount;
        m_confluenceResult.strongestFactor = strongestFactor;
        m_confluenceResult.weakestFactor = weakestFactor;
        m_confluenceResult.isValid = true;
        
        CCoreUtils::LogInfo("Confluência consolidada: " + 
                          IntegerToString(m_confluenceResult.bullishFactors) + " bull, " +
                          IntegerToString(m_confluenceResult.bearishFactors) + " bear, " +
                          IntegerToString(m_confluenceResult.neutralFactors) + " neutral");
    }
    
public:
    //+------------------------------------------------------------------+
    //| Obter informações de debug                                     |
    //+------------------------------------------------------------------+
    string GetDebugInfo()
    {
        if(!m_initialized)
        {
            return "ConfluenceAnalyzer não inicializado";
        }
        
        string info = "=== ANÁLISE DE CONFLUÊNCIA ===\n";
        
        if(m_confluenceResult.isValid)
        {
            info += "Score de confluência: " + DoubleToString(m_confluenceResult.confluenceScore, 1) + "%\n";
            info += "Fatores bullish: " + IntegerToString(m_confluenceResult.bullishFactors) + "\n";
            info += "Fatores bearish: " + IntegerToString(m_confluenceResult.bearishFactors) + "\n";
            info += "Fatores neutros: " + IntegerToString(m_confluenceResult.neutralFactors) + "\n";
            info += "Total de fatores: " + IntegerToString(m_confluenceResult.totalFactors) + "\n";
            info += "Fator mais forte: " + m_confluenceResult.strongestFactor + "\n";
            info += "Fator mais fraco: " + m_confluenceResult.weakestFactor + "\n\n";
            
            info += "DETALHES DOS FATORES:\n";
            for(int i = 0; i < m_factorCount; i++)
            {
                if(!m_factors[i].isValid) continue;
                
                string typeStr = "";
                switch(m_factors[i].type)
                {
                    case CONFLUENCE_BULLISH: typeStr = "BULL"; break;
                    case CONFLUENCE_BEARISH: typeStr = "BEAR"; break;
                    case CONFLUENCE_NEUTRAL: typeStr = "NEUT"; break;
                }
                
                info += IntegerToString(i + 1) + ". " + m_factors[i].name + " [" + typeStr + "] ";
                info += "Peso: " + DoubleToString(m_factors[i].weight, 1) + " - ";
                info += m_factors[i].description + "\n";
            }
        }
        else
        {
            info += "Resultado de confluência inválido\n";
        }
        
        info += "\nÚltima atualização: " + TimeToString(m_lastUpdate, TIME_DATE|TIME_SECONDS);
        
        return info;
    }
};

#endif // CONFLUENCE_ANALYZER_H

