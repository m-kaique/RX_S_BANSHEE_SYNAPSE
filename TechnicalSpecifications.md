# Especificações Técnicas Completas - Expert Advisor WINM25

## Visão Geral do Sistema

O Expert Advisor TrendAnalyzerWINM25 é um sistema completo de análise de tendência desenvolvido especificamente para o ativo WINM25 (Mini Ibovespa Futuro). O sistema implementa rigorosamente a metodologia descrita no "GUIA COMPLETO DE ANÁLISE DE TENDÊNCIA - WINM25", combinando análise de Price Action com indicadores técnicos para gerar sinais de compra e venda precisos.

### Objetivo Principal

Identificar contextos de mercado de tendência (ALTA e BAIXA) através de análise multi-timeframe, gerando sinais de trading baseados na confluência de múltiplos fatores técnicos. O sistema opera com foco em timeframes de 3 e 5 minutos para execução, mas utiliza análises de timeframes superiores para contexto.

### Princípio Fundamental

"O trade é sempre a favor da tendência. Perto das médias." - Este princípio orienta toda a lógica de geração de sinais do sistema.

## Arquitetura Modular

### Módulo Core
- **TrendAnalyzer.mqh**: Classe principal de análise de tendência
- **CoreUtils.mqh**: Utilitários e funções auxiliares
- **CoreTest.mq5**: Testes unitários do módulo core

### Módulo Price Action
- **TrendLines.mqh**: Implementação de Linhas de Tendência de Alta (LTA) e Baixa (LTB)
- **SupportResistance.mqh**: Identificação e validação de níveis de suporte e resistência
- **Channels.mqh**: Análise de canais ascendentes, descendentes e horizontais
- **AdvancedPatterns.mqh**: Padrões avançados (Spike and Channel, Trend from Open, Small Pullback Trend)
- **PriceActionUtils.mqh**: Utilitários para análise de price action

### Módulo Indicators
- **MovingAverages.mqh**: Médias móveis (EMA9, EMA21, EMA50, SMA200)
- **VWAP.mqh**: Volume Weighted Average Price com desvios padrão
- **BollingerBands.mqh**: Bandas de Bollinger com detecção de "Walking the Bands"
- **Fibonacci.mqh**: Níveis de Fibonacci com foco na zona de ouro (61.8%)
- **VolumeAnalyzer.mqh**: Análise de volume para confirmação de sinais

### Módulo Multi-Timeframe
- **MultiTimeframe.mqh**: Coordenação da análise entre timeframes
- **TimeframeSequencer.mqh**: Sequenciamento lógico da análise
- **TimeframeUtils.mqh**: Utilitários para manipulação de timeframes

### Módulo Signal Generation
- **SignalGenerator.mqh**: Geração de sinais baseada em confluência
- **ConfluenceAnalyzer.mqh**: Análise de confluência entre fatores
- **SignalValidator.mqh**: Validação e filtragem de sinais
- **TradingSignal.mqh**: Estrutura e manipulação de sinais de trading

## Especificações de Timeframes

### H4 (4 Horas) - Contexto Macro
- **Função**: Análise estrutural de longo prazo
- **Indicadores**: SMA200, estrutura de mercado, canais principais
- **Objetivo**: Definir viés direcional principal

### H1 (1 Hora) - Tendência Principal
- **Função**: Confirmação da tendência de médio prazo
- **Indicadores**: EMA50, LTA/LTB, Fibonacci
- **Objetivo**: Validar direção e identificar níveis de entrada

### M15 (15 Minutos) - Setup
- **Função**: Preparação para entrada
- **Indicadores**: EMA9, EMA21, VWAP, Bollinger Bands
- **Objetivo**: Refinar timing e confirmar setup

### M5/M3 (5/3 Minutos) - Execução
- **Função**: Timing preciso de entrada
- **Indicadores**: Price action imediato, volume
- **Objetivo**: Executar entrada no momento ideal

## Especificações de Indicadores

### Médias Móveis

#### EMA 9 (M15)
- **Tipo**: Exponencial
- **Função**: Tendência de curtíssimo prazo
- **Aplicação**: Timing de entrada/saída

#### EMA 21 (M15)
- **Tipo**: Exponencial
- **Função**: Suporte/resistência dinâmico
- **Estratégia**: "Estratégia da média de 21 para média de 9"

#### EMA 50 (H1)
- **Tipo**: Exponencial
- **Função**: Tendência de médio prazo
- **Aplicação**: Contexto principal de tendência

#### SMA 200 (H4)
- **Tipo**: Simples
- **Função**: Tendência de longo prazo
- **Aplicação**: Filtro direcional macro

### VWAP (M15/M5)
- **Configuração**: Padrão intradiário
- **Função**: Referência de viés intradiário
- **Desvios**: ±1, ±2, ±3 sigma
- **Reset**: Diário às 09:00

### Bandas de Bollinger (M15)
- **Período**: 20
- **Desvio**: 2.0
- **Preço**: Close
- **Função**: Volatilidade e "Walking the Bands"

### Fibonacci
- **Metodologia**: Mínima à máxima do dia anterior
- **Níveis**: 23.6%, 38.2%, 50%, 61.8%, 78.6%
- **Foco**: Zona de ouro (61.8%)
- **Aplicação**: "Pra cima desse ponto e comprar. Baixo e venda"

## Lógica de Geração de Sinais

### Sinal de Compra (Tendência de Alta)

#### Condições Obrigatórias:
1. **Alinhamento Multi-Timeframe**: H4, H1, M15, M5 em tendência de alta
2. **Proximidade às Médias**: Preço próximo à EMA21 (tolerância 15 pontos)
3. **Confirmação de Volume**: Volume crescente em movimentos de alta
4. **Horário de Liquidez**: Entre 10h-16h

#### Condições de Confluência:
1. **Price Action**: Preço respeitando LTA ou suporte válido
2. **Fibonacci**: Preço acima de 61.8% ou em zona de suporte
3. **VWAP**: Preço acima da VWAP
4. **Bollinger**: Walking the bands superior ou expansão

### Sinal de Venda (Tendência de Baixa)

#### Condições Obrigatórias:
1. **Alinhamento Multi-Timeframe**: H4, H1, M15, M5 em tendência de baixa
2. **Proximidade às Médias**: Preço próximo à EMA21 (tolerância 15 pontos)
3. **Confirmação de Volume**: Volume crescente em movimentos de baixa
4. **Horário de Liquidez**: Entre 10h-16h

#### Condições de Confluência:
1. **Price Action**: Preço rejeitando LTB ou resistência válida
2. **Fibonacci**: Preço abaixo de 61.8% ou em zona de resistência
3. **VWAP**: Preço abaixo da VWAP
4. **Bollinger**: Walking the bands inferior ou expansão

## Configurações de Risk Management

### Stop Loss
- **Padrão**: 100 pontos
- **Dinâmico**: Baseado em ATR ou níveis técnicos
- **Máximo**: 150 pontos

### Take Profit
- **Padrão**: 200 pontos (Risk/Reward 2:1)
- **Dinâmico**: Baseado em resistências/suportes
- **Múltiplos alvos**: 50%, 75%, 100%

### Gestão de Posição
- **Tamanho**: Baseado em % do capital
- **Máximo risco por trade**: 2%
- **Máximo trades simultâneos**: 1

## Tolerâncias e Parâmetros

### Tolerâncias (em pontos)
- **Linha de Tendência**: 10 pontos
- **Suporte/Resistência**: 20 pontos
- **Proximidade às Médias**: 15 pontos
- **Fibonacci**: 10 pontos

### Validação de Padrões
- **Mínimo toques LTA/LTB**: 3
- **Mínimo toques S/R**: 3
- **Máximo barras pullback**: 3
- **Máximo % pullback**: 25%

### Volume
- **Período média**: 20 barras
- **Ratio alto volume**: 1.5x média
- **Horário alta liquidez**: 10h-16h

## Especificações de Performance

### Frequência de Atualização
- **Principal**: 1000ms (1 segundo)
- **Cache**: 60 segundos de validade
- **Máximo barras**: 1000 para cálculos

### Otimizações
- **Cache de indicadores**: Evitar recálculos desnecessários
- **Análise incremental**: Apenas novas barras
- **Validação prévia**: Filtros rápidos antes de análise completa

## Estrutura de Dados

### TradingSignal
```mql5
struct TradingSignal
{
   datetime             time;           // Tempo do sinal
   ENUM_SIGNAL_TYPE     type;           // SIGNAL_BUY/SIGNAL_SELL
   ENUM_SIGNAL_STRENGTH strength;       // WEAK/MEDIUM/STRONG
   double               entryPrice;     // Preço de entrada
   double               stopLoss;       // Stop Loss
   double               takeProfit;     // Take Profit
   string               reason;         // Razão detalhada
   double               confidence;     // Confiança (0-100%)
   ENUM_TIMEFRAMES      timeframe;      // Timeframe principal
   bool                 isValid;        // Validade do sinal
};
```

### MultiTimeframeAnalysis
```mql5
struct MultiTimeframeAnalysis
{
   ENUM_TREND_DIRECTION trendH4;    // Tendência H4
   ENUM_TREND_DIRECTION trendH1;    // Tendência H1
   ENUM_TREND_DIRECTION trendM15;   // Tendência M15
   ENUM_TREND_DIRECTION trendM5;    // Tendência M5
   bool                 aligned;    // Alinhamento
   double               confidence; // Confiança
};
```

## Validação e Testes

### Testes Unitários
- **CoreTest.mq5**: Testes do módulo core
- **PriceActionTest.mq5**: Testes de price action
- **IndicatorsTest.mq5**: Testes de indicadores
- **SignalTest.mq5**: Testes de geração de sinais

### Validação de Dados
- **Verificação de símbolo**: Confirmar WINM25
- **Validação de timeframes**: Verificar disponibilidade
- **Consistência de dados**: Verificar integridade
- **Limites de erro**: Tolerância a falhas

### Performance
- **Tempo de execução**: < 100ms por análise
- **Uso de memória**: < 50MB
- **CPU**: < 10% em operação normal

## Logging e Debug

### Níveis de Log
- **INFO**: Informações gerais
- **WARNING**: Avisos não críticos
- **ERROR**: Erros críticos

### Debug Mode
- **Ativo**: Durante desenvolvimento
- **Detalhado**: Todos os cálculos
- **Performance**: Tempos de execução

Esta especificação técnica serve como base para a implementação completa do Expert Advisor, garantindo que todos os aspectos da metodologia de análise sejam corretamente implementados e testados.

