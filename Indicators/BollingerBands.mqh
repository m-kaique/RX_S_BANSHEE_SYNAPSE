//+------------------------------------------------------------------+
//| BollingerBands.mqh - Bandas de Bollinger                        |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#ifndef BOLLINGER_BANDS_H
#define BOLLINGER_BANDS_H

#include <Object.mqh>
#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "../Core/CoreUtils.mqh"

//+------------------------------------------------------------------+
//| Classe de Bandas de Bollinger                                   |
//+------------------------------------------------------------------+
class CBollingerBands : public CObject
{
private:
    string               m_symbol;           // Símbolo
    int                  m_handle;           // Handle do indicador
    
    // Arrays de dados
    double               m_upper[];          // Banda superior
    double               m_middle[];         // Linha central (MA20)
    double               m_lower[];          // Banda inferior
    
    // Valores atuais
    double               m_currentUpper;     // Banda superior atual
    double               m_currentMiddle;    // Linha central atual
    double               m_currentLower;     // Banda inferior atual
    
    datetime             m_lastUpdate;       // Última atualização
    bool                 m_initialized;      // Status de inicialização
    
    // Arrays auxiliares para análise
    double               m_high[];           // Máximas
    double               m_low[];            // Mínimas
    double               m_close[];          // Fechamentos
    datetime             m_time[];           // Tempos
    
public:
    //+------------------------------------------------------------------+
    //| Construtor                                                       |
    //+------------------------------------------------------------------+
    CBollingerBands()
    {
        m_symbol = "";
        m_handle = INVALID_HANDLE;
        
        m_currentUpper = 0;
        m_currentMiddle = 0;
        m_currentLower = 0;
        
        m_lastUpdate = 0;
        m_initialized = false;
        
        // Configurar arrays como séries
        ArraySetAsSeries(m_upper, true);
        ArraySetAsSeries(m_middle, true);
        ArraySetAsSeries(m_lower, true);
        ArraySetAsSeries(m_high, true);
        ArraySetAsSeries(m_low, true);
        ArraySetAsSeries(m_close, true);
        ArraySetAsSeries(m_time, true);
    }
    
    //+------------------------------------------------------------------+
    //| Destrutor                                                        |
    //+------------------------------------------------------------------+
    ~CBollingerBands()
    {
        if(m_handle != INVALID_HANDLE)
        {
            IndicatorRelease(m_handle);
        }
        
        ArrayFree(m_upper);
        ArrayFree(m_middle);
        ArrayFree(m_lower);
        ArrayFree(m_high);
        ArrayFree(m_low);
        ArrayFree(m_close);
        ArrayFree(m_time);
    }
    
    //+------------------------------------------------------------------+
    //| Inicializar Bandas de Bollinger                                |
    //+------------------------------------------------------------------+
    bool Initialize(string symbol)
    {
        if(symbol == "" || symbol == NULL)
        {
            CCoreUtils::LogError("Símbolo inválido para BollingerBands");
            return false;
        }
        
        m_symbol = symbol;
        
        // Criar handle do indicador conforme especificações do guia
        // Período 20, Desvio 2, M15
        m_handle = iBands(m_symbol, PERIOD_M15, BB_PERIOD, 0, BB_DEVIATION, BB_APPLIED_PRICE);
        
        if(m_handle == INVALID_HANDLE)
        {
            CCoreUtils::LogError("Falha ao criar handle das Bandas de Bollinger");
            return false;
        }
        
        // Aguardar cálculo inicial
        Sleep(100);
        
        // Marcar como inicializado antes da primeira atualização
        // permitindo que UpdateValues() acesse os dados do indicador
        m_initialized = true;

        // Fazer primeira atualização
        if(!UpdateValues())
        {
            m_initialized = false;
            CCoreUtils::LogError("Falha na atualização inicial das Bandas de Bollinger");
            return false;
        }
        CCoreUtils::LogInfo("BollingerBands inicializado com sucesso para " + symbol);
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Atualizar valores das bandas                                   |
    //+------------------------------------------------------------------+
    bool UpdateValues()
    {
        if(!m_initialized)
        {
            CCoreUtils::LogError("BollingerBands não inicializado");
            return false;
        }
        
        // Copiar dados das bandas
        if(CopyBuffer(m_handle, 0, 0, 10, m_upper) < 0)
        {
            CCoreUtils::LogError("Falha ao copiar banda superior");
            return false;
        }
        
        if(CopyBuffer(m_handle, 1, 0, 10, m_middle) < 0)
        {
            CCoreUtils::LogError("Falha ao copiar linha central");
            return false;
        }
        
        if(CopyBuffer(m_handle, 2, 0, 10, m_lower) < 0)
        {
            CCoreUtils::LogError("Falha ao copiar banda inferior");
            return false;
        }
        
        // Atualizar valores atuais
        m_currentUpper = m_upper[0];
        m_currentMiddle = m_middle[0];
        m_currentLower = m_lower[0];
        
        m_lastUpdate = TimeCurrent();
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Detectar "Walking the Bands"                                   |
    //+------------------------------------------------------------------+
    bool IsWalkingTheBands(string symbol, ENUM_BB_BAND band)
    {
        if(symbol != "") m_symbol = symbol;
        
        if(!m_initialized || !UpdateValues())
        {
            return false;
        }
        
        // Obter dados de preço para análise
        if(!GetPriceData())
        {
            return false;
        }
        
        // Analisar últimas 10 barras
        int barsToCheck = MathMin(10, ArraySize(m_high));
        if(barsToCheck < 7) return false; // Mínimo 7 barras conforme especificação
        
        int touchCount = 0;
        int closeNearBandCount = 0;
        
        for(int i = 0; i < barsToCheck; i++)
        {
            double bandLevel = 0;
            double testPrice = 0;
            double closePrice = m_close[i];
            
            if(band == BB_UPPER)
            {
                // Walking the upper band (tendência de alta)
                bandLevel = m_upper[i];
                testPrice = m_high[i];
                
                // Verificar se máxima tocou/ultrapassou banda superior
                if(testPrice >= bandLevel - CCoreUtils::PointsToPrice(5, m_symbol))
                {
                    touchCount++;
                }
                
                // Verificar se fechamento está próximo da banda
                if(closePrice >= bandLevel - CCoreUtils::PointsToPrice(10, m_symbol))
                {
                    closeNearBandCount++;
                }
            }
            else if(band == BB_LOWER)
            {
                // Walking the lower band (tendência de baixa)
                bandLevel = m_lower[i];
                testPrice = m_low[i];
                
                // Verificar se mínima tocou/ultrapassou banda inferior
                if(testPrice <= bandLevel + CCoreUtils::PointsToPrice(5, m_symbol))
                {
                    touchCount++;
                }
                
                // Verificar se fechamento está próximo da banda
                if(closePrice <= bandLevel + CCoreUtils::PointsToPrice(10, m_symbol))
                {
                    closeNearBandCount++;
                }
            }
        }
        
        // Walking the bands se 7+ barras tocaram a banda e 5+ fecharam próximo
        bool isWalking = (touchCount >= 7 && closeNearBandCount >= 5);
        
        if(isWalking)
        {
            string bandStr = (band == BB_UPPER) ? "SUPERIOR" : "INFERIOR";
            CCoreUtils::LogInfo("Walking the Bands detectado na banda " + bandStr + 
                              ". Toques: " + IntegerToString(touchCount) + 
                              ", Fechamentos próximos: " + IntegerToString(closeNearBandCount));
        }
        
        return isWalking;
    }
    
    //+------------------------------------------------------------------+
    //| Calcular largura das bandas                                    |
    //+------------------------------------------------------------------+
    double GetBandWidth()
    {
        if(!m_initialized || m_currentMiddle == 0)
        {
            return 0;
        }
        
        // Largura = (banda superior - banda inferior) / linha central * 100
        return ((m_currentUpper - m_currentLower) / m_currentMiddle) * 100.0;
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se bandas estão se expandindo                        |
    //+------------------------------------------------------------------+
    bool AreBandsExpanding()
    {
        if(!m_initialized || ArraySize(m_upper) < 3)
        {
            return false;
        }
        
        // Calcular largura atual e anterior
        double currentWidth = (m_upper[0] - m_lower[0]) / m_middle[0];
        double previousWidth = (m_upper[1] - m_lower[1]) / m_middle[1];
        double previousWidth2 = (m_upper[2] - m_lower[2]) / m_middle[2];
        
        // Expansão se largura está aumentando nas últimas 2 barras
        return (currentWidth > previousWidth && previousWidth > previousWidth2);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se bandas estão se contraindo                        |
    //+------------------------------------------------------------------+
    bool AreBandsContracting()
    {
        if(!m_initialized || ArraySize(m_upper) < 3)
        {
            return false;
        }
        
        // Calcular largura atual e anterior
        double currentWidth = (m_upper[0] - m_lower[0]) / m_middle[0];
        double previousWidth = (m_upper[1] - m_lower[1]) / m_middle[1];
        double previousWidth2 = (m_upper[2] - m_lower[2]) / m_middle[2];
        
        // Contração se largura está diminuindo nas últimas 2 barras
        return (currentWidth < previousWidth && previousWidth < previousWidth2);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está próximo da banda superior              |
    //+------------------------------------------------------------------+
    bool IsPriceNearUpperBand(double price, double tolerance)
    {
        if(!m_initialized || m_currentUpper == 0)
        {
            return false;
        }
        
        return CCoreUtils::IsPriceWithinTolerance(price, m_currentUpper, tolerance, m_symbol);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está próximo da banda inferior              |
    //+------------------------------------------------------------------+
    bool IsPriceNearLowerBand(double price, double tolerance)
    {
        if(!m_initialized || m_currentLower == 0)
        {
            return false;
        }
        
        return CCoreUtils::IsPriceWithinTolerance(price, m_currentLower, tolerance, m_symbol);
    }
    
    //+------------------------------------------------------------------+
    //| Verificar se preço está próximo da linha central               |
    //+------------------------------------------------------------------+
    bool IsPriceNearMiddleLine(double price, double tolerance)
    {
        if(!m_initialized || m_currentMiddle == 0)
        {
            return false;
        }
        
        return CCoreUtils::IsPriceWithinTolerance(price, m_currentMiddle, tolerance, m_symbol);
    }
    
    //+------------------------------------------------------------------+
    //| Obter posição relativa do preço nas bandas (0-100%)            |
    //+------------------------------------------------------------------+
    double GetPricePosition(double price)
    {
        if(!m_initialized || m_currentUpper == m_currentLower)
        {
            return 50; // Meio se não há dados válidos
        }
        
        // Posição relativa: 0% = banda inferior, 100% = banda superior
        double position = ((price - m_currentLower) / (m_currentUpper - m_currentLower)) * 100.0;
        
        return MathMax(0, MathMin(100, position));
    }
    
    //+------------------------------------------------------------------+
    //| Detectar squeeze (bandas muito estreitas)                      |
    //+------------------------------------------------------------------+
    bool IsSqueeze()
    {
        if(!m_initialized)
        {
            return false;
        }
        
        double currentWidth = GetBandWidth();
        
        // Squeeze se largura < 10% (valor típico para WINM25)
        return (currentWidth < 10.0);
    }
    
    //+------------------------------------------------------------------+
    //| Obter valor da banda superior                                  |
    //+------------------------------------------------------------------+
    double GetUpperBand() const { return m_currentUpper; }
    
    //+------------------------------------------------------------------+
    //| Obter valor da linha central                                   |
    //+------------------------------------------------------------------+
    double GetMiddleLine() const { return m_currentMiddle; }
    
    //+------------------------------------------------------------------+
    //| Obter valor da banda inferior                                  |
    //+------------------------------------------------------------------+
    double GetLowerBand() const { return m_currentLower; }
    
    //+------------------------------------------------------------------+
    //| Verificar se está inicializado                                 |
    //+------------------------------------------------------------------+
    bool IsInitialized() const { return m_initialized; }

private:
    //+------------------------------------------------------------------+
    //| Obter dados de preço                                           |
    //+------------------------------------------------------------------+
    bool GetPriceData()
    {
        int bars = 15; // Suficiente para análise
        
        if(ArrayResize(m_high, bars) < 0 || 
           ArrayResize(m_low, bars) < 0 ||
           ArrayResize(m_close, bars) < 0 ||
           ArrayResize(m_time, bars) < 0)
        {
            return false;
        }
        
        if(CopyHigh(m_symbol, PERIOD_M15, 0, bars, m_high) < 0 ||
           CopyLow(m_symbol, PERIOD_M15, 0, bars, m_low) < 0 ||
           CopyClose(m_symbol, PERIOD_M15, 0, bars, m_close) < 0 ||
           CopyTime(m_symbol, PERIOD_M15, 0, bars, m_time) < 0)
        {
            return false;
        }
        
        return true;
    }
    
public:
    //+------------------------------------------------------------------+
    //| Obter informações de debug                                     |
    //+------------------------------------------------------------------+
    string GetDebugInfo()
    {
        if(!m_initialized)
        {
            return "BollingerBands não inicializado";
        }
        
        string info = "=== BANDAS DE BOLLINGER ===\n";
        info += "Banda Superior: " + DoubleToString(m_currentUpper, 2) + "\n";
        info += "Linha Central (MA20): " + DoubleToString(m_currentMiddle, 2) + "\n";
        info += "Banda Inferior: " + DoubleToString(m_currentLower, 2) + "\n";
        info += "Largura das Bandas: " + DoubleToString(GetBandWidth(), 2) + "%\n";
        
        bool expanding = AreBandsExpanding();
        bool contracting = AreBandsContracting();
        bool squeeze = IsSqueeze();
        
        info += "Expansão: " + (expanding ? "SIM" : "NÃO") + "\n";
        info += "Contração: " + (contracting ? "SIM" : "NÃO") + "\n";
        info += "Squeeze: " + (squeeze ? "SIM" : "NÃO") + "\n";
        
        bool walkingUpper = IsWalkingTheBands(m_symbol, BB_UPPER);
        bool walkingLower = IsWalkingTheBands(m_symbol, BB_LOWER);
        
        info += "Walking Upper Band: " + (walkingUpper ? "SIM" : "NÃO") + "\n";
        info += "Walking Lower Band: " + (walkingLower ? "SIM" : "NÃO") + "\n";
        info += "Última atualização: " + TimeToString(m_lastUpdate, TIME_DATE|TIME_SECONDS);
        
        return info;
    }
};

#endif // BOLLINGER_BANDS_H

