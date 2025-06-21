# TrendAnalyzer WINM25

![Versao](https://img.shields.io/badge/version-1.0-green)
![Plataforma](https://img.shields.io/badge/MQL5-blue)

**Expert Advisor para Análise de Tendência do Mini Índice Bovespa**

Projeto desenvolvido por Manus AI.

---

## Sumário

- [Visão Geral](#visão-geral)
- [Instalação](#instalação)
- [Uso](#uso)
- [Contribuição](#contribuição)
- [Documentação](#documentação)
- [Licença](#licença)

## Visão Geral

TrendAnalyzer WINM25 é um Expert Advisor (EA) completo para negociação automática do mini índice Bovespa. O sistema aplica uma metodologia de análise de tendência baseada em múltiplos timeframes e confluência de fatores técnicos.

Principais diferenciais:

- **Análise Multi-Timeframe** (H4 → H1 → M15 → M5)
- **Sistema de Confluência** combinando Price Action, Indicadores e Volume
- **Gestão de Risco Avançada** com stop dinâmico e trailing stop
- **Arquitetura Modular** em seis módulos independentes
- **Configurações Flexíveis** (30+ parâmetros ajustáveis)

Para detalhes completos da arquitetura consulte [DocumentacaoTecnica.md](DocumentacaoTecnica.md).

### Estrutura de Módulos

| Módulo | Descrição |
|---------|-----------|
| **Core** | Algoritmos de tendência e utilitários base |
| **Price Action** | Linhas de tendência, suporte, resistência e padrões |
| **Indicators** | Médias móveis, VWAP, Bollinger, Fibonacci e volume |
| **TimeframeAnalysis** | Coordena a análise em múltiplos timeframes |
| **SignalGeneration** | Geração de sinais e cálculo de confluência |
| **TradeExecution** | Execução e gerenciamento das ordens |

## Instalação

1. Verifique os requisitos:
   - MetaTrader 5 build 3815+
   - Windows 10 ou superior
   - Conexão estável com a internet
   - Conta com o ativo **WINM25** habilitado
2. Copie a pasta `TrendAnalyzerWINM25/` para `MQL5/Experts/`
3. Compile `TrendAnalyzerEA.mq5` no MetaEditor
4. Anexe o EA a um gráfico WINM25 e ajuste os parâmetros
5. Execute `TrendAnalyzerTest.mq5` para validar a instalação

Configurações sugeridas de risco estão descritas em [ManualInstalacao.md](ManualInstalacao.md).

## Uso

O EA identifica oportunidades a partir da seguinte sequência:

1. **H4** – Determina o contexto principal
2. **H1** – Confirma a direção
3. **M15** – Define o ponto de entrada
4. **M5** – Refina o timing

Os sinais contêm força (0–100%), confluência e relação risco/recompensa. Exemplos completos e orientações estão em [GuiaUso.md](GuiaUso.md).

## Contribuição

Contribuições são bem-vindas! Para propor melhorias:

1. Fork este repositório
2. Crie uma branch com sua melhoria
3. Envie um pull request descrevendo a alteração

Sugestões de documentação ou testes também são apreciadas.

## Documentação

- [DocumentacaoTecnica.md](DocumentacaoTecnica.md) – Detalhes da arquitetura e metodologia
- [ManualInstalacao.md](ManualInstalacao.md) – Passo a passo de instalação
- [GuiaUso.md](GuiaUso.md) – Explicação completa sobre sinais
- [TechnicalSpecifications.md](TechnicalSpecifications.md) – Especificações técnicas

## Licença

Este software é propriedade intelectual dos desenvolvedores e seu uso está sujeito aos termos de licença aplicáveis. Trading envolve risco de perda; utilize por sua conta e risco.

---

*Desenvolvido por Manus AI - Junho 2025*
