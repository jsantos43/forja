# forja

Script em bash para sintetizar e gravar FPGAs usando só ferramentas open source:

```
yosys → nextpnr → gowin_pack / icepack / ecppack → openFPGALoader
```

Você entra na pasta do projeto, roda `forja run` e ele sintetiza e grava na placa.

## Instalação

```bash
./install.sh          # cria o link ~/.local/bin/forja
forja doctor          # confere quais ferramentas estão instaladas
```

Ferramentas no Arch Linux:

```bash
sudo pacman -S yosys openfpgaloader iverilog gtkwave
yay -S nextpnr-git prjapicula   # nextpnr + gowin_pack (Tang Nano)
yay -S icestorm                 # icepack (Lattice iCE40) — só se for usar
yay -S prjtrellis               # ecppack (Lattice ECP5)  — só se for usar
```

Autocompletar no zsh: adicione ao `~/.zshrc`, antes do `compinit`:

```zsh
fpath=(~/Arquivos/forja/completions $fpath)
```

## Uso

```bash
forja synth  [pasta]   # sintetiza e gera o bitstream
forja load   [pasta]   # grava na placa o bitstream já gerado
forja run    [pasta]   # sintetiza (se algo mudou) e grava
forja sim    [pasta]   # simula com iverilog e abre o GTKWave
forja clean  [pasta]   # apaga build/
forja detect           # detecta a placa conectada
forja boards           # lista as placas suportadas
forja init -b <placa>  # cria forja.conf na pasta
forja doctor           # verifica as ferramentas
```

Se a pasta não for informada, ele usa a atual.

| Opção | Efeito |
|---|---|
| `-b, --board <placa>` | placa alvo |
| `-t, --top <módulo>` | módulo top (padrão: `top`) |
| `-p, --persistent` | grava na flash (permanente) em vez da SRAM |
| `-f, --force` | ressintetiza mesmo sem mudanças |
| `-v, --verbose` | mostra a saída completa das ferramentas |
| `-n, --no-wave` | (`sim`) não abre o GTKWave |

## Estrutura de um projeto

```
meu_projeto/
├── forja.conf          ← opcional: BOARD=, TOP=, CONSTRAINTS=
├── top.v               ← fontes .v/.sv na raiz ou em src/
├── outro_modulo.v
├── constraints.cst     ← pinagem (.cst Gowin, .pcf iCE40, .lpf ECP5)
├── sim/top_tb.v        ← testbench (<top>_tb.v)
└── build/<placa>/      ← gerado: bitstream e logs de cada etapa
```

- **Fontes:** o forja pega todos os `*.v` e `*.sv` da raiz e de `src/`, exceto os `*_tb.v`.
- **Pinagem:** procura, nesta ordem, o `CONSTRAINTS=` do `forja.conf`, depois `<placa>.<ext>`, depois `constraints.<ext>`, depois o único `*.<ext>` da pasta. Assim um projeto pode ter `tangnano20k.cst` e `icebreaker.pcf` lado a lado.
- **Cache:** a síntese só é refeita quando o conteúdo das fontes, da pinagem, da placa ou do top muda.
- **Logs:** cada etapa grava em `build/<placa>/<etapa>.log`. Se der erro, aparecem só as linhas relevantes.
- **Simulação:** o `vvp` roda com a pasta do projeto como diretório de trabalho, então use `$dumpfile("sim/dump.vcd")` ou `$dumpfile("dump.vcd")` no testbench.

Coloque `build/` no `.gitignore` dos seus projetos.

## Escolha da placa

A placa é escolhida nesta ordem de prioridade:

1. a opção `-b <placa>`;
2. o `BOARD=` do `forja.conf` do projeto;
3. o `BOARD=` de `~/.config/forja/config`, que é o padrão global.

```bash
mkdir -p ~/.config/forja && echo "BOARD=tangnano20k" > ~/.config/forja/config
```

## Placas

| Placa | Família | Status |
|---|---|---|
| `tangnano20k` | Gowin GW2AR-18C | perfil principal |
| `tangnano9k` | Gowin GW1NR-9C | |
| `icebreaker` | Lattice iCE40UP5K | |
| `ulx3s-85f` | Lattice ECP5 85F | |

Para adicionar uma placa, copie `boards/_modelo.sh.txt` para `boards/<nome>.sh` ou para `~/.config/forja/boards/<nome>.sh` e preencha os campos. O nome usado pelo openFPGALoader aparece em `openFPGALoader --list-boards`.

Famílias suportadas: **gowin**, **ice40** e **ecp5**. Xilinx (openXC7) e Intel não são suportadas.

> Nas placas iCE40, o openFPGALoader pode gravar na flash mesmo sem `-p`, dependendo da placa.
