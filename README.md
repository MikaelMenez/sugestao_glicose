# sugestao_glicose

Sistema de recomendação de refeições para **reduzir a glicose de um paciente ao longo de 3 dias**,
construído sobre dados reais de monitoramento contínuo de glicose (CGM) e de registro alimentar.

> **Status:** projeto em andamento. A análise exploratória, a construção do dataset e o preparo
> para modelagem (classe de diabetes, split e seleção de features) estão prontos. O modelo de
> previsão e o algoritmo genético ainda **não foram implementados**. Veja
> [Estado atual e próximos passos](#estado-atual-e-próximos-passos).

---

## 1. O problema

Pessoas com diabetes tipo 2 ou pré-diabetes controlam a glicose em boa parte pela alimentação,
mas a resposta glicêmica a uma mesma refeição varia muito de pessoa para pessoa. Montar um
cardápio que realmente reduza a glicose de um paciente específico é difícil de fazer "no olho".

**Pergunta do projeto:** dado o perfil fisiológico de um paciente, quais refeições devemos
sugerir ao longo de 3 dias para que sua glicose **diminua no terceiro dia**?

## 2. A solução proposta (em camadas)

```
┌──────────────────────────┐        ┌───────────────────────────────┐
│ Camada 1: modelo         │        │ Camada 2: recomendação        │
│ (rede neural)            │        │ (algoritmo genético)          │
│                          │        │                               │
│ refeição + perfil do     │───────▶│ gera planos de 3 dias, usa o  │
│ paciente  ──▶  score de  │ fitness│ modelo para avaliar cada plano│
│ glicose                  │        │ e evolui até o melhor         │
└──────────────────────────┘        └───────────────────────────────┘
```

1. **Camada 1 – modelo substituto (surrogate).** Uma rede neural é treinada com os dados
   históricos para prever um **score de glicose** (a resposta glicêmica pós-refeição) a partir
   das características da refeição e do paciente.
2. **Camada 2 – recomendação.** Ao receber um paciente novo, um **algoritmo genético** gera
   candidatos de plano alimentar de 3 dias e usa o modelo da camada 1 como **função de fitness**.
   O plano que minimiza a glicose prevista (com foco no 3º dia) é o recomendado.

### Decisões de projeto

- **O modelo deve generalizar para pacientes novos**, então o conjunto de teste é composto de
  **participantes inteiros** que o modelo nunca viu (nunca de refeições soltas).
- **Features por papel.** Só pode ser feature o que o algoritmo genético consegue controlar ou
  conhecer na hora de planejar:
  - *variáveis de decisão* (o GA escolhe): calorias, carboidratos, proteína, gordura, fibra,
    quantidade consumida, tipo e horário da refeição;
  - *perfil do paciente* (dado fixo): idade, IMC, sexo;
  - *estado no momento da refeição* (glicose e frequência cardíaca nos 90 min anteriores):
    **não existe num plano futuro**, então precisa ser substituída por valores típicos do
    paciente ou removida do modelo final. Hoje estão no dataset para análise.
- **Sem vazamento de dados.** Seleção de features, imputação e padronização são ajustadas
  **apenas no conjunto de treino**.

## 3. Os dados

Dataset **CGMacros**, com 45 participantes acompanhados por ~10 dias, usando dois sensores de
glicose (Abbott Libre Pro e Dexcom G6 Pro), um relógio Fitbit Sense e fotos das refeições.

| Item | Descrição |
|---|---|
| Granularidade | 1 linha por minuto, por participante (687.580 linhas no total) |
| Glicose | `Libre GL` e `Dexcom GL` (mg/dL, 40–400) |
| Fisiologia | `HR` (batimentos/min), `Calories (Activity)`, `METs` |
| Refeição | `Meal Type`, `Calories`, `Carbs`, `Protein`, `Fat`, `Fiber`, `Amount Consumed`, foto |
| Perfil (`bio.csv`) | idade, sexo, IMC, A1c, glicemia de jejum, insulina de jejum, lipídios etc. |

**Classes de diabetes** (pelo A1c, em %), usadas para estratificar o split:

| Classe | Critério | Participantes |
|---|---|---|
| Saudável | A1c < 5,7 | 15 |
| Pré-diabético | 5,7 ≤ A1c ≤ 6,4 | 16 |
| Diabético (tipo 2) | A1c > 6,4 | 14 |

> **Licença dos dados:** Creative Commons **BY-NC-SA 4.0** (veja `data/LICENSE.txt`). Uso não
> comercial, com atribuição e compartilhamento pela mesma licença. Ao publicar resultados,
> cite a fonte original do dataset.

> **Atenção:** os dados **não contêm insulina medida por refeição**, só a insulina de jejum,
> uma vez por participante. Por isso o alvo do modelo é a resposta de **glicose**.

## 4. Estrutura do repositório

```
sugestao_glicose/
├── Untitled.ipynb          # notebook principal: carga, EDA, dataset, split e seleção
├── main.py                 # placeholder gerado pelo `uv init` (ainda sem uso)
├── pyproject.toml          # dependências do projeto
├── uv.lock                 # versões travadas das dependências
├── setup_uv_jupyter.sh     # prepara o ambiente (uv + .venv + kernel do Jupyter)
├── .python-version         # Python 3.14
├── .gitignore
└── data/                   # dados (CC BY-NC-SA 4.0)
    ├── CGMacros_dateshifted365/CGMacros/
    │   ├── bio.csv                       # perfil e exames de cada participante
    │   └── CGMacros-001 … CGMacros-0NN/  # uma pasta por participante
    │       ├── CGMacros-0NN.csv          # série minuto a minuto
    │       └── photos/                   # fotos das refeições
    ├── DataDictionary*.csv / .pdf        # dicionários de dados
    ├── LICENSE.txt
    └── SHA256SUMS.txt
```

## 5. Setup

**Requisitos:** Linux/macOS, `git` e `curl`. O Python 3.14 e as dependências são gerenciados
pelo [`uv`](https://docs.astral.sh/uv/).

```bash
git clone <url-do-repositorio>
cd sugestao_glicose

bash setup_uv_jupyter.sh
```

O script instala o `uv` (se necessário), cria a `.venv`, instala as dependências do
`pyproject.toml` e registra o kernel **"Python (uv - sugestao_glicose)"** no Jupyter. Use
`bash setup_uv_jupyter.sh` em vez de `./setup_uv_jupyter.sh`, a menos que você dê permissão de
execução com `chmod +x`.

**Dados:** coloque o dataset em `data/` conforme a estrutura acima. A pasta `data/` consta no
`.gitignore`.

**Rodando o notebook:** abra `Untitled.ipynb` e **selecione o kernel
"Python (uv - sugestao_glicose)"**. Se o notebook estiver no kernel genérico `python3`, ele não
enxerga as bibliotecas do projeto (erro `No module named 'polars'`).

### Dependências

| Pacote | Uso |
|---|---|
| `polars[rtcompat]` | manipulação dos dados |
| `scikit-learn` | seleção de features e métricas |
| `keras` | rede neural (camada 1, ainda não implementada) |
| `ipykernel` (dev) | kernel do Jupyter |

> **CPUs antigas:** o Polars padrão exige instruções AVX2/FMA/BMI. Em CPUs sem elas (por
> exemplo, Intel Ivy Bridge de 2012), ele encerra com `Illegal instruction` (SIGILL) ao
> importar. O projeto usa a variante **`polars[rtcompat]`**, compatível com esses processadores
> e também com os modernos.

## 6. O pipeline do notebook

| Etapa | O que faz |
|---|---|
| Carga | lê os CSVs de todos os participantes e concatena (687.580 × 19) |
| Qualidade | preenchimento por coluna e auditoria por participante |
| EDA | estatísticas, perfil nutricional por refeição, comparação Libre × Dexcom |
| Janelas por refeição | para cada refeição, estatísticas de 90 min **antes** (glicose, HR, METs) e de 90 min **depois** (pico, média, mínimo da glicose) |
| Dataset de refeições | 1 linha por refeição (≈1.700), com o perfil do participante (`bio.csv`) |
| Classe de diabetes | saudável / pré-diabético / diabético, derivada do A1c |
| Split | treino e teste **por participante, estratificado por classe** (36 treino / 9 teste) |
| Pré-processamento | imputação pela mediana, padronização e one-hot, estatísticas só do treino |
| Seleção de features | `SelectKBest` com `f_regression`, ajustado só no treino |

**Alvo atual (provisório):** `delta_GL_peak_90m`, o quanto a glicose sobe no pico em até 90 min
após a refeição.

## 7. Estado atual e próximos passos

**Pronto**
- Carga, limpeza e análise exploratória.
- Dataset por refeição com janelas pré e pós.
- Classe de diabetes, split por participante estratificado e seleção de features.

**A fazer**
- Reorganizar as features por papel (decisão, perfil, estado) e forçar as variáveis de decisão
  no modelo.
- Treinar a rede neural e um baseline simples (por exemplo, gradient boosting) para comparar.
- Implementar o algoritmo genético com o modelo como fitness e faixas realistas de refeição.
- Decidir se o efeito do 3º dia entra só no fitness ou se o modelo aprende o histórico dos dias
  anteriores.

## 8. Limitações conhecidas

- **Poucos pacientes:** são 45 participantes, e as refeições da mesma pessoa não são
  independentes. Os p-values da seleção de features devem ser lidos só como ranking.
- **Refeições lançadas em partes:** cerca de 100 registros estão a ≤ 30 min de outro do mesmo
  participante, o que pode representar uma refeição dividida em itens e sobrepõe as janelas.
- **Dois sensores:** o Dexcom lê, em média, ~32 mg/dL a mais que o Libre, e a glicose usada é a
  média dos dois, sem calibração.
- **Surrogate explorável:** o algoritmo genético tende a explorar erros do modelo, então as
  refeições geradas precisam ser limitadas a combinações realistas.
- **Uso clínico:** este é um projeto de pesquisa. As recomendações **não substituem
  orientação médica ou nutricional**.
