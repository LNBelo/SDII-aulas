# Estudo: UART Transmissor 8-E-1 em Verilog

## Meu primeiro prompt
Em estudos/interfaces-seriais quero começar os estudos sobre comunicação serial usando verilog. Quero usar a  configuração do transmissor co 8-E-1 e ver as formas do onda no gtkwave. Preciso patricar o verilog, então não gere as linhas de código, a menos que eu peça, mas pode me dar instruções para que eu consiga escrever o códgido em verilog. por onde podemos começar?

## Objetivo

Implementar um transmissor UART com configuração **8-E-1** em Verilog, visualizar as formas de onda no GTKWave, e aprender comunicação serial do zero praticando a escrita do código sem que o assistente gere o código diretamente.

---

## Configuração 8-E-1

| Campo | Valor | Significado |
|---|---|---|
| **8** | 8 bits de dados | LSB primeiro |
| **E** | Paridade par (Even) | XOR de todos os bits = 0 |
| **1** | 1 stop bit | nível alto |

Frame completo: `START + D0..D7 + PARIDADE + STOP` = **11 bits no total**.

---

## Decisões tomadas

- **Protocolo escolhido para começar:** UART (assíncrono) — mais simples, um fio, frame bem definido.
- **Circuito:** síncrono (baseado em clock com `always @(posedge clk)`).
- **Progressão planejada:** UART TX → UART RX → SPI → I2C.
- **Ferramentas:** Icarus Verilog (`iverilog`) para compilar e simular, GTKWave para visualizar formas de onda.

---

## Conceito importante: síncrono vs assíncrono

O termo aparece em dois níveis diferentes e não deve ser confundido:

| Nível | Assíncrono | Síncrono |
|---|---|---|
| **Protocolo** (comunicação entre chips) | UART — sem clock compartilhado, os dois lados precisam concordar no baud rate antes | SPI, I2C — clock transmitido junto com os dados |
| **Circuito Verilog** (como a lógica é escrita) | Lógica combinacional `always @(*)` — muda com o sinal | `always @(posedge clk)` — muda só na borda do clock |

**Conclusão:** o circuito UART deve ser **síncrono** (baseado em clock) mesmo o protocolo sendo assíncrono — sem clock não dá para contar ciclos e gerar o baud rate.

---

## Conceito: por que o divisor de baud existe?

O clock do FPGA (ex: 50 MHz) é muito mais rápido do que o baud rate do UART (ex: 9600 baud).

- 50 MHz = 50.000.000 pulsos por segundo
- 9600 baud = 9600 bits por segundo = 1 bit a cada ~104 microsegundos

Se você ligasse `tx` diretamente ao clock, estaria transmitindo 50 milhões de bits por segundo — o receptor esperando 9600 baud não entenderia nada.

**Solução:** contar ciclos de clock e só avançar para o próximo bit quando passar o tempo certo.

```
DIVISOR = CLK_FREQ / BAUD_RATE = 50.000.000 / 9600 = 5208 ciclos por bit
```

A cada 5208 ciclos de clock, o sinal `baud_tick` vale `1` por exatamente 1 ciclo. Esse pulso é o "sinal de avançar" para a FSM — quando `baud_tick` pulsa, você muda o bit na linha `tx`.

**Analogia:** pense num metrônomo batendo 50 vezes por segundo, mas você precisa bater palmas só 9600 vezes por hora. Você conta as batidas do metrônomo e só bate palma quando chega no número certo. Zera o contador e começa de novo.

---

## Conceito: `parameter` vs `localparam`

- `parameter` — constante que **pode** ser sobrescrita de fora do módulo ao instanciá-lo. Use para valores que o usuário do módulo pode querer configurar (ex: `CLK_FREQ`, `BAUD_RATE`).
- `localparam` — constante **interna**, não pode ser sobrescrita. Use para valores derivados de outros parâmetros (ex: `DIVISOR = CLK_FREQ / BAUD_RATE`).

---

## Conceito: `$clog2`

`$clog2(N)` retorna o teto do logaritmo base 2 de N — ou seja, **quantos bits são necessários para representar o valor N**.

Exemplo: para contar até 5208, precisamos de `$clog2(5208) = 13` bits.

Uso para declarar o contador com largura automática:
```verilog
reg [$clog2(DIVISOR)-1 : 0] contador;
```

---

## Erros cometidos e corrigidos durante o estudo

### Erro 1: nome da saída como `rx`
```verilog
output rx  // errado — rx é convenção para recepção
output tx  // correto — tx é convenção para transmissão
```

### Erro 2: `wire` redundante na porta de saída
```verilog
wire rx = tx_start;  // redundante e incorreto — rx já estava declarado como output
```

### Erro 3: `data` declarado como 1 bit
```verilog
input data,        // isso é 1 bit só — não dá para transmitir um byte
input [7:0] data,  // correto — vetor de 8 bits
```

### Erro 4: `CLK_FREQ` sem as unidades corretas
```verilog
parameter CLK_FREQ = 50;           // errado — DIVISOR ficaria 50/9600 = 0
parameter CLK_FREQ = 50_000_000;   // correto — underscore é permitido em Verilog para legibilidade
```

---

## Arquivos do projeto

- `uart_tx.v` — módulo do transmissor (em desenvolvimento)
- `uart_tx_tb.v` — testbench (ainda não criado)

---

## Estado atual do uart_tx.v

```verilog
module uart_tx (
    input clk,
    input rst,
    input tx_start,
    input [7:0] data, // [MSB:LSB]
    output tx // bit serial saindo
);  
    parameter CLK_FREQ = 50_000_000; // Ex. FPGA com 50MHZ
    parameter BAUD_RATE = 9600;
    localparam DIVISOR = CLK_FREQ / BAUD_RATE;

    parameter largura = $clog2(DIVISOR)-1;
    reg [largura : 0] contador;
    reg baud_tick;

    always @(posedge clk) begin
        // ainda vazio — próximo passo
    end

endmodule
```

---

## Próximo passo: completar o bloco always do divisor de baud

O bloco `always @(posedge clk)` deve conter a seguinte lógica:

- Se `rst`: zera o `contador` e o `baud_tick`
- Se `contador == DIVISOR - 1`: zera o contador, coloca `baud_tick = 1`
- Senão: incrementa o contador, coloca `baud_tick = 0`

Após escrever, compilar com:
```bash
iverilog -o uart_tx.vvp uart_tx.v
```
Se não houver erro, partir para o Passo 3 (FSM).

---

## Passos completos do projeto

| Passo | Descrição | Status |
|---|---|---|
| 1 | Interface do módulo (ports) | Concluído |
| 2 | Divisor de baud (contador + baud_tick) | Em andamento — bloco always vazio |
| 3 | FSM (IDLE → START → DATA → PARITY → STOP) | Pendente |
| 4 | Cálculo de paridade par | Pendente |
| 5 | Testbench + GTKWave | Pendente |

---

## Passo 3: FSM planejada

Estados da máquina:
```
IDLE → START → DATA (bits 0..7) → PARITY → STOP → IDLE
```

O que acontece na linha `tx` em cada estado:
| Estado | Valor de `tx` |
|---|---|
| IDLE | `1` (linha ociosa em nível alto) |
| START | `0` (start bit é sempre 0) |
| DATA | bit atual do dado (`data[bit_index]`) |
| PARITY | bit de paridade par (`^data`) |
| STOP | `1` (stop bit é sempre 1) |

Perguntas a responder ao implementar:
- Como representar os estados? (use `localparam` ou `parameter` para nomear cada estado)
- O avanço de estado acontece a cada ciclo de clock ou apenas quando `baud_tick` pulsa?
- Quantos bits precisa o contador de índice de bit? (0 a 7 → 3 bits)
- O bit de paridade é calculado antecipadamente (ao carregar o dado) ou no estado PARITY?

---

## Passo 5: Testbench

O testbench `uart_tx_tb.v` precisará de:
1. Geração de clock (período típico de 20 ns para 50 MHz)
2. Reset inicial
3. Pulsar `tx_start` com um byte de teste — usar `8'h55` (= `01010101`) pois alterna 0 e 1 e é fácil de visualizar
4. `$dumpfile("dump.vcd")` e `$dumpvars` para gerar o arquivo que o GTKWave lê

Compilar e simular:
```bash
iverilog -o uart_tx_tb.vvp uart_tx_tb.v uart_tx.v
vvp uart_tx_tb.vvp
gtkwave dump.vcd
```

No GTKWave, adicionar o sinal `tx` e verificar o frame: nível alto → start bit (0) → 8 bits de dados LSB primeiro → paridade → stop bit (1) → nível alto.

---

## Regras de conduta do estudo

- O assistente **não gera código** — apenas dá instruções para o aluno escrever.
- Exceção: o assistente pode mostrar trechos pequenos de sintaxe quando o conceito for novo (ex: como declarar um vetor, como usar `$clog2`).
- O aluno mostra o código escrito e o assistente revisa e orienta o próximo passo.
- Erros de compilação são investigados juntos antes de avançar.