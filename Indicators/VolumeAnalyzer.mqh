//+------------------------------------------------------------------+
//| VolumeAnalyzer.mqh - Análise de Volume                          |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef VOLUME_ANALYZER_H
#define VOLUME_ANALYZER_H

#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "../Core/CoreUtils.mqh"

//+------------------------------------------------------------------+
//| Classe de Análise de Volume                                     |
//+------------------------------------------------------------------+
class CVolumeAnalyzer : public CObject
{
private:
    string               m_symbol;           // Símbolo
    
    // Arrays de dados
    double               m_high[];           // Máximas
    double               m_low[];            // Mínimas
    double               m_close[];          // Fechamentos
    double               m_open[];           // Aberturas
    datetime             m_time[];           // Tempos
    long                 m_volume[];         // Volume
    
    // Análise de volume
    double               m_avgVolume;        // Volume médio
    double               m_currentVolume;    // Volume atual
    double               m_volumeRatio;      // Razão volume atual/médio
    
    datetime             m_lastUpdate;       // Última atualização
    bool                 m_initialized;      // Status de inicialização
    
public:
    //+------------------------------------------------------------------+
    //| Construtor                                                       |
    //+------------------------------------------------------------------+
    CVolumeAnalyzer()
    {
        m_symbol = "";
        m_avgVolume = 0;
        m_currentVolume = 0;
        m_volumeRatio = 0;
        m_lastUpdate = 0;
        m_initialized = false;
        
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
    ~CVolumeAnalyzer()
    {
        ArrayFree(m_high);
        ArrayFree(m_low);
        ArrayFree(m_close);
        ArrayFree(m_open);
        ArrayFree(m_time);
        ArrayFree(m_volume);
    }
    
    //+------------------------------------------------------------------+
    //| Inicializar analisador de volume                               |
    //+------------------------------------------------------------------+
    bool Initialize(string symbol)
    {
        if(symbol == "" || symbol == NULL)
        {
            CCoreUtils::LogError("Símbolo inválido para VolumeAnalyzer");
            return false;
        }
        
        m_symbol = symbol;
        m_initialized = true;
        
        CCoreUtils::LogInfo("VolumeAnalyzer inicializado com sucesso para " + symbol);
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Analisar volume                                                |
    //+------------------------------------------------------------------+
    bool AnalyzeVolume(string symbol, ENUM_TIMEFRAMES tf)
    {
        if(symbol != "") m_symbol = symbol;
        
        if(!m_initialized)
        {
            CCoreUtils::LogError("VolumeAnalyzer não inicializado");
            return false;
        }
        
        // Obter dados históricos
        if(!GetHistoricalData(tf, VOLUME_ANALYSIS_PERIOD))
        {
            CCoreUtils::LogError("Falha ao obter dados para análise de volume");
            return false;
        }
        
        // Calcular volume médio
        CalculateAverageVolume();
        
        // Analisar volume atual
        m_currentVolume = (double)m_volume[0];
        m_volumeRatio = (m_avgVolume > 0) ? (m_currentVolume / m_avgVolume) : 1.0;
        
        m_lastUpdate = TimeCurrent();
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se há volume alto                                    |
    //+------------------------------------------------------------------+
    bool IsHighVolume()
    {
        if(!m_initialized)
        {
            return false;
        }
        
        // Volume alto se > 1.5x a média
        return (m_volumeRatio > HIGH_VOLUME_THRESHOLD);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se há volume baixo                                   |
    //+------------------------------------------------------------------+
    bool IsLowVolume()
    {
        if(!m_initialized)
        {
            return false;
        }
        
        // Volume baixo se < 0.7x a média
        return (m_volumeRatio < LOW_VOLUME_THRESHOLD);
    }
    
    //+------------------------------------------------------------------+
    //| Detectar climax de volume                                      |
    //+------------------------------------------------------------------+
    bool IsVolumeClimax()
    {
        if(!m_initialized || ArraySize(m_volume) < 5)
        {
            return false;
        }
        
        // Climax se volume atual é muito maior que os anteriores
        double currentVol = (double)m_volume[0];
        double avgRecentVol = 0;
        
        // Calcular média das últimas 4 barras
        for(int i = 1; i <= 4; i++)
        {
            avgRecentVol += (double)m_volume[i];
        }
        avgRecentVol /= 4.0;
        
        // Climax se volume atual > 3x a média recente
        return (avgRecentVol > 0 && currentVol > avgRecentVol * VOLUME_CLIMAX_MULTIPLIER);
    }
    
    //+------------------------------------------------------------------+
    //| Analisar volume por preço (Volume Profile simplificado)        |
    //+------------------------------------------------------------------+
    bool AnalyzeVolumeByPrice(double &pocLevel, double &highVolumeLevel, double &lowVolumeLevel)
    {
        if(!m_initialized || ArraySize(m_volume) < 20)
        {
            return false;
        }
        
        // Criar bins de preço para análise
        int binsCount = 20;
        double minPrice = m_low[ArrayMinimum(m_low, 0, 20)];
        double maxPrice = m_high[ArrayMaximum(m_high, 0, 20)];
        double priceRange = maxPrice - minPrice;
        
        if(priceRange <= 0) return false;
        
        double binSize = priceRange / binsCount;
        double volumeBins[];
        ArrayResize(volumeBins, binsCount);
        ArrayInitialize(volumeBins, 0);
        
        // Distribuir volume por bins de preço
        for(int i = 0; i < MathMin(20, ArraySize(m_volume)); i++)
        {
            double typicalPrice = (m_high[i] + m_low[i] + m_close[i]) / 3.0;
            int binIndex = (int)((typicalPrice - minPrice) / binSize);
            binIndex = MathMax(0, MathMin(binsCount - 1, binIndex));
            
            volumeBins[binIndex] += (double)m_volume[i];
        }
        
        // Encontrar POC (Point of Control) - nível com maior volume
        int pocIndex = ArrayMaximum(volumeBins);
        pocLevel = minPrice + (pocIndex * binSize) + (binSize / 2);
        
        // Encontrar níveis de alto e baixo volume
        int highVolIndex = pocIndex;
        int lowVolIndex = ArrayMinimum(volumeBins);
        
        highVolumeLevel = pocLevel; // Simplificado - usar POC como high volume
        lowVolumeLevel = minPrice + (lowVolIndex * binSize) + (binSize / 2);
        
        ArrayFree(volumeBins);
        
        CCoreUtils::LogInfo("Volume Profile - POC: " + DoubleToString(pocLevel, 2) + 
                          ", Low Vol: " + DoubleToString(lowVolumeLevel, 2));
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar divergência de volume                                |
    //+------------------------------------------------------------------+
    bool IsVolumeDivergence(bool lookingForBullish)
    {
        if(!m_initialized || ArraySize(m_volume) < 10)
        {
            return false;
        }
        
        // Analisar últimas 10 barras
        int barsToCheck = 10;
        
        // Encontrar extremos de preço
        int highIndex = ArrayMaximum(m_high, 0, barsToCheck);
        int lowIndex = ArrayMinimum(m_low, 0, barsToCheck);
        
        if(highIndex == -1 || lowIndex == -1) return false;
        
        if(lookingForBullish)
        {
            // Divergência bullish: preço faz mínima mais baixa, volume diminui
            if(lowIndex < 5) // Mínima recente
            {
                // Comparar volume na mínima atual vs mínima anterior
                double currentLowVolume = (double)m_volume[lowIndex];
                
                // Procurar mínima anterior
                for(int i = lowIndex + 3; i < barsToCheck; i++)
                {
                    if(m_low[i] <= m_low[lowIndex] * 1.001) // Mínima similar ou mais alta
                    {
                        double previousLowVolume = (double)m_volume[i];
                        
                        // Divergência se volume atual < volume anterior
                        if(currentLowVolume < previousLowVolume * 0.8)
                        {
                            return true;
                        }
                        break;
                    }
                }
            }
        }
        else
        {
            // Divergência bearish: preço faz máxima mais alta, volume diminui
            if(highIndex < 5) // Máxima recente
            {
                double currentHighVolume = (double)m_volume[highIndex];
                
                // Procurar máxima anterior
                for(int i = highIndex + 3; i < barsToCheck; i++)
                {
                    if(m_high[i] >= m_high[highIndex] * 0.999) // Máxima similar ou mais baixa
                    {
                        double previousHighVolume = (double)m_volume[i];
                        
                        // Divergência se volume atual < volume anterior
                        if(currentHighVolume < previousHighVolume * 0.8)
                        {
                            return true;
                        }
                        break;
                    }
                }
            }
        }
        
        return false;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular On Balance Volume (OBV)                               |
    //+------------------------------------------------------------------+
    double CalculateOBV(int period)
    {
        if(!m_initialized || ArraySize(m_volume) < period)
        {
            return 0;
        }
        
        double obv = 0;
        
        for(int i = period - 1; i >= 1; i--)
        {
            if(m_close[i-1] > m_close[i])
            {
                obv += (double)m_volume[i-1]; // Preço subiu, adicionar volume
            }
            else if(m_close[i-1] < m_close[i])
            {
                obv -= (double)m_volume[i-1]; // Preço desceu, subtrair volume
            }
            // Se preço igual, volume não afeta OBV
        }
        
        return obv;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar confirmação de volume                                |
    //+------------------------------------------------------------------+
    bool IsVolumeConfirming(bool priceMovingUp)
    {
        if(!m_initialized || ArraySize(m_volume) < 3)
        {
            return false;
        }
        
        // Volume confirma se está acima da média quando preço se move
        bool volumeHigh = IsHighVolume();
        
        if(priceMovingUp)
        {
            // Em alta, volume alto confirma
            return volumeHigh;
        }
        else
        {
            // Em baixa, volume alto também confirma
            return volumeHigh;
        }
    }
    
    //+------------------------------------------------------------------+
    //| Obter razão de volume atual                                    |
    //+------------------------------------------------------------------+
    double GetVolumeRatio() const { return m_volumeRatio; }
    
    //+------------------------------------------------------------------+
    //| Obter volume médio                                             |
    //+------------------------------------------------------------------+
    double GetAverageVolume() const { return m_avgVolume; }
    
    //+------------------------------------------------------------------+
    //| Obter volume atual                                             |
    //+------------------------------------------------------------------+
    double GetCurrentVolume() const { return m_currentVolume; }
    
    //+------------------------------------------------------------------+
    //| Verificar se está inicializado                                 |
    //+------------------------------------------------------------------+
    bool IsInitialized() const { return m_initialized; }

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
    //| Calcular volume médio                                          |
    //+------------------------------------------------------------------+
    void CalculateAverageVolume()
    {
        int dataSize = ArraySize(m_volume);
        if(dataSize < 2)
        {
            m_avgVolume = 1; // Valor padrão para evitar divisão por zero
            return;
        }
        
        // Calcular média das últimas 20 barras (excluindo a atual)
        int period = MathMin(20, dataSize - 1);
        long totalVolume = 0;
        
        for(int i = 1; i <= period; i++)
        {
            totalVolume += m_volume[i];
        }
        
        m_avgVolume = (double)totalVolume / period;
        
        if(m_avgVolume <= 0) m_avgVolume = 1; // Evitar divisão por zero
    }
    
public:
    //+------------------------------------------------------------------+
    //| Obter informações de debug                                     |
    //+------------------------------------------------------------------+
    string GetDebugInfo()
    {
        if(!m_initialized)
        {
            return "VolumeAnalyzer não inicializado";
        }
        
        string info = "=== ANÁLISE DE VOLUME ===\n";
        info += "Volume atual: " + DoubleToString(m_currentVolume, 0) + "\n";
        info += "Volume médio: " + DoubleToString(m_avgVolume, 0) + "\n";
        info += "Razão volume: " + DoubleToString(m_volumeRatio, 2) + "x\n";
        
        bool highVol = IsHighVolume();
        bool lowVol = IsLowVolume();
        bool climax = IsVolumeClimax();
        
        info += "Volume alto: " + (highVol ? "SIM" : "NÃO") + "\n";
        info += "Volume baixo: " + (lowVol ? "SIM" : "NÃO") + "\n";
        info += "Climax de volume: " + (climax ? "SIM" : "NÃO") + "\n";
        
        bool bullishDiv = IsVolumeDivergence(true);
        bool bearishDiv = IsVolumeDivergence(false);
        
        info += "Divergência bullish: " + (bullishDiv ? "SIM" : "NÃO") + "\n";
        info += "Divergência bearish: " + (bearishDiv ? "SIM" : "NÃO") + "\n";
        
        double obv = CalculateOBV(20);
        info += "OBV (20): " + DoubleToString(obv, 0) + "\n";
        
        info += "Última atualização: " + TimeToString(m_lastUpdate, TIME_DATE|TIME_SECONDS);
        
        return info;
    }
};

#endif // VOLUME_ANALYZER_H

