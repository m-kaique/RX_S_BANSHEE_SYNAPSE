# Manual de Instalação e Configuração - TrendAnalyzer WINM25

**Versão:** 1.0  
**Data:** 21 de junho de 2025  
**Desenvolvido por:** Manus AI

---

## Guia Rápido de Instalação

### Passo 1: Verificação de Requisitos

Antes de instalar o TrendAnalyzer WINM25, certifique-se de que seu sistema atende aos seguintes requisitos:

**Software Necessário:**
- MetaTrader 5 build 3815 ou superior
- Sistema operacional Windows 10 ou superior
- Conexão estável com a internet
- Conta de trading com permissões para Expert Advisors

**Configurações da Conta:**
- Símbolo WINM25 disponível e ativo
- Trading automático habilitado
- Capital mínimo recomendado: R$ 5.000

### Passo 2: Download e Extração

1. Faça o download do arquivo TrendAnalyzerWINM25.zip
2. Extraia todo o conteúdo para uma pasta temporária
3. Verifique se todos os arquivos estão presentes:
   - TrendAnalyzerEA.mq5 (arquivo principal)
   - Pasta Core/ com todos os módulos
   - Pasta PriceAction/ com análises de price action
   - Pasta Indicators/ com indicadores técnicos
   - Pasta TimeframeAnalysis/ com análise multi-timeframe
   - Pasta SignalGeneration/ com geração de sinais
   - Pasta TradeExecution/ com execução de trades
   - Arquivos de configuração (.mqh)

### Passo 3: Instalação no MetaTrader 5

1. Abra o MetaTrader 5
2. Pressione F4 ou vá em "Ferramentas" → "Editor MetaQuotes"
3. No MetaEditor, clique em "Arquivo" → "Abrir Pasta de Dados"
4. Navegue até a pasta "MQL5" → "Experts"
5. Copie toda a pasta "TrendAnalyzerWINM25" para esta localização
6. Mantenha a estrutura de pastas exatamente como fornecida

### Passo 4: Compilação

1. No MetaEditor, navegue até a pasta TrendAnalyzerWINM25
2. Abra o arquivo TrendAnalyzerEA.mq5
3. Pressione F7 ou clique em "Compilar"
4. Verifique se não há erros na aba "Erros"
5. Se a compilação for bem-sucedida, você verá a mensagem "0 erro(s), 0 aviso(s)"

### Passo 5: Configuração Inicial

1. No MetaTrader 5, abra um gráfico do WINM25
2. No Navegador, expanda "Expert Advisors"
3. Localize "TrendAnalyzerWINM25" → "TrendAnalyzerEA"
4. Arraste o EA para o gráfico do WINM25
5. Na janela de configuração que abrir, ajuste os parâmetros conforme necessário

## Configurações Recomendadas por Perfil

### Perfil Conservador (Capital: R$ 5.000 - R$ 15.000)

```
=== CONFIGURAÇÕES GERAIS ===
EA_Symbol = "WINM25"
EA_Enabled = true
EA_AllowLong = true
EA_AllowShort = true
EA_MagicNumber = 20250621

=== GESTÃO DE RISCO ===
Risk_LotSize = 0.1
Risk_UseFixedLot = true
Risk_RiskPercent = 1.5
Risk_MaxLoss = 150.0
Risk_MaxProfit = 450.0
Risk_MaxTrades = 3

=== CONFIGURAÇÕES DE SINAL ===
Signal_MinStrength = 75.0
Signal_MinConfluence = 65.0
Signal_UpdateInterval = 300
Signal_OnlyLiquidityHours = true

=== STOP LOSS E TAKE PROFIT ===
SL_ATRMultiplier = 2.5
TP_RiskRewardRatio = 2.0
SL_UseTrailingStop = true
SL_TrailingDistance = 150.0
TP_UsePartialClose = true
TP_PartialPercent = 50.0
```

### Perfil Moderado (Capital: R$ 15.000 - R$ 50.000)

```
=== CONFIGURAÇÕES GERAIS ===
EA_Symbol = "WINM25"
EA_Enabled = true
EA_AllowLong = true
EA_AllowShort = true
EA_MagicNumber = 20250621

=== GESTÃO DE RISCO ===
Risk_LotSize = 0.2
Risk_UseFixedLot = false
Risk_RiskPercent = 2.0
Risk_MaxLoss = 400.0
Risk_MaxProfit = 1000.0
Risk_MaxTrades = 4

=== CONFIGURAÇÕES DE SINAL ===
Signal_MinStrength = 70.0
Signal_MinConfluence = 60.0
Signal_UpdateInterval = 300
Signal_OnlyLiquidityHours = true

=== STOP LOSS E TAKE PROFIT ===
SL_ATRMultiplier = 2.0
TP_RiskRewardRatio = 2.0
SL_UseTrailingStop = true
SL_TrailingDistance = 120.0
TP_UsePartialClose = true
TP_PartialPercent = 50.0
```

### Perfil Agressivo (Capital: R$ 50.000+)

```
=== CONFIGURAÇÕES GERAIS ===
EA_Symbol = "WINM25"
EA_Enabled = true
EA_AllowLong = true
EA_AllowShort = true
EA_MagicNumber = 20250621

=== GESTÃO DE RISCO ===
Risk_LotSize = 0.5
Risk_UseFixedLot = false
Risk_RiskPercent = 2.5
Risk_MaxLoss = 1000.0
Risk_MaxProfit = 2500.0
Risk_MaxTrades = 5

=== CONFIGURAÇÕES DE SINAL ===
Signal_MinStrength = 65.0
Signal_MinConfluence = 55.0
Signal_UpdateInterval = 300
Signal_OnlyLiquidityHours = true

=== STOP LOSS E TAKE PROFIT ===
SL_ATRMultiplier = 1.8
TP_RiskRewardRatio = 1.8
SL_UseTrailingStop = true
SL_TrailingDistance = 100.0
TP_UsePartialClose = true
TP_PartialPercent = 50.0
```

## Verificação de Instalação

### Teste Básico

1. Após anexar o EA ao gráfico, verifique a aba "Expert"
2. Você deve ver mensagens como:
   ```
   === INICIANDO TREND ANALYZER EA v1.0 ===
   EA inicializado com sucesso para WINM25
   Configurações: Lote=0.1, Risco=2.0%, Magic=20250621
   ```

3. Se houver erros, verifique:
   - Se todos os arquivos foram copiados corretamente
   - Se a compilação foi bem-sucedida
   - Se o trading automático está habilitado

### Teste Completo

1. Execute o script TrendAnalyzerTest.mq5:
   - No MetaEditor, abra TrendAnalyzerTest.mq5
   - Compile o script (F7)
   - No MetaTrader 5, vá em "Ferramentas" → "Scripts"
   - Execute TrendAnalyzerTest

2. Verifique o resultado nos logs:
   ```
   === RESULTADO FINAL DOS TESTES ===
   Total de módulos testados: 7
   Módulos aprovados: 7
   STATUS: TODOS OS TESTES PASSARAM COM SUCESSO! ✓
   ```

## Configurações Avançadas

### Horários de Operação

Para otimizar a performance, configure os horários conforme sua estratégia:

**Horário Padrão (Recomendado):**
```
Time_StartTrading = "09:00"
Time_StopTrading = "17:00"
Time_AvoidNews = true
Time_OnlyLiquidHours = true
```

**Horário Estendido:**
```
Time_StartTrading = "08:30"
Time_StopTrading = "17:30"
Time_AvoidNews = true
Time_OnlyLiquidHours = false
```

### Configurações de Debug

Para monitoramento detalhado:
```
Debug_Enabled = true
Debug_ShowPanel = true
Debug_LogSignals = true
Debug_LogTrades = true
```

Para operação em produção:
```
Debug_Enabled = false
Debug_ShowPanel = false
Debug_LogSignals = false
Debug_LogTrades = true
```

## Solução de Problemas Comuns

### Problema: EA não inicia

**Possíveis causas:**
- Trading automático desabilitado
- Arquivos não copiados corretamente
- Erro de compilação

**Soluções:**
1. Verifique se o botão "Trading Automático" está ativo
2. Recompile o EA no MetaEditor
3. Verifique se todos os arquivos estão na pasta correta

### Problema: Não gera sinais

**Possíveis causas:**
- Parâmetros muito restritivos
- Horário fora do configurado
- Dados insuficientes

**Soluções:**
1. Reduza temporariamente Signal_MinStrength para 60%
2. Verifique configurações de horário
3. Aguarde acúmulo de dados históricos (30 minutos)

### Problema: Execução com erro

**Possíveis causas:**
- Saldo insuficiente
- Lote muito grande
- Problemas de conectividade

**Soluções:**
1. Verifique saldo da conta
2. Reduza Risk_LotSize
3. Teste conectividade com o broker

## Suporte e Contato

Para questões técnicas ou problemas não cobertos neste manual:

1. Consulte primeiro a documentação técnica completa
2. Verifique os logs do sistema para mensagens de erro específicas
3. Execute o teste completo para identificar módulos com problemas

**Lembre-se:** Este EA gerencia capital real. Sempre teste em conta demo antes de usar em produção, e nunca arrisque mais do que pode perder.

---

*Manual de Instalação v1.0 - TrendAnalyzer WINM25*  
*Desenvolvido por Manus AI - 2025*

