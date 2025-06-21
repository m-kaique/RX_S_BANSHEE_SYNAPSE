//+------------------------------------------------------------------+
//| CoreTest.mq5 - Testes do Módulo Core                            |
//| Desenvolvido por: Manus AI                                       |
//| Versão: 1.0                                                      |
//| Data: 2025-06-21                                                 |
//+------------------------------------------------------------------+

#property copyright "Manus AI"
#property version   "1.0"
#property script_show_inputs

#include "../TrendAnalyzerEnums.mqh"
#include "../TrendAnalyzerConfig.mqh"
#include "TrendAnalyzer.mqh"
#include "CoreUtils.mqh"

//+------------------------------------------------------------------+
//| Parâmetros de entrada                                           |
//+------------------------------------------------------------------+
input string TestSymbol = "WINM25";  // Símbolo para teste

//+------------------------------------------------------------------+
//| Função principal do script                                       |
//+------------------------------------------------------------------+
void OnStart()
{
    Print("=== INICIANDO TESTES DO MÓDULO CORE ===");
    
    bool allTestsPassed = true;
    
    // Teste 1: Inicialização do TrendAnalyzer
    allTestsPassed &= TestTrendAnalyzerInitialization();
    
    // Teste 2: Análise de tendência
    allTestsPassed &= TestTrendAnalysis();
    
    // Teste 3: Utilitários Core
    allTestsPassed &= TestCoreUtils();
    
    // Teste 4: Validação de dados
    allTestsPassed &= TestDataValidation();
    
    // Teste 5: Cálculos matemáticos
    allTestsPassed &= TestMathematicalCalculations();
    
    // Resultado final
    if(allTestsPassed)
    {
        Print("=== TODOS OS TESTES PASSARAM COM SUCESSO ===");
    }
    else
    {
        Print("=== ALGUNS TESTES FALHARAM ===");
    }
}

//+------------------------------------------------------------------+
//| Teste de inicialização do TrendAnalyzer                        |
//+------------------------------------------------------------------+
bool TestTrendAnalyzerInitialization()
{
    Print("--- Teste 1: Inicialização do TrendAnalyzer ---");
    
    CTrendAnalyzer* analyzer = new CTrendAnalyzer();
    
    // Teste com símbolo válido
    bool result1 = analyzer.Initialize(TestSymbol);
    if(!result1)
    {
        Print("FALHA: Não foi possível inicializar com símbolo válido");
        delete analyzer;
        return false;
    }
    
    // Verificar propriedades
    if(analyzer.GetSymbol() != TestSymbol)
    {
        Print("FALHA: Símbolo não foi definido corretamente");
        delete analyzer;
        return false;
    }
    
    if(analyzer.GetPointValue() <= 0)
    {
        Print("FALHA: Valor do ponto inválido");
        delete analyzer;
        return false;
    }
    
    if(!analyzer.IsInitialized())
    {
        Print("FALHA: Status de inicialização incorreto");
        delete analyzer;
        return false;
    }
    
    // Teste com símbolo inválido
    CTrendAnalyzer* analyzer2 = new CTrendAnalyzer();
    bool result2 = analyzer2.Initialize("");
    if(result2)
    {
        Print("FALHA: Inicialização deveria falhar com símbolo vazio");
        delete analyzer;
        delete analyzer2;
        return false;
    }
    
    delete analyzer;
    delete analyzer2;
    
    Print("SUCESSO: Inicialização do TrendAnalyzer");
    return true;
}

//+------------------------------------------------------------------+
//| Teste de análise de tendência                                  |
//+------------------------------------------------------------------+
bool TestTrendAnalysis()
{
    Print("--- Teste 2: Análise de Tendência ---");
    
    CTrendAnalyzer* analyzer = new CTrendAnalyzer();
    
    if(!analyzer.Initialize(TestSymbol))
    {
        Print("FALHA: Não foi possível inicializar analyzer");
        delete analyzer;
        return false;
    }
    
    // Testar análise em diferentes timeframes
    ENUM_TIMEFRAMES timeframes[] = {PERIOD_H4, PERIOD_H1, PERIOD_M15, PERIOD_M5};
    
    for(int i = 0; i < ArraySize(timeframes); i++)
    {
        ENUM_TREND_DIRECTION trend = analyzer.AnalyzeTrend(timeframes[i]);
        
        Print("Tendência ", EnumToString(timeframes[i]), ": ", CCoreUtils::TrendDirectionToString(trend));
        
        // Verificar se retornou um valor válido
        if(trend != TREND_UP && trend != TREND_DOWN && trend != TREND_NEUTRAL)
        {
            Print("FALHA: Tendência inválida retornada para ", EnumToString(timeframes[i]));
            delete analyzer;
            return false;
        }
        
        // Testar força da tendência
        double strength = analyzer.GetTrendStrength(timeframes[i]);
        if(strength < 0 || strength > 100)
        {
            Print("FALHA: Força da tendência fora do range (0-100): ", strength);
            delete analyzer;
            return false;
        }
        
        Print("Força da tendência ", EnumToString(timeframes[i]), ": ", DoubleToString(strength, 2), "%");
    }
    
    // Testar alinhamento de tendências
    bool aligned = analyzer.AreTrendsAligned();
    Print("Tendências alinhadas: ", (aligned ? "SIM" : "NÃO"));
    
    delete analyzer;
    
    Print("SUCESSO: Análise de Tendência");
    return true;
}

//+------------------------------------------------------------------+
//| Teste dos utilitários Core                                     |
//+------------------------------------------------------------------+
bool TestCoreUtils()
{
    Print("--- Teste 3: Utilitários Core ---");
    
    // Teste de conversão pontos/preço
    double points = 100;
    double price = CCoreUtils::PointsToPrice(points, TestSymbol);
    double backToPoints = CCoreUtils::PriceToPoints(price, TestSymbol);
    
    if(MathAbs(points - backToPoints) > 0.001)
    {
        Print("FALHA: Conversão pontos/preço inconsistente");
        return false;
    }
    
    // Teste de normalização de preço
    double testPrice = 123456.789123;
    double normalized = CCoreUtils::NormalizePrice(testPrice, TestSymbol);
    Print("Preço normalizado: ", DoubleToString(normalized, 5));
    
    // Teste de horário de liquidez
    datetime testTime = StringToTime("2025-06-21 14:30:00"); // 14:30 - alta liquidez
    bool isHighLiquidity = CCoreUtils::IsHighLiquidityTime(testTime);
    if(!isHighLiquidity)
    {
        Print("FALHA: 14:30 deveria ser horário de alta liquidez");
        return false;
    }
    
    testTime = StringToTime("2025-06-21 08:30:00"); // 08:30 - baixa liquidez
    isHighLiquidity = CCoreUtils::IsHighLiquidityTime(testTime);
    if(isHighLiquidity)
    {
        Print("FALHA: 08:30 não deveria ser horário de alta liquidez");
        return false;
    }
    
    // Teste de horário de mercado
    testTime = StringToTime("2025-06-21 15:00:00"); // 15:00 - mercado aberto
    bool isMarketHours = CCoreUtils::IsMarketHours(testTime);
    if(!isMarketHours)
    {
        Print("FALHA: 15:00 deveria ser horário de mercado");
        return false;
    }
    
    // Teste de cálculo de distância
    double price1 = 100000;
    double price2 = 100050;
    double distance = CCoreUtils::CalculateDistance(price1, price2, TestSymbol);
    Print("Distância entre preços: ", DoubleToString(distance, 2), " pontos");
    
    // Teste de tolerância
    bool withinTolerance = CCoreUtils::IsPriceWithinTolerance(price1, price2, 60, TestSymbol);
    if(!withinTolerance)
    {
        Print("FALHA: Preços deveriam estar dentro da tolerância");
        return false;
    }
    
    // Teste de inclinação
    datetime time1 = StringToTime("2025-06-21 10:00:00");
    datetime time2 = StringToTime("2025-06-21 11:00:00");
    double slope = CCoreUtils::CalculateSlope(time1, 100000, time2, 100100);
    Print("Inclinação calculada: ", DoubleToString(slope, 8));
    
    Print("SUCESSO: Utilitários Core");
    return true;
}

//+------------------------------------------------------------------+
//| Teste de validação de dados                                    |
//+------------------------------------------------------------------+
bool TestDataValidation()
{
    Print("--- Teste 4: Validação de Dados ---");
    
    // Criar array de teste válido
    double validArray[10];
    for(int i = 0; i < 10; i++)
    {
        validArray[i] = 100000 + i * 10;
    }
    
    if(!CCoreUtils::ValidateArrayData(validArray, 5))
    {
        Print("FALHA: Array válido foi rejeitado");
        return false;
    }
    
    // Criar array com valor inválido
    double invalidArray[5];
    invalidArray[0] = 100000;
    invalidArray[1] = 100010;
    invalidArray[2] = EMPTY_VALUE; // Valor inválido
    invalidArray[3] = 100030;
    invalidArray[4] = 100040;
    
    if(CCoreUtils::ValidateArrayData(invalidArray, 5))
    {
        Print("FALHA: Array inválido foi aceito");
        return false;
    }
    
    // Teste de array muito pequeno
    double smallArray[2];
    smallArray[0] = 100000;
    smallArray[1] = 100010;
    
    if(CCoreUtils::ValidateArrayData(smallArray, 5))
    {
        Print("FALHA: Array pequeno foi aceito para tamanho mínimo maior");
        return false;
    }
    
    Print("SUCESSO: Validação de Dados");
    return true;
}

//+------------------------------------------------------------------+
//| Teste de cálculos matemáticos                                  |
//+------------------------------------------------------------------+
bool TestMathematicalCalculations()
{
    Print("--- Teste 5: Cálculos Matemáticos ---");
    
    // Teste de mudança percentual
    double oldValue = 100000;
    double newValue = 102000;
    double percentChange = CCoreUtils::CalculatePercentChange(oldValue, newValue);
    
    if(MathAbs(percentChange - 2.0) > 0.001)
    {
        Print("FALHA: Cálculo de mudança percentual incorreto. Esperado: 2.0, Obtido: ", percentChange);
        return false;
    }
    
    // Teste de range
    double value = 50;
    bool inRange = CCoreUtils::IsValueInRange(value, 0, 100);
    if(!inRange)
    {
        Print("FALHA: Valor deveria estar no range");
        return false;
    }
    
    value = 150;
    inRange = CCoreUtils::IsValueInRange(value, 0, 100);
    if(inRange)
    {
        Print("FALHA: Valor não deveria estar no range");
        return false;
    }
    
    // Teste de ATR
    double high[];
    double low[];
    double close[];

    ArrayResize(high, 5);
    ArrayResize(low, 5);
    ArrayResize(close, 5);

    // Preencher dados (mais recente no índice 0)
    high[0] = 100220;
    high[1] = 100180;
    high[2] = 100200;
    high[3] = 100150;
    high[4] = 100100;

    low[0] = 100120;
    low[1] = 100080;
    low[2] = 100100;
    low[3] = 100050;
    low[4] = 100000;

    close[0] = 100180;
    close[1] = 100120;
    close[2] = 100150;
    close[3] = 100100;
    close[4] = 100050;

    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    double atr = CCoreUtils::CalculateATR(high, low, close, 5);
    if(atr <= 0)
    {
        Print("FALHA: ATR deveria ser positivo");
        return false;
    }
    
    Print("ATR calculado: ", DoubleToString(atr, 2));
    
    // Teste de correlação
    double array1[] = {1, 2, 3, 4, 5};
    double array2[] = {2, 4, 6, 8, 10};
    
    double correlation = CCoreUtils::CalculateCorrelation(array1, array2, 5);
    if(MathAbs(correlation - 1.0) > 0.001)
    {
        Print("FALHA: Correlação deveria ser próxima de 1.0. Obtido: ", correlation);
        return false;
    }
    
    Print("SUCESSO: Cálculos Matemáticos");
    return true;
}

