//+------------------------------------------------------------------+
//| IndicatorsTest.mq5 - Testes do Módulo Indicators                |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#property copyright "Manus AI"
#property version   "1.0"
#property script_show_inputs

#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "MovingAverages.mqh"
#include "VWAP.mqh"
#include "BollingerBands.mqh"
#include "Fibonacci.mqh"
#include "VolumeAnalyzer.mqh"

//+------------------------------------------------------------------+
//| Parâmetros de entrada                                           |
//+------------------------------------------------------------------+
input string TestSymbol = "WINM25";  // Símbolo para teste

//+------------------------------------------------------------------+
//| Função principal do script                                       |
//+------------------------------------------------------------------+
void OnStart()
{
    Print("=== INICIANDO TESTES DO MÓDULO INDICATORS ===");
    
    bool allTestsPassed = true;
    
    // Teste 1: Médias Móveis
    allTestsPassed &= TestMovingAverages();
    
    // Teste 2: VWAP
    allTestsPassed &= TestVWAP();
    
    // Teste 3: Bandas de Bollinger
    allTestsPassed &= TestBollingerBands();
    
    // Teste 4: Fibonacci
    allTestsPassed &= TestFibonacci();
    
    // Teste 5: Análise de Volume
    allTestsPassed &= TestVolumeAnalyzer();
    
    // Resultado final
    if(allTestsPassed)
    {
        Print("=== TODOS OS TESTES DE INDICATORS PASSARAM COM SUCESSO ===");
    }
    else
    {
        Print("=== ALGUNS TESTES DE INDICATORS FALHARAM ===");
    }
}

//+------------------------------------------------------------------+
//| Teste de Médias Móveis                                         |
//+------------------------------------------------------------------+
bool TestMovingAverages()
{
    Print("--- Teste 1: Médias Móveis ---");
    
    CMovingAverages* ma = new CMovingAverages();
    
    // Inicializar
    if(!ma.Initialize(TestSymbol))
    {
        Print("FALHA: Não foi possível inicializar MovingAverages");
        delete ma;
        return false;
    }
    
    // Aguardar cálculo dos indicadores
    Sleep(1000);
    
    // Testar valores das médias
    double ema9 = ma.GetEMA9();
    double ema21 = ma.GetEMA21();
    double ema50 = ma.GetEMA50();
    double sma200 = ma.GetSMA200();
    
    Print("EMA9: ", DoubleToString(ema9, 2));
    Print("EMA21: ", DoubleToString(ema21, 2));
    Print("EMA50: ", DoubleToString(ema50, 2));
    Print("SMA200: ", DoubleToString(sma200, 2));
    
    if(ema9 <= 0 || ema21 <= 0 || ema50 <= 0 || sma200 <= 0)
    {
        Print("FALHA: Valores de médias inválidos");
        delete ma;
        return false;
    }
    
    // Testar alinhamento
    ENUM_MA_ALIGNMENT alignment = ma.GetAlignment();
    string alignmentStr = "";
    switch(alignment)
    {
        case MA_BULLISH: alignmentStr = "BULLISH"; break;
        case MA_BEARISH: alignmentStr = "BEARISH"; break;
        case MA_NEUTRAL: alignmentStr = "NEUTRAL"; break;
    }
    Print("Alinhamento das médias: ", alignmentStr);
    
    // Testar força do alinhamento
    double alignmentStrength = ma.GetAlignmentStrength();
    Print("Força do alinhamento: ", DoubleToString(alignmentStrength, 1), "%");
    
    // Testar proximidade
    double currentPrice = SymbolInfoDouble(TestSymbol, SYMBOL_BID);
    bool nearMA21 = ma.IsNearMA21(currentPrice, TOLERANCE_MA);
    bool nearMA50 = ma.IsNearMA50(currentPrice, TOLERANCE_MA);
    
    Print("Próximo da EMA21: ", (nearMA21 ? "SIM" : "NÃO"));
    Print("Próximo da EMA50: ", (nearMA50 ? "SIM" : "NÃO"));
    
    // Testar posição em relação à SMA200
    bool aboveSMA200 = ma.IsPriceAboveSMA200(currentPrice);
    bool belowSMA200 = ma.IsPriceBelowSMA200(currentPrice);
    
    Print("Acima da SMA200: ", (aboveSMA200 ? "SIM" : "NÃO"));
    Print("Abaixo da SMA200: ", (belowSMA200 ? "SIM" : "NÃO"));
    
    // Testar inclinação
    bool ema9Up = ma.IsMASloping(MA_PERIOD_9, true);
    bool ema21Up = ma.IsMASloping(MA_PERIOD_21, true);
    
    Print("EMA9 subindo: ", (ema9Up ? "SIM" : "NÃO"));
    Print("EMA21 subindo: ", (ema21Up ? "SIM" : "NÃO"));
    
    // Testar cruzamentos
    bool bullishCross = ma.IsMAsCrossing(MA_PERIOD_9, MA_PERIOD_21, true);
    bool bearishCross = ma.IsMAsCrossing(MA_PERIOD_9, MA_PERIOD_21, false);
    
    Print("Cruzamento bullish EMA9/21: ", (bullishCross ? "SIM" : "NÃO"));
    Print("Cruzamento bearish EMA9/21: ", (bearishCross ? "SIM" : "NÃO"));
    
    delete ma;
    
    Print("SUCESSO: Teste de Médias Móveis");
    return true;
}

//+------------------------------------------------------------------+
//| Teste de VWAP                                                   |
//+------------------------------------------------------------------+
bool TestVWAP()
{
    Print("--- Teste 2: VWAP ---");
    
    CVWAP* vwap = new CVWAP();
    
    // Inicializar
    if(!vwap.Initialize(TestSymbol))
    {
        Print("FALHA: Não foi possível inicializar VWAP");
        delete vwap;
        return false;
    }
    
    // Calcular VWAP
    vwap.Calculate(TestSymbol, PERIOD_M15);
    
    // Testar valores
    double vwapValue = vwap.GetVWAP();
    double upperBand1 = vwap.GetUpperBand1();
    double lowerBand1 = vwap.GetLowerBand1();
    double upperBand2 = vwap.GetUpperBand2();
    double lowerBand2 = vwap.GetLowerBand2();
    
    Print("VWAP: ", DoubleToString(vwapValue, 2));
    Print("Banda +1σ: ", DoubleToString(upperBand1, 2));
    Print("Banda -1σ: ", DoubleToString(lowerBand1, 2));
    Print("Banda +2σ: ", DoubleToString(upperBand2, 2));
    Print("Banda -2σ: ", DoubleToString(lowerBand2, 2));
    
    if(vwapValue <= 0)
    {
        Print("FALHA: Valor VWAP inválido");
        delete vwap;
        return false;
    }
    
    // Testar análise de preço
    double currentPrice = SymbolInfoDouble(TestSymbol, SYMBOL_BID);
    
    bool aboveVWAP = vwap.IsPriceAboveVWAP(currentPrice);
    bool belowVWAP = vwap.IsPriceBelowVWAP(currentPrice);
    bool nearVWAP = vwap.IsPriceNearVWAP(currentPrice, TOLERANCE_VWAP);
    
    Print("Acima do VWAP: ", (aboveVWAP ? "SIM" : "NÃO"));
    Print("Abaixo do VWAP: ", (belowVWAP ? "SIM" : "NÃO"));
    Print("Próximo do VWAP: ", (nearVWAP ? "SIM" : "NÃO"));
    
    // Testar nível de desvio
    int deviationLevel = vwap.GetPriceDeviationLevel(currentPrice);
    Print("Nível de desvio: ±", deviationLevel, "σ");
    
    bool atExtreme = vwap.IsPriceAtExtreme(currentPrice);
    Print("Em extremo (±2σ): ", (atExtreme ? "SIM" : "NÃO"));
    
    // Testar viés intradiário
    ENUM_TREND_DIRECTION bias = vwap.GetIntradayBias(currentPrice);
    string biasStr = "";
    switch(bias)
    {
        case TREND_UP: biasStr = "ALTA"; break;
        case TREND_DOWN: biasStr = "BAIXA"; break;
        case TREND_NEUTRAL: biasStr = "NEUTRO"; break;
    }
    Print("Viés intradiário: ", biasStr);
    
    delete vwap;
    
    Print("SUCESSO: Teste de VWAP");
    return true;
}

//+------------------------------------------------------------------+
//| Teste de Bandas de Bollinger                                   |
//+------------------------------------------------------------------+
bool TestBollingerBands()
{
    Print("--- Teste 3: Bandas de Bollinger ---");
    
    CBollingerBands* bb = new CBollingerBands();
    
    // Inicializar
    if(!bb.Initialize(TestSymbol))
    {
        Print("FALHA: Não foi possível inicializar BollingerBands");
        delete bb;
        return false;
    }
    
    // Aguardar cálculo
    Sleep(1000);
    
    // Testar valores
    double upperBand = bb.GetUpperBand();
    double middleLine = bb.GetMiddleLine();
    double lowerBand = bb.GetLowerBand();
    
    Print("Banda Superior: ", DoubleToString(upperBand, 2));
    Print("Linha Central: ", DoubleToString(middleLine, 2));
    Print("Banda Inferior: ", DoubleToString(lowerBand, 2));
    
    if(upperBand <= 0 || middleLine <= 0 || lowerBand <= 0)
    {
        Print("FALHA: Valores das bandas inválidos");
        delete bb;
        return false;
    }
    
    // Testar largura das bandas
    double bandWidth = bb.GetBandWidth();
    Print("Largura das bandas: ", DoubleToString(bandWidth, 2), "%");
    
    // Testar expansão/contração
    bool expanding = bb.AreBandsExpanding();
    bool contracting = bb.AreBandsContracting();
    bool squeeze = bb.IsSqueeze();
    
    Print("Bandas expandindo: ", (expanding ? "SIM" : "NÃO"));
    Print("Bandas contraindo: ", (contracting ? "SIM" : "NÃO"));
    Print("Squeeze: ", (squeeze ? "SIM" : "NÃO"));
    
    // Testar proximidade
    double currentPrice = SymbolInfoDouble(TestSymbol, SYMBOL_BID);
    
    bool nearUpper = bb.IsPriceNearUpperBand(currentPrice, TOLERANCE_BB);
    bool nearLower = bb.IsPriceNearLowerBand(currentPrice, TOLERANCE_BB);
    bool nearMiddle = bb.IsPriceNearMiddleLine(currentPrice, TOLERANCE_BB);
    
    Print("Próximo da banda superior: ", (nearUpper ? "SIM" : "NÃO"));
    Print("Próximo da banda inferior: ", (nearLower ? "SIM" : "NÃO"));
    Print("Próximo da linha central: ", (nearMiddle ? "SIM" : "NÃO"));
    
    // Testar posição relativa
    double position = bb.GetPricePosition(currentPrice);
    Print("Posição nas bandas: ", DoubleToString(position, 1), "%");
    
    // Testar Walking the Bands
    bool walkingUpper = bb.IsWalkingTheBands(TestSymbol, BB_UPPER);
    bool walkingLower = bb.IsWalkingTheBands(TestSymbol, BB_LOWER);
    
    Print("Walking upper band: ", (walkingUpper ? "SIM" : "NÃO"));
    Print("Walking lower band: ", (walkingLower ? "SIM" : "NÃO"));
    
    delete bb;
    
    Print("SUCESSO: Teste de Bandas de Bollinger");
    return true;
}

//+------------------------------------------------------------------+
//| Teste de Fibonacci                                             |
//+------------------------------------------------------------------+
bool TestFibonacci()
{
    Print("--- Teste 4: Fibonacci ---");
    
    CFibonacci* fib = new CFibonacci();
    
    // Inicializar
    if(!fib.Initialize(TestSymbol))
    {
        Print("FALHA: Não foi possível inicializar Fibonacci");
        delete fib;
        return false;
    }
    
    // Calcular níveis de retração
    bool retracementCalculated = fib.CalculateLevels(TestSymbol, PERIOD_H1, true);
    Print("Níveis de retração calculados: ", (retracementCalculated ? "SIM" : "NÃO"));
    
    if(retracementCalculated)
    {
        FibonacciLevels levels = fib.GetCurrentLevels();
        
        Print("Swing High: ", DoubleToString(levels.swingHigh, 2));
        Print("Swing Low: ", DoubleToString(levels.swingLow, 2));
        Print("0%: ", DoubleToString(levels.level0, 2));
        Print("23.6%: ", DoubleToString(levels.level236, 2));
        Print("38.2%: ", DoubleToString(levels.level382, 2));
        Print("50%: ", DoubleToString(levels.level500, 2));
        Print("61.8%: ", DoubleToString(levels.level618, 2));
        Print("78.6%: ", DoubleToString(levels.level786, 2));
        Print("100%: ", DoubleToString(levels.level1000, 2));
        
        // Testar proximidade
        double currentPrice = SymbolInfoDouble(TestSymbol, SYMBOL_BID);
        double nearestLevel = 0;
        
        bool nearFib = fib.IsPriceNearFibLevel(currentPrice, TOLERANCE_FIBONACCI, nearestLevel);
        Print("Próximo de nível Fibonacci: ", (nearFib ? "SIM" : "NÃO"));
        
        if(nearFib)
        {
            Print("Nível mais próximo: ", DoubleToString(nearestLevel, 2));
            double levelStrength = fib.GetLevelStrength(nearestLevel);
            Print("Força do nível: ", DoubleToString(levelStrength, 1), "%");
        }
        
        // Testar confluência
        bool confluence = fib.IsInConfluenceZone(currentPrice, TOLERANCE_FIBONACCI);
        Print("Em zona de confluência: ", (confluence ? "SIM" : "NÃO"));
        
        // Testar níveis específicos
        double fib618 = fib.GetFibLevel(61.8);
        double fib382 = fib.GetFibLevel(38.2);
        
        Print("Nível 61.8%: ", DoubleToString(fib618, 2));
        Print("Nível 38.2%: ", DoubleToString(fib382, 2));
    }
    
    // Calcular níveis de extensão
    bool extensionCalculated = fib.CalculateLevels(TestSymbol, PERIOD_H1, false);
    Print("Níveis de extensão calculados: ", (extensionCalculated ? "SIM" : "NÃO"));
    
    delete fib;
    
    Print("SUCESSO: Teste de Fibonacci");
    return true;
}

//+------------------------------------------------------------------+
//| Teste de Análise de Volume                                     |
//+------------------------------------------------------------------+
bool TestVolumeAnalyzer()
{
    Print("--- Teste 5: Análise de Volume ---");
    
    CVolumeAnalyzer* vol = new CVolumeAnalyzer();
    
    // Inicializar
    if(!vol.Initialize(TestSymbol))
    {
        Print("FALHA: Não foi possível inicializar VolumeAnalyzer");
        delete vol;
        return false;
    }
    
    // Analisar volume
    bool analyzed = vol.AnalyzeVolume(TestSymbol, PERIOD_M15);
    Print("Análise de volume realizada: ", (analyzed ? "SIM" : "NÃO"));
    
    if(analyzed)
    {
        double currentVolume = vol.GetCurrentVolume();
        double avgVolume = vol.GetAverageVolume();
        double volumeRatio = vol.GetVolumeRatio();
        
        Print("Volume atual: ", DoubleToString(currentVolume, 0));
        Print("Volume médio: ", DoubleToString(avgVolume, 0));
        Print("Razão volume: ", DoubleToString(volumeRatio, 2), "x");
        
        // Testar condições de volume
        bool highVolume = vol.IsHighVolume();
        bool lowVolume = vol.IsLowVolume();
        bool climax = vol.IsVolumeClimax();
        
        Print("Volume alto: ", (highVolume ? "SIM" : "NÃO"));
        Print("Volume baixo: ", (lowVolume ? "SIM" : "NÃO"));
        Print("Climax de volume: ", (climax ? "SIM" : "NÃO"));
        
        // Testar divergências
        bool bullishDiv = vol.IsVolumeDivergence(true);
        bool bearishDiv = vol.IsVolumeDivergence(false);
        
        Print("Divergência bullish: ", (bullishDiv ? "SIM" : "NÃO"));
        Print("Divergência bearish: ", (bearishDiv ? "SIM" : "NÃO"));
        
        // Testar OBV
        double obv = vol.CalculateOBV(20);
        Print("OBV (20 períodos): ", DoubleToString(obv, 0));
        
        // Testar confirmação
        bool confirmingUp = vol.IsVolumeConfirming(true);
        bool confirmingDown = vol.IsVolumeConfirming(false);
        
        Print("Volume confirma alta: ", (confirmingUp ? "SIM" : "NÃO"));
        Print("Volume confirma baixa: ", (confirmingDown ? "SIM" : "NÃO"));
        
        // Testar Volume Profile
        double pocLevel = 0, highVolLevel = 0, lowVolLevel = 0;
        bool profileAnalyzed = vol.AnalyzeVolumeByPrice(pocLevel, highVolLevel, lowVolLevel);
        
        Print("Volume Profile analisado: ", (profileAnalyzed ? "SIM" : "NÃO"));
        if(profileAnalyzed)
        {
            Print("POC (Point of Control): ", DoubleToString(pocLevel, 2));
            Print("Nível alto volume: ", DoubleToString(highVolLevel, 2));
            Print("Nível baixo volume: ", DoubleToString(lowVolLevel, 2));
        }
    }
    
    delete vol;
    
    Print("SUCESSO: Teste de Análise de Volume");
    return true;
}

