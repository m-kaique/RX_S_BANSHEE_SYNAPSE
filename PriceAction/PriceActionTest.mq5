//+------------------------------------------------------------------+
//| PriceActionTest.mq5 - Testes do Módulo Price Action             |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#property copyright "Manus AI"
#property version   "1.0"
#property script_show_inputs

#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "TrendLines.mqh"
#include "SupportResistance.mqh"
#include "Channels.mqh"
#include "AdvancedPatterns.mqh"
#include "PriceActionUtils.mqh"

//+------------------------------------------------------------------+
//| Parâmetros de entrada                                           |
//+------------------------------------------------------------------+
input string TestSymbol = "WINM25";  // Símbolo para teste

//+------------------------------------------------------------------+
//| Função principal do script                                       |
//+------------------------------------------------------------------+
void OnStart()
{
    Print("=== INICIANDO TESTES DO MÓDULO PRICE ACTION ===");
    
    bool allTestsPassed = true;
    
    // Teste 1: Linhas de Tendência
    allTestsPassed &= TestTrendLines();
    
    // Teste 2: Suporte e Resistência
    allTestsPassed &= TestSupportResistance();
    
    // Teste 3: Canais
    allTestsPassed &= TestChannels();
    
    // Teste 4: Padrões Avançados
    allTestsPassed &= TestAdvancedPatterns();
    
    // Teste 5: Utilitários Price Action
    allTestsPassed &= TestPriceActionUtils();
    
    // Resultado final
    if(allTestsPassed)
    {
        Print("=== TODOS OS TESTES DE PRICE ACTION PASSARAM COM SUCESSO ===");
    }
    else
    {
        Print("=== ALGUNS TESTES DE PRICE ACTION FALHARAM ===");
    }
}

//+------------------------------------------------------------------+
//| Teste de Linhas de Tendência                                   |
//+------------------------------------------------------------------+
bool TestTrendLines()
{
    Print("--- Teste 1: Linhas de Tendência ---");
    
    CTrendLines* trendLines = new CTrendLines();
    
    // Inicializar
    if(!trendLines.Initialize(TestSymbol))
    {
        Print("FALHA: Não foi possível inicializar TrendLines");
        delete trendLines;
        return false;
    }
    
    // Testar cálculo de LTA
    bool ltaResult = trendLines.CalculateLTA(TestSymbol, PERIOD_H1);
    Print("Cálculo LTA: ", (ltaResult ? "SUCESSO" : "FALHA"));
    
    if(ltaResult)
    {
        TrendLine lta = trendLines.GetLTA();
        Print("LTA - Toques: ", lta.touches, ", Inclinação: ", DoubleToString(lta.slope, 8));
        
        // Testar nível atual
        double currentLevel = trendLines.GetCurrentLTALevel(TimeCurrent());
        Print("Nível atual LTA: ", DoubleToString(currentLevel, 2));
        
        // Testar proximidade
        double currentPrice = SymbolInfoDouble(TestSymbol, SYMBOL_BID);
        bool nearLTA = trendLines.IsPriceNearLTA(currentPrice, TOLERANCE_TRENDLINE);
        Print("Preço próximo da LTA: ", (nearLTA ? "SIM" : "NÃO"));
    }
    
    // Testar cálculo de LTB
    bool ltbResult = trendLines.CalculateLTB(TestSymbol, PERIOD_H1);
    Print("Cálculo LTB: ", (ltbResult ? "SUCESSO" : "FALHA"));
    
    if(ltbResult)
    {
        TrendLine ltb = trendLines.GetLTB();
        Print("LTB - Toques: ", ltb.touches, ", Inclinação: ", DoubleToString(ltb.slope, 8));
    }
    
    delete trendLines;
    
    Print("SUCESSO: Teste de Linhas de Tendência");
    return true;
}

//+------------------------------------------------------------------+
//| Teste de Suporte e Resistência                                 |
//+------------------------------------------------------------------+
bool TestSupportResistance()
{
    Print("--- Teste 2: Suporte e Resistência ---");
    
    CSupportResistance* sr = new CSupportResistance();
    
    // Inicializar
    if(!sr.Initialize(TestSymbol))
    {
        Print("FALHA: Não foi possível inicializar SupportResistance");
        delete sr;
        return false;
    }
    
    // Identificar níveis
    sr.IdentifyLevels(TestSymbol, PERIOD_H1);
    
    int levelsCount = sr.GetLevelsCount();
    Print("Níveis S/R identificados: ", levelsCount);
    
    if(levelsCount > 0)
    {
        double currentPrice = SymbolInfoDouble(TestSymbol, SYMBOL_BID);
        
        // Testar suporte mais próximo
        double nearestSupport = sr.GetNearestSupport(currentPrice);
        Print("Suporte mais próximo: ", DoubleToString(nearestSupport, 2));
        
        // Testar resistência mais próxima
        double nearestResistance = sr.GetNearestResistance(currentPrice);
        Print("Resistência mais próxima: ", DoubleToString(nearestResistance, 2));
        
        // Testar proximidade
        bool nearSupport = sr.IsPriceNearSupport(currentPrice, TOLERANCE_SR_LEVEL);
        bool nearResistance = sr.IsPriceNearResistance(currentPrice, TOLERANCE_SR_LEVEL);
        
        Print("Próximo de suporte: ", (nearSupport ? "SIM" : "NÃO"));
        Print("Próximo de resistência: ", (nearResistance ? "SIM" : "NÃO"));
        
        // Testar confluência
        bool hasConfluence = sr.HasConfluence(currentPrice, TOLERANCE_SR_LEVEL);
        Print("Confluência de níveis: ", (hasConfluence ? "SIM" : "NÃO"));
    }
    
    delete sr;
    
    Print("SUCESSO: Teste de Suporte e Resistência");
    return true;
}

//+------------------------------------------------------------------+
//| Teste de Canais                                                |
//+------------------------------------------------------------------+
bool TestChannels()
{
    Print("--- Teste 3: Canais ---");
    
    // Primeiro criar TrendLines para usar como referência
    CTrendLines* trendLines = new CTrendLines();
    if(!trendLines.Initialize(TestSymbol))
    {
        Print("FALHA: Não foi possível inicializar TrendLines para Channels");
        delete trendLines;
        return false;
    }
    
    // Calcular linhas de tendência
    trendLines.CalculateLTA(TestSymbol, PERIOD_H1);
    trendLines.CalculateLTB(TestSymbol, PERIOD_H1);
    
    CChannels* channels = new CChannels();
    
    // Inicializar
    if(!channels.Initialize(TestSymbol, trendLines))
    {
        Print("FALHA: Não foi possível inicializar Channels");
        delete channels;
        delete trendLines;
        return false;
    }
    
    // Identificar canal
    bool channelFound = channels.IdentifyChannel(TestSymbol, PERIOD_H1);
    Print("Canal identificado: ", (channelFound ? "SIM" : "NÃO"));
    
    if(channelFound)
    {
        Channel currentChannel = channels.GetCurrentChannel();
        Print("Tipo de canal: ", EnumToString(currentChannel.type));
        Print("Largura do canal: ", DoubleToString(currentChannel.width, 2));
        
        double currentPrice = SymbolInfoDouble(TestSymbol, SYMBOL_BID);
        
        // Testar posição no canal
        ENUM_CHANNEL_POSITION position = channels.GetPricePosition(currentPrice);
        string positionStr = "";
        switch(position)
        {
            case CHANNEL_UPPER:  positionStr = "SUPERIOR"; break;
            case CHANNEL_MIDDLE: positionStr = "MEIO"; break;
            case CHANNEL_LOWER:  positionStr = "INFERIOR"; break;
        }
        Print("Posição no canal: ", positionStr);
        
        // Testar proximidade às linhas
        bool nearUpper = channels.IsPriceNearUpperLine(currentPrice, TOLERANCE_TRENDLINE);
        bool nearLower = channels.IsPriceNearLowerLine(currentPrice, TOLERANCE_TRENDLINE);
        
        Print("Próximo da linha superior: ", (nearUpper ? "SIM" : "NÃO"));
        Print("Próximo da linha inferior: ", (nearLower ? "SIM" : "NÃO"));
        
        // Testar se canal está sendo respeitado
        bool respected = channels.IsChannelBeingRespected();
        Print("Canal sendo respeitado: ", (respected ? "SIM" : "NÃO"));
    }
    
    delete channels;
    delete trendLines;
    
    Print("SUCESSO: Teste de Canais");
    return true;
}

//+------------------------------------------------------------------+
//| Teste de Padrões Avançados                                     |
//+------------------------------------------------------------------+
bool TestAdvancedPatterns()
{
    Print("--- Teste 4: Padrões Avançados ---");
    
    CAdvancedPatterns* patterns = new CAdvancedPatterns();
    
    // Inicializar
    if(!patterns.Initialize(TestSymbol))
    {
        Print("FALHA: Não foi possível inicializar AdvancedPatterns");
        delete patterns;
        return false;
    }
    
    // Testar Spike and Channel
    bool spikeAndChannel = patterns.DetectSpikeAndChannel(TestSymbol, PERIOD_H1);
    Print("Spike and Channel detectado: ", (spikeAndChannel ? "SIM" : "NÃO"));
    
    // Testar Trend from Open
    bool trendFromOpen = patterns.DetectTrendFromOpen(TestSymbol);
    Print("Trend from Open detectado: ", (trendFromOpen ? "SIM" : "NÃO"));
    
    // Testar Small Pullback Trend
    bool smallPullback = patterns.DetectSmallPullbackTrend(TestSymbol, PERIOD_M15);
    Print("Small Pullback Trend detectado: ", (smallPullback ? "SIM" : "NÃO"));
    
    // Testar status dos padrões
    Print("Spike and Channel ativo: ", (patterns.IsSpikeAndChannelActive() ? "SIM" : "NÃO"));
    Print("Trend from Open ativo: ", (patterns.IsTrendFromOpenActive() ? "SIM" : "NÃO"));
    Print("Small Pullback ativo: ", (patterns.IsSmallPullbackTrendActive() ? "SIM" : "NÃO"));
    
    // Testar força dos padrões
    double patternStrength = patterns.GetPatternStrength();
    Print("Força dos padrões: ", DoubleToString(patternStrength, 1), "%");
    
    delete patterns;
    
    Print("SUCESSO: Teste de Padrões Avançados");
    return true;
}

//+------------------------------------------------------------------+
//| Teste de Utilitários Price Action                              |
//+------------------------------------------------------------------+
bool TestPriceActionUtils()
{
    Print("--- Teste 5: Utilitários Price Action ---");
    
    // Dados de teste
    double testOpen = 100000;
    double testClose = 100050;
    double testHigh = 100080;
    double testLow = 99950;
    
    // Testar identificação de barras
    bool isBullish = CPriceActionUtils::IsBullishBar(testOpen, testClose);
    bool isBearish = CPriceActionUtils::IsBearishBar(testOpen, testClose);
    bool isDoji = CPriceActionUtils::IsDoji(testOpen, testClose, testHigh, testLow, TestSymbol);
    
    Print("Barra bullish: ", (isBullish ? "SIM" : "NÃO"));
    Print("Barra bearish: ", (isBearish ? "SIM" : "NÃO"));
    Print("Doji: ", (isDoji ? "SIM" : "NÃO"));
    
    // Testar cálculos de tamanhos
    double bodySize = CPriceActionUtils::GetBodySize(testOpen, testClose);
    double upperShadow = CPriceActionUtils::GetUpperShadow(testOpen, testClose, testHigh);
    double lowerShadow = CPriceActionUtils::GetLowerShadow(testOpen, testClose, testLow);
    
    Print("Tamanho do corpo: ", DoubleToString(bodySize, 2));
    Print("Sombra superior: ", DoubleToString(upperShadow, 2));
    Print("Sombra inferior: ", DoubleToString(lowerShadow, 2));
    
    // Testar padrões de candlestick
    bool isHammer = CPriceActionUtils::IsHammer(testOpen, testClose, testHigh, testLow);
    bool isShootingStar = CPriceActionUtils::IsShootingStar(testOpen, testClose, testHigh, testLow);
    
    Print("Hammer: ", (isHammer ? "SIM" : "NÃO"));
    Print("Shooting Star: ", (isShootingStar ? "SIM" : "NÃO"));
    
    // Testar força da barra
    double barStrength = CPriceActionUtils::GetBarStrength(testOpen, testClose, testHigh, testLow);
    Print("Força da barra: ", DoubleToString(barStrength, 1), "%");
    
    // Testar momentum
    double momentum = CPriceActionUtils::GetBarMomentum(testOpen, testClose, testHigh, testLow);
    Print("Momentum: ", DoubleToString(momentum, 3));
    
    // Testar pressões
    double buyingPressure = CPriceActionUtils::GetBuyingPressure(testOpen, testClose, testHigh, testLow);
    double sellingPressure = CPriceActionUtils::GetSellingPressure(testOpen, testClose, testHigh, testLow);
    
    Print("Pressão compradora: ", DoubleToString(buyingPressure, 3));
    Print("Pressão vendedora: ", DoubleToString(sellingPressure, 3));
    
    // Testar gaps
    double prevClose = 99980;
    double nextOpen = 100020;
    
    bool isGap = CPriceActionUtils::IsGap(prevClose, nextOpen);
    bool isGapUp = CPriceActionUtils::IsGapUp(prevClose, nextOpen);
    bool isGapDown = CPriceActionUtils::IsGapDown(prevClose, nextOpen);
    
    Print("Gap detectado: ", (isGap ? "SIM" : "NÃO"));
    Print("Gap de alta: ", (isGapUp ? "SIM" : "NÃO"));
    Print("Gap de baixa: ", (isGapDown ? "SIM" : "NÃO"));
    
    // Testar validação de dados
    double testOpen2[] = {100000, 100010, 100020};
    double testClose2[] = {100005, 100015, 100025};
    double testHigh2[] = {100010, 100020, 100030};
    double testLow2[] = {99995, 100005, 100015};
    
    bool validData = CPriceActionUtils::ValidateBarSequence(testOpen2, testClose2, testHigh2, testLow2, 3);
    if(!validData)
    {
        Print("FALHA: Validação de dados deveria passar");
        return false;
    }
    
    // Testar dados inválidos
    double testHighInvalid[] = {100000, 100010, 100020}; // High menor que close
    double testCloseInvalid[] = {100005, 100015, 100025};
    
    bool invalidData = CPriceActionUtils::ValidateBarSequence(testOpen2, testCloseInvalid, testHighInvalid, testLow2, 3);
    if(invalidData)
    {
        Print("FALHA: Validação deveria falhar com dados inválidos");
        return false;
    }
    
    Print("SUCESSO: Teste de Utilitários Price Action");
    return true;
}

